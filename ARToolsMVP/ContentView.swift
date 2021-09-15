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
    @ObservedObject var camera = CameraModel()
    @State var showPicker = false
    
    var body: some View{
        ZStack{
            CameraPreview(camera: camera)
            
            if showPicker {
                Circle()
                    .stroke(Color.white,lineWidth: 1)
                    .frame(width: 20, height: 20)
            }
            
            if camera.isClipped{
                VisualEffectView(effect: UIBlurEffect(style: .dark))
            }
            
            VStack{
                if camera.isClipped{
                    camera.clippedImage!.resizable()
                        .border(Color.white)
                        .padding(10)
                    
                    HStack {
                        Button(action: camera.reTake, label: {
                            if #available(iOS 14.0, *) {
                                Image(systemName: "chevron.backward")
                                    .foregroundColor(.black)
                                    .padding(.vertical,12)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            } else {
                                Text("<-")
                                    .foregroundColor(.black)
                                    .padding(.vertical,12)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        }).padding(.horizontal,15)
                        
                        Spacer()
                        
                        Button(action: camera.share, label: {
                            if #available(iOS 14.0, *) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.black)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            } else {
                                Text("Share")
                                    .foregroundColor(.black)
                                    .padding(.vertical,12)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        })
                        
                        Button(action: {if !camera.isSaved{camera.savePic()}}, label: {
                            Text(camera.isSaved ? "Saved" : "Save")
                                .foregroundColor(.black)
                                //.fontWeight(.semibold)
                                .padding(.vertical,10)
                                .padding(.horizontal,20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }).padding(.horizontal,15)
                    }
                } else {
                    
                    Spacer()
                    
                    HStack{
                        Spacer()
                        
                        if !self.showPicker{
                            
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
                            HStack {
                                Rectangle()
                                    .foregroundColor(Color(camera.centerColor ?? UIColor.white))
                                    .frame(width: 40, height: 40)
                                    .border(Color.gray, width: 1)
                                Text(hexStringFromColor(color: camera.centerColor))
                                    .foregroundColor(.black)
                                    .font(.title)
                                    .frame(width:120)
                            }
                            .frame(width: 220, height: 75)
                            .background(Color.white)
                            .clipShape(Capsule())
                            
                        }
                        Spacer()
                        Button(action: {self.showPicker.toggle()}, label: {
                            if #available(iOS 14.0, *) {
                                Image(systemName: "paintpalette")
                                    .foregroundColor(.black)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            } else {
                                Text("P")
                                    .foregroundColor(.black)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        })
                    }
                    .frame(height: 75)
                }
            }.padding(15)
        }
        .onAppear(perform: {
            camera.authorizeCamera()
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Please Enable Camera Access"))
        }
    }
    
    func hexStringFromColor(color: UIColor?) -> String {
        let components = color?.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
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
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
