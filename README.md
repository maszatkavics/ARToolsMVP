ARToolsMVP is an iOS app for experinmental AR tools

# AR Color Picker
Picks the average color of pixels within a rectange in the midle of the camera image.  
*Usage:* Switch on/off with palette icon, get color with eydropper icon

![](images/colorpicker.png)

# AR Copy-and-paste Tool
Salient Object Detection based background removal.  
*Usage:* Take a picture, wait for object detection. The image of the salient object without background can be shared or saved to phone.

![](images/remov.png)

## Object detection
Based on U2Net, a two-level nested U-structure neural network. Link: [U Square Net](https://github.com/xuebinqin/U-2-Net)

(Recommended article to learn more about U2Net: [U2Net : A machine learning model that performs object cropping in a single shot](https://medium.com/axinc-ai/u2net-a-machine-learning-model-that-performs-object-cropping-in-a-single-shot-48adfc158483)  
A nice summary to get deeper into Neural Networks: [Types of Neural Networks and Definition of Neural Network](https://www.mygreatlearning.com/blog/types-of-neural-networks/))

## Update pre-trained model
Object detection **can be improved** by replacing the current pre-trained model.  
The **u2net.mlmodel** is located in the ARToolsMVP folder. Due to filesize limitations of github recently this repository contains the small version (4.6MB). The large model (176 MB) can be downloaded from Dropbox (todo: link), then the current file needs to be replaced.

## Generate CoreML compatible pre-trained model from U2Net
U2Net [requested libraries](https://github.com/xuebinqin/U-2-Net#required-libraries) needs to be installed then follow the [usage instructions]( https://github.com/xuebinqin/U-2-Net#usage-for-salient-object-detection) (make sure to download "model u2net.pth").  
Copy [convert2mlmodel.py](https://github.com/maszatkavics/ARToolsMVP/blob/04b56caf70a267c014c1c9da64f9b4abcaa0fd61/convert2mlmodel.py) file to U2Net folder and run it with python. Once run with success the large u2net.mlmodel file will be generated. Overwrite the file in ARToolsMVP directory.

