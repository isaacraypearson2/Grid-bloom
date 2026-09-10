import SwiftUI
import PhotosUI
import UIKit

struct FlowerScanView: View {
    @ObservedObject var profile: PlayerProfile
    var theme: BoardTheme
    var onClose: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var sourceImage: UIImage?
    @State private var stamp: UIImage?
    @State private var draft: FlowerScanDraft?
    @State private var working = false
    @State private var errorText: String?
    @State private var savedName: String?

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan a flower")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Camera or a photo from your library. Classified on this iPhone — nothing is uploaded.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        scanButtonLabel("Camera", systemImage: "camera.fill")
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        scanButtonLabel("Photo library", systemImage: "photo.on.rectangle")
                    }
                }

                if working {
                    ProgressView("Reading the bloom…")
                        .tint(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }

                if let stamp, let draft {
                    previewCard(stamp: stamp, draft: draft)
                } else if let errorText {
                    Text(errorText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }

                if let savedName {
                    Text("\(savedName) is in your album and can appear in Classic Garden.")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
                }

                Spacer()
            }
            .padding(22)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let image { process(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            pickerItem = nil
            Task { await loadPicker(item) }
        }
    }

    private func scanButtonLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func previewCard(stamp: UIImage, draft: FlowerScanDraft) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: stamp)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
            Text(draft.name)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            if let hint = draft.speciesHint {
                Text("Reads like a \(hint.title.lowercased())")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            Text(draft.note)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.inkSoft)
                .multilineTextAlignment(.center)
            PrimaryGardenButton(title: "Plant in album", fill: theme.accent) {
                save(stamp: stamp, draft: draft)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(theme.cream.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func loadPicker(_ item: PhotosPickerItem) async {
        await MainActor.run {
            working = true
            errorText = nil
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { process(image) }
            } else {
                await MainActor.run {
                    working = false
                    errorText = "Couldn’t read that photo."
                }
            }
        } catch {
            await MainActor.run {
                working = false
                errorText = "Couldn’t read that photo."
            }
        }
    }

    private func process(_ image: UIImage) {
        working = true
        errorText = nil
        savedName = nil
        sourceImage = image
        DispatchQueue.global(qos: .userInitiated).async {
            let analyzed = FlowerScanner.analyze(image)
            let stampImage = CustomBloomDisk.makeStamp(from: image)
            DispatchQueue.main.async {
                draft = analyzed
                stamp = stampImage
                working = false
                Haptics.success()
            }
        }
    }

    private func save(stamp: UIImage, draft: FlowerScanDraft) {
        if let bloom = profile.addCustomBloom(name: draft.name, stamp: stamp, draft: draft) {
            savedName = bloom.name
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 2)
        } else {
            errorText = "Album is full (12 scanned blooms). Remove one first."
            Haptics.error()
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImage(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            onImage(image)
        }
    }
}
