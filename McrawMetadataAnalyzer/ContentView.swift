//
//  ContentView.swift
//  McrawMetadataAnalyzer
//
//  Created by Sebastijan on 17.12.2025..
//

import SwiftUI
import Motioncam
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isDropTargeted = false
    @State private var decodedMetadata: String = ""
    @State private var errorMessage: String?
    @State private var hasFile = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MCRAW Metadata Analyzer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            if hasFile {
                Text("File loaded successfully!")
                    .foregroundColor(.green)
            }
            
            // Drop area
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTargeted ? Color.blue : Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDropTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(isDropTargeted ? .blue : .gray)
                        
                        Text("Drop MCRAW files here")
                            .font(.headline)
                            .foregroundColor(isDropTargeted ? .blue : .gray)
                        
                        Text("or click to browse")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers: providers)
                }
                .onTapGesture {
                    // Optional: Add file browser support
                }
            
            // Display decoded metadata or error
            if !decodedMetadata.isEmpty {
                ScrollView {
                    Text(decodedMetadata)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "mcraw" else {
                DispatchQueue.main.async {
                    self.errorMessage = "Please drop a valid MCRAW file"
                }
                return
            }
            
            decodeFile(at: url)
        }
        
        return true
    }
    
    private func decodeFile(at url: URL) {
        // Create decoder instance
        let decoder = Motioncam.motioncam.Decoder(std.string(url.path))
        
        // Get container metadata
        let metadata = decoder.getContainerMetadata()
        
        // Convert JSON to string for display
        let jsonString = String(metadata.dump())
        
        DispatchQueue.main.async {
            self.decodedMetadata = jsonString
            self.errorMessage = nil
            self.hasFile = true
        }
    }
}

#Preview {
    ContentView()
}
