//  ScreenshotPreviewView.swift Agent  Extracted from ContentView.swift 

import SwiftUI

struct ScreenshotPreviewView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    private var captionStyle: HierarchicalShapeStyle { contrast == .increased ? .primary : .secondary }
    let images: [NSImage]
    let onRemove: (Int) -> Void
    let onRemoveAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.secondary.opacity(0.3))
                            )
                            .accessibilityLabel("Attached image \(index + 1) of \(images.count)")
                        Button {
                            onRemove(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white, .red)
                        }
                        .buttonStyle(.plain)
                        .offset(x: 4, y: -4)
                        .help("Remove Image")
                        .accessibilityLabel("Remove image \(index + 1)")
                    }
                }
                Text("\(images.count) image(s)")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
                Button("Clear All") { onRemoveAll() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .accessibilityLabel("Remove all images")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
}
