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
    @State private var containerMetadata: String = ""
    @State private var firstFrameMetadata: String = ""
    @State private var lastFrameMetadata: String = ""
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
            
            // Display metadata sections
            if !containerMetadata.isEmpty || !firstFrameMetadata.isEmpty || !lastFrameMetadata.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !containerMetadata.isEmpty {
                            MetadataSection(title: "Container Metadata", content: containerMetadata)
                        }

                        if !firstFrameMetadata.isEmpty {
                            MetadataSection(title: "First Frame Metadata", content: firstFrameMetadata)
                        }

                        if !lastFrameMetadata.isEmpty {
                            MetadataSection(title: "Last Frame Metadata", content: lastFrameMetadata)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 500)
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
        do {
            // Create decoder instance
            var decoder = Motioncam.motioncam.Decoder(std.string(url.path))

            // Get container metadata
            let containerMeta = decoder.getContainerMetadata()
            let containerJson = String(containerMeta.dump())

            // Get all frame timestamps
            let timestamps = decoder.getFrames()

            // Get first frame metadata
            var firstFrameJson = ""
            if !timestamps.isEmpty {
                var firstTimestamp = timestamps[0]
                var outMetadata = decoder.loadFrameMetadata(firstTimestamp)
                firstFrameJson = String(outMetadata.dump())
            }

            // Get last frame metadata
            var lastFrameJson = ""
            if !timestamps.isEmpty {
                let lastTimestamp = timestamps[timestamps.count - 1]
                var outMetadata = decoder.loadFrameMetadata(lastTimestamp)
                lastFrameJson = String(outMetadata.dump())
            }

            DispatchQueue.main.async {
                self.containerMetadata = formatJSON(containerJson)
                self.firstFrameMetadata = formatJSON(firstFrameJson)
                self.lastFrameMetadata = formatJSON(lastFrameJson)
                self.errorMessage = nil
                self.hasFile = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.hasFile = false
            }
        }
    }

    private func formatJSON(_ jsonString: String) -> String {
        guard !jsonString.isEmpty else { return "" }

        // Parse and reformat JSON for better readability
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let formattedString = String(data: formattedData, encoding: .utf8) else {
            return jsonString
        }

        return formattedString
    }
}

struct MetadataSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
