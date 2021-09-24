import os
import torch
import torchvision

import coremltools as ct
from coremltools.proto import FeatureTypes_pb2 as ft
from model import U2NET
from model import U2NETP

model_name='u2net'
#model_name='u2netp'

model_dir = os.path.join(os.getcwd(), 'saved_models', model_name, model_name + '.pth')

if(model_name=='u2net'):
    net = U2NET(3,1)
elif(model_name=='u2netp'):
    net = U2NETP(3,1)

net.load_state_dict(torch.load(model_dir, map_location=torch.device('cpu')))
net.eval()

example_input = torch.rand(1, 3, 320, 320)
traced_model = torch.jit.trace(net, example_input)

model = ct.convert(
    traced_model,
    inputs=[ct.ImageType(name="in_0", shape=example_input.shape,scale=1/255.0)]
)

spec = model.get_spec()
spec.specificationVersion = 1
spec_layers = getattr(spec, spec.WhichOneof("Type")).layers
output_layers = []
for layer in spec_layers:
    if layer.name[:2] == "21":
        print("name: %s  input: %s  output: %s" % (layer.name, layer.input, layer.output))
        output_layers.append(layer)

new_layers = []
layernum = 0;
for layer in output_layers:
    new_layer = spec_layers.add()
    new_layer.name = 'out_p'+str(layernum)
    new_layers.append('out_p'+str(layernum))

    new_layer.activation.linear.alpha=255
    new_layer.activation.linear.beta=0

    new_layer.input.append(layer.name)
    new_layer.output.append('out_p'+str(layernum))
    output_description = next(x for x in spec.description.output if x.name==output_layers[layernum].output[0])
    output_description.name = new_layer.name

    layernum = layernum + 1

# Specify the outputs as grayscale images.
for output in spec.description.output:
    if output.name not in new_layers:
        continue
    if output.type.WhichOneof('Type') != 'multiArrayType':
        raise ValueError("%s is not a multiarray type" % output.name)
    output.type.imageType.colorSpace = ft.ImageFeatureType.ColorSpace.Value('GRAYSCALE')
    output.type.imageType.width = 320
    output.type.imageType.height = 320

# Save our new model
updated_model = ct.models.MLModel(spec)

updated_model.user_defined_metadata["com.apple.coreml.model.preview.type"] = "imageSegmenter"
updated_model.save("u2net.mlmodel")
