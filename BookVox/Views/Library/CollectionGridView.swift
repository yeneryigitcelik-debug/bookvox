import SwiftUI
import SwiftData

// MARK: - Koleksiyon grid gorunumu
// Kitap koleksiyonlarini yonetme ve goruntuleleme

struct CollectionGridView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Collection.sortOrder) private var collections: [Collection]
    @State private var showNewCollection = false
    @State private var newCollectionName = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "#5856D6"

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    private let iconOptions = [
        "folder", "heart.fill", "star.fill", "book.fill",
        "headphones", "moon.fill", "flame.fill", "leaf.fill",
        "brain", "lightbulb.fill", "globe", "graduationcap.fill"
    ]

    private let colorOptions = [
        "#FF2D55", "#FF9500", "#FFD60A", "#34C759",
        "#5AC8FA", "#5856D6", "#AF52DE", "#FF375F"
    ]

    var body: some View {
        ScrollView {
            if collections.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(collections, id: \.id) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            collectionCard(collection)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Koleksiyonlar")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewCollection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Yeni Koleksiyon", isPresented: $showNewCollection) {
            TextField("Koleksiyon adi", text: $newCollectionName)
            Button("Olustur") { createCollection() }
            Button("Iptal", role: .cancel) { }
        }
        .onAppear { createDefaultsIfNeeded() }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Koleksiyon Yok", systemImage: "folder")
        } description: {
            Text("Kitaplarini organize etmek icin koleksiyonlar olustur")
        } actions: {
            Button("Koleksiyon Olustur") {
                showNewCollection = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func collectionCard(_ collection: Collection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: collection.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hexString: collection.colorHex))

                Spacer()

                Text("\(collection.books.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
            }

            Text(collection.name)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Mini kapak resimleri (ilk 3 kitap)
            HStack(spacing: -8) {
                ForEach(Array(collection.books.prefix(3).enumerated()), id: \.offset) { _, book in
                    if let data = book.coverImageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 28, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.background, lineWidth: 2)
                            )
                    }
                }

                if collection.books.count > 3 {
                    Text("+\(collection.books.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func createCollection() {
        guard !newCollectionName.isEmpty else { return }
        let collection = Collection(
            name: newCollectionName,
            icon: selectedIcon,
            colorHex: selectedColor,
            sortOrder: collections.count
        )
        context.insert(collection)
        try? context.save()
        newCollectionName = ""
        HapticService.importComplete()
    }

    private func createDefaultsIfNeeded() {
        guard collections.isEmpty else { return }
        for (index, def) in Collection.defaultCollections.enumerated() {
            let collection = Collection(
                name: def.name,
                icon: def.icon,
                colorHex: def.color,
                sortOrder: index
            )
            context.insert(collection)
        }
        try? context.save()
    }
}

// MARK: - Koleksiyon detay

struct CollectionDetailView: View {
    let collection: Collection

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            if collection.books.isEmpty {
                ContentUnavailableView(
                    "Bos Koleksiyon",
                    systemImage: collection.icon,
                    description: Text("Bu koleksiyona henuz kitap eklenmedi")
                )
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(collection.books, id: \.id) { book in
                        NavigationLink {
                            ReaderView(book: book)
                        } label: {
                            BookCardView(book: book)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(collection.name)
    }
}

#Preview {
    NavigationStack {
        CollectionGridView()
    }
    .modelContainer(for: [Collection.self, Book.self], inMemory: true)
}
