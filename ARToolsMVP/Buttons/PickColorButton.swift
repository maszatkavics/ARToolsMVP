//
//  PickColorButton.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 24..
//

import SwiftUI

struct PickColorButton: View {
    var camera: CameraModel

    var body: some View {
        Button(action: {camera.pickColor()}, label: {
            if #available(iOS 14.0, *) {
                Image(systemName: "eyedropper")
                    .foregroundColor(.black)
                    .padding(.vertical,10)
                    .padding(.horizontal,20)
                    .background(Color.white)
                    .clipShape(Capsule())
            } else {
                Text("C")
                    .foregroundColor(.black)
                    .padding(.vertical,10)
                    .padding(.horizontal,20)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        })
    }
}
