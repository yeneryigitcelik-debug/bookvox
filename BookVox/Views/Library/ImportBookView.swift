import SwiftUI
import UniformTypeIdentifiers

// MARK: - Kitap import sheet

struct ImportBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var viewModel: LibraryViewModel

    @State private var showFilePicker = false
    @State private var selectedURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xxl) {
                Spacer()

                // Gorsel
                VStack(spacing: DS.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(.bookVoxAccent.opacity(0.08))
                            .frame(width: 120, height: 120)

                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.bookVoxAccent)
                    }

                    Text("PDF Kitap Yukle")
                        .font(.title3.weight(.bold))

                    Text("Dosyalarindan bir PDF kitap sec")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Secilen dosya
                if let url = selectedURL {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.bookVoxAccent)
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            withAnimation(DS.Anim.quick) { selectedURL = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(DS.Spacing.lg)
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.xxl)
                    .transition(.scale.combined(with: .opacity))
                }

                // Butonlar
                VStack(spacing: DS.Spacing.md) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Dosya Sec", systemImage: "folder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(selectedURL == nil ? Color.bookVoxAccent : Color(.secondarySystemFill))
                            .foregroundStyle(selectedURL == nil ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    }

                    if selectedURL != nil {
                        Button {
                            guard let url = selectedURL else { return }
                            Task {
                                await viewModel.importBook(from: url, context: context)
                                dismiss()
                            }
                        } label: {
                            Text("Yukle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.bookVoxAccent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                        }
                        .disabled(viewModel.isLoading)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DS.Spacing.xxl)
                .animation(DS.Anim.spring, value: selectedURL != nil)

                ErrorBanner(message: viewModel.errorMessage)
                    .padding(.horizontal, DS.Spacing.xxl)

                Spacer()
            }
            .navigationTitle("Kitap Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Iptal") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    withAnimation(DS.Anim.spring) { selectedURL = urls.first }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ImportBookView(viewModel: LibraryViewModel())
        .modelContainer(for: [Book.self], inMemory: true)
}
