//
//  SaveButton.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 22..
//

import SwiftUI

struct SaveButton: View {
    var camera: CameraModel
    var buttonPadding: CGFloat

    var body: some View {
        Button(action: {camera.savePic()}, label: {
            if #available(iOS 14.0, *) {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.black)
                    .padding(.vertical,10)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            } else {
                Text("Save")
                    .font(.caption)
                    .foregroundColor(.black)
                    //.fontWeight(.semibold)
                    .padding(.vertical,15)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        })
    }
}
