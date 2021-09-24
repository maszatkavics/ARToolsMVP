//
//  ColorpickerButton.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 24..
//

import SwiftUI

struct ColorpickerButton: View {
    var camera: CameraModel
    
    var body: some View {
        Button(action: {
            camera.showPicker.toggle()
            camera.centerColor = nil
        }, label: {
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
}
