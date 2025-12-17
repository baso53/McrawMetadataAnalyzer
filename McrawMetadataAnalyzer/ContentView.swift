//
//  ContentView.swift
//  McrawMetadataAnalyzer
//
//  Created by Sebastijan on 17.12.2025..
//

import SwiftUI
import Motioncam

struct ContentView: View {
    var body: some View {
        let ops = Motioncam.motioncam.Decoder
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
