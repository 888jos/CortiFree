import PhotosUI
import SwiftUI

struct ProgressPhotosSection: View {
    @ObservedObject private var store = ProgressPhotoStore.shared
    @ObservedObject private var faceStore = FaceScanStore.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var showGallery = false
    @State private var importError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("progress.photos.title".localized)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)
                Spacer()
                if !store.photos.isEmpty {
                    Button {
                        showGallery = true
                    } label: {
                        Text("progress.photos.see_all".localized)
                            .font(.faroSemiBold(12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassSecondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                            Text("progress.photos.add".localized)
                                .font(.faroSemiBold(11))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.white)
                        .frame(width: 118, height: 138)
                        .glassCard(cornerRadius: 18, tint: Color(hex: "49288C"), interactive: true)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                        }
                    }

                    ForEach(store.photos.prefix(4)) { photo in
                        if let image = store.image(for: photo) {
                            Button {
                                showGallery = true
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 118, height: 138)
                                        .clipped()
                                    Text(photo.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.faroRegular(9))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 5)
                                        .glassCapsule()
                                        .padding(7)
                                }
                                .overlay(alignment: .topLeading) { FaceScanPhotoBadge(photo: photo).padding(7) }
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        try store.add(data: data)
                        HapticManager.success()
                    }
                } catch {
                    importError = true
                    HapticManager.error()
                }
                selectedItem = nil
            }
        }
        .onAppear { faceStore.reload() }
        .fullScreenCover(isPresented: $showGallery) {
            ProgressPhotoGalleryView()
        }
        .alert("progress.photos.error_title".localized, isPresented: $importError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("progress.photos.error_message".localized)
        }
    }
}

private struct ProgressPhotoGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = ProgressPhotoStore.shared

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.55)
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)
                    Spacer()
                    Text("progress.photos.title".localized)
                        .font(.faroSemiBold(18))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 10)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                        ForEach(store.photos) { photo in
                            if let image = store.image(for: photo) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(0.82, contentMode: .fit)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(alignment: .bottomLeading) { FaceScanPhotoBadge(photo: photo).padding(8) }

                                    Button(role: .destructive) {
                                        store.delete(photo)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 34, height: 34)
                                            .contentShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .glassCircle(tint: .black, interactive: true)
                                    .padding(7)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

/// Week and « rested » score on photos taken by the weekly face check.
private struct FaceScanPhotoBadge: View {
    let photo: ProgressPhoto
    @ObservedObject private var faceStore = FaceScanStore.shared

    var body: some View {
        if let record = faceStore.records.first(where: { $0.photoID == photo.id }) {
            HStack(spacing: 4) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 9, weight: .semibold))
                Text(verbatim: "\(String(format: "calm.face.result.week".localized, record.slot + 1)) · \(record.result.restedScore)")
                    .font(.faroSemiBold(9))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .glassCapsule(tint: Color.appTheme)
        }
    }
}
