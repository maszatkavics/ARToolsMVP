//
//  BackButton.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 22..
//

import SwiftUI

struct BackButton: View {
    var camera: CameraModel
    var buttonPadding: CGFloat
    
    var body: some View {
        Button(action: camera.reTake, label: {
            if #available(iOS 14.0, *) {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.black)
                    .padding(.vertical,12)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            } else {
                Text("<-")
                    .foregroundColor(.black)
                    .padding(.vertical,12)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        })
    }
}
