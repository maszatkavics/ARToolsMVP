//
//  CameraModel.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 12..
//

import SwiftUI
import AVFoundation
import CoreML
import VideoToolbox

class CameraModel: NSObject,ObservableObject,AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    @Published var picData = Data(count: 0)
    
    //bgremoval
    @Published var isRemoving = false
    @Published var isClipped = false
    @Published var clippedImage: Image? = nil
    
    //colorpicker
    @Published var showPicker = false
    @Published var centerColor: UIColor?
    var pickingColor = false
    let pickWidth: CGFloat = 20.0
    
    // iOS camera authorization
    func authorizeCamera(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    // initial setup for camera capture
    func setUp(){
        do{
            self.session.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            if self.session.canAddInput(input){
                self.session.addInput(input)
            }
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    // start photo capture (photoOutput will be called with the result)
    func takePic(){
        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.picData = Data(count: 0)
                self.session.startRunning()
            }
        }
    }
    
    // used by back button
    func reTake(){
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isClipped = false
                self.picData = Data(count: 0)
            }
        }
    }
    
    // called once camera picture is captured
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil{
            return
        }
        guard let imageData = photo.fileDataRepresentation(), let photoImage = UIImage(data: imageData) else{return}
        
        if (self.pickingColor) {
            // color picker: average color for center square
            self.centerColor = photoImage.cropsToSquare(cropSize: self.pickWidth).averageColor
            self.pickingColor = false
        } else {
            // backgound removal
            self.isRemoving = true
            
            let origSize = photoImage.size
            
            // u2net input size
            let resizedImage = photoImage.scale(with: CGSize(width: 320,height: 320))!
            
            DispatchQueue.global().async {
                do {
                    // use the u2net model for spatial bg detection
                    let model = try u2net.init(configuration: MLModelConfiguration())
                    let result = try model.prediction(in_0: self.buffer(from: resizedImage)!)
                    
                    DispatchQueue.main.async {
                        let outImage = UIImage(pixelBuffer: result.out_p1)
                        let invertedOut = outImage?.invert
                        let finalImage = resizedImage.maskImage(invertedOut!).scale(with: origSize)!
                            
                        self.picData = finalImage.jpegData(compressionQuality: 1)!
                        self.clippedImage = Image(uiImage: finalImage)
                        self.isClipped = true
                        
                        self.isRemoving = false
                    }
                } catch {
                    print(error)
                    self.isRemoving = false
                }
            }
        }
    }
    
    // color picker
    func pickColor() {
        self.pickingColor = true
        self.takePic()
    }
    
    func hexStringColor() -> String {
        let components = self.centerColor?.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}

// bgremoval helper
extension CameraModel {
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}


// share and save
extension CameraModel {
    func share(){
        guard let image = UIImage(data: self.picData) else{return}
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
    
    func savePic(){
        guard let image = UIImage(data: self.picData) else{return}
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}


extension UIImage {
    // bgremoval
    func maskImage(_ maskImage: UIImage) -> UIImage {
        let maskRef = maskImage.cgImage
        
        let mask = CGImage(
            maskWidth: maskRef!.width,
            height: maskRef!.height,
            bitsPerComponent: maskRef!.bitsPerComponent,
            bitsPerPixel: maskRef!.bitsPerPixel,
            bytesPerRow: maskRef!.bytesPerRow,
            provider: maskRef!.dataProvider!,
            decode: nil,
            shouldInterpolate: true)
        
        let masked = self.cgImage!.masking(mask!)
        let maskedImage = UIImage(cgImage: masked!)
        return maskedImage
    }
    
    var invert: UIImage? {
        let context = CIContext(options: nil)
        if let filter = CIFilter(name: "CIColorInvert") {
            filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
    
    func scale(with size: CGSize) -> UIImage? {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    public convenience init?(pixelBuffer: CVPixelBuffer) {
      if let cgImage = CGImage.create(pixelBuffer: pixelBuffer) {
        self.init(cgImage: cgImage)
      } else {
        return nil
      }
    }
    
    // color picker
    func cropsToSquare(cropSize: CGFloat) -> UIImage {
        let refWidth = CGFloat((self.cgImage!.width))
        let refHeight = CGFloat((self.cgImage!.height))
        
        let x = (refWidth - cropSize) / 2.0
        let y = (refHeight - cropSize) / 2.0
        
        let cropRect = CGRect(x: x, y: y, width: cropSize, height: cropSize)
        let imageRef = self.cgImage?.cropping(to: cropRect)
        let cropped = UIImage(cgImage: imageRef!, scale: 0.0, orientation: self.imageOrientation)
        
        return cropped
    }
    
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension CGImage {
  public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
    return cgImage
  }
}
