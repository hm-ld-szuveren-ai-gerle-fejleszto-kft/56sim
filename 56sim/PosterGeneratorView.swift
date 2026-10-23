//
//  PosterGeneratorView.swift
//  56sim
//
//  The Poster Foundry: choose a slogan, choose a compliant ink colour,
//  optionally overprint a neighbour's face, share with the people.
//

import PhotosUI
import SwiftUI

struct PosterGeneratorView: View {
 @State private var sloganIndex = 0
 @State private var palette: Palette = .red
 @State private var textSize: Double = 24
 @State private var photoItem: PhotosPickerItem?
 @State private var face: Image?

 private var posterCard: some View {
  PosterCard(
   slogan: Propaganda.slogans[sloganIndex],
   palette: palette,
   face: face,
   textSize: textSize
  )
  .frame(width: 360)
 }

 var body: some View {
  Form {
   Section("Message") {
    Picker("Slogan", selection: $sloganIndex) {
     ForEach(Propaganda.slogans.indices, id: \.self) { index in
      Text(Propaganda.slogans[index].text).tag(index)
     }
    }
    Slider(value: $textSize, in: 18...34) {
     Text("Poster shout volume")
    } minimumValueLabel: {
     Text("murmur")
    } maximumValueLabel: {
     Text("GLORY")
    }
   }
   Section("Ink (approved choices only)") {
    Picker("Palette", selection: $palette) {
     Text("Red").tag(Palette.red)
     Text("Ink").tag(Palette.ink)
     Text("Green").tag(Palette.green)
    }
    .pickerStyle(.segmented)
   }
   Section("Re-education subject (optional)") {
    PhotosPicker(selection: $photoItem, matching: .images) {
     Label(face == nil ? "Add a face" : "Change the face", systemImage: "person.crop.square")
    }
    if face != nil {
     Button("Remove face", role: .destructive) {
      face = nil
      photoItem = nil
     }
    }
   }
   Section("Proof") {
    posterCard
     .frame(maxWidth: .infinity, alignment: .center)
     .listRowBackground(Color.clear)
   }
   Section {
    if let png = renderedPNG, let url = writtenShareURL(for: png) {
     ShareLink(item: url) {
      Label("Print for the people", systemImage: "square.and.arrow.up")
     }
    }
   }
  }
  .navigationTitle("Poster Foundry")
  .onChange(of: photoItem) { _, newItem in
   guard let newItem else { return }
   Task {
    if let data = try? await newItem.loadTransferable(type: Data.self),
     let ui = UIImage(data: data)
    {
     face = Image(uiImage: ui)
    }
   }
  }
 }

 /// Three-times-scale rendering of the poster, exported as PNG.
 private var renderedPNG: Data? {
  let renderer = ImageRenderer(content: posterCard)
  renderer.scale = 3
  return renderer.uiImage?.pngData()
 }

 /// Drops the PNG in the temporary directory so the share sheet gets a real file.
 private func writtenShareURL(for png: Data) -> URL? {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent("peoples-poster.png")
  do {
   try png.write(to: url)
   return url
  } catch {
   return nil
  }
 }
}

#Preview {
 NavigationStack {
  PosterGeneratorView()
 }
}
