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
    @State private var fileName: String = ""
    @State private var isShowingFileImporter = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(hasFile ? fileName : "MCRAW Metadata Analyzer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                if hasFile {
                    Button(action: { isShowingFileImporter = true }) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open another file")
                }
            }
            .padding(.top)

            if hasFile {
                Text("File loaded successfully!")
                    .foregroundColor(.green)
            }

            // Show drop area only when no file is loaded
            if !hasFile {
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
                        isShowingFileImporter = true
                    }
            }

            // Display metadata in three columns when file is loaded
            if hasFile {
                HStack(alignment: .top, spacing: 16) {
                    // Container Metadata Column
                    if !containerMetadata.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Container Metadata")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)

                            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                                Text(containerMetadata)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .frame(maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // First Frame Metadata Column
                    if !firstFrameMetadata.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Frame Metadata")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)

                            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                                Text(firstFrameMetadata)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .frame(maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Last Frame Metadata Column
                    if !lastFrameMetadata.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Frame Metadata")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)

                            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                                Text(lastFrameMetadata)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .frame(maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: 600)
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
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            // Allow dropping files even when file is loaded
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first,
                      url.pathExtension.lowercased() == "mcraw" else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Please select a valid MCRAW file"
                    }
                    return
                }
                decodeFile(at: url)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        .onOpenURL { url in
            // Handle opening .mcraw files from Finder or other apps
            if url.pathExtension.lowercased() == "mcraw" {
                decodeFile(at: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            isShowingFileImporter = true
        }
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
                do {
                    let firstTimestamp = timestamps[0]
                    let outMetadata = try decoder.loadFrameMetadata(firstTimestamp)
                    firstFrameJson = String(outMetadata.dump())
                } catch {
                    print("Error loading first frame metadata: \(error)")
                }
            }

            // Get last frame metadata
            var lastFrameJson = ""
            if !timestamps.isEmpty {
                do {
                    let lastTimestamp = timestamps[timestamps.count - 1]
                    let outMetadata = try decoder.loadFrameMetadata(lastTimestamp)
                    lastFrameJson = String(outMetadata.dump())
                } catch {
                    print("Error loading last frame metadata: \(error)")
                }
            }

            DispatchQueue.main.async {
                // Reset state first
                self.containerMetadata = ""
                self.firstFrameMetadata = ""
                self.lastFrameMetadata = ""

                // Then set new values
                self.containerMetadata = formatJSON(containerJson)
                self.firstFrameMetadata = formatJSON(firstFrameJson)
                self.lastFrameMetadata = formatJSON(lastFrameJson)
                self.errorMessage = nil
                self.hasFile = true
                self.fileName = url.lastPathComponent

                // Debug print
                print("Loaded file: \(url.lastPathComponent)")
                print("Frame count: \(timestamps.count)")
                print("First frame JSON empty: \(firstFrameJson.isEmpty)")
                if !timestamps.isEmpty {
                    print("First timestamp: \(timestamps[0])")
                    print("Last timestamp: \(timestamps[timestamps.count - 1])")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.hasFile = false
                self.fileName = ""
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
