//
//  ShareButton.swift
//  ARToolsMVP
//
//  Created by kavics on 2021. 09. 22..
//

import SwiftUI

struct ShareButton: View {
    var camera: CameraModel
    var buttonPadding: CGFloat

    var body: some View {
        Button(action: camera.share, label: {
            if #available(iOS 14.0, *) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.black)
                    .padding(.vertical,10)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            } else {
                Text("Share")
                    .foregroundColor(.black)
                    .padding(.vertical,15)
                    .padding(.horizontal,self.buttonPadding)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        })
    }
}
