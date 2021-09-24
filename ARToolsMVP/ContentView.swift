//
//  ContentView.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 12..
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        CameraView()
    }
}

struct CameraView: View {
    let buttonPadding: CGFloat = 20.0
    @ObservedObject var camera = CameraModel()
        
    var body: some View{
        ZStack{
            // preview for the camera
            CameraPreview(camera: camera)
            
            // rectangle for color picker
            if self.camera.showPicker {
                Rectangle()
                    .stroke(Color.white,lineWidth: 1)
                    .frame(width: camera.pickWidth, height: camera.pickWidth)
            }
            
            if camera.isClipped{
                //blur camera preview
                VisualEffectView(effect: UIBlurEffect(style: .dark))
                
                //show clipped image full screen
                camera.clippedImage!.resizable()
                    .frame(width: UIScreen.main.bounds.size.width)
                
                //clipped bottom bar
                VStack{
                    Spacer()
                    HStack {
                        BackButton(camera: self.camera, buttonPadding: self.buttonPadding)
                        Spacer()
                        ShareButton(camera: self.camera, buttonPadding: self.buttonPadding)
                        SaveButton(camera: self.camera, buttonPadding: self.buttonPadding)
                    }
                }.padding(15)
            }else{
                // bottom bar
                VStack{
                    Spacer()
                    HStack{
                        if !self.camera.showPicker{
                            Spacer()
                            
                            //main camera button
                            Button(action: camera.takePic, label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 65, height: 65)
                                    Circle()
                                        .stroke(Color.white,lineWidth: 2)
                                        .frame(width: 75, height: 75)
                                }
                            })
                            .padding(.leading, 60)
                        } else {
                            PickColorButton(camera: self.camera)
                            
                            Spacer()
                            
                            //show color
                            HStack(){
                                if camera.centerColor != nil {
                                    Rectangle()
                                        .foregroundColor(Color(camera.centerColor ?? UIColor.white))
                                        .frame(width: 35, height: 35)
                                        .border(Color.gray, width: 1)
                                    Text(camera.hexStringColor())
                                        .foregroundColor(.black)
                                        .font(.system(size: 13))
                                        .frame(width:70)
                                } else {
                                    Text("Pick color\nTap eyedropper icon")
                                        .foregroundColor(.black)
                                        .font(.system(size: 13))
                                }
                            }
                            .frame(width: 150, height: 75)
                            .background(Color.white)
                            .clipShape(Capsule())
                            
                        }
                        Spacer()
                        ColorpickerButton(camera: self.camera)
                    }.frame(height: 75)
                    
                }.padding(15)
            }
            
            // blur while removing bg
            if camera.isRemoving{
                VisualEffectView(effect: UIBlurEffect(style: .dark))
                Text("Removing background…")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
    
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear(perform: {
            camera.authorizeCamera()
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Please Enable Camera Access"))
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera : CameraModel
    
    func makeUIView(context: Context) ->  UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
