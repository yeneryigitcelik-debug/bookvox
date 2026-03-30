import Foundation
import Supabase
import Auth

// MARK: - Supabase istemci servisi
// Auth, database ve storage islemleri — production implementasyon

@Observable
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private(set) var currentUserId: String?
    private(set) var isInitialized = false

    private init() {
        client = SupabaseClient(
            supabaseURL: Constants.Supabase.projectURL,
            supabaseKey: Constants.Supabase.anonKey
        )

        Task { await initialize() }
    }

    private func initialize() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                currentUserId = session.user.id.uuidString
                isInitialized = true
            }
        } catch {
            await MainActor.run {
                isInitialized = true
            }
        }
    }

    // MARK: - Auth

    func signInWithEmail(_ email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        await MainActor.run {
            currentUserId = session.user.id.uuidString
        }
    }

    func signUpWithEmail(_ email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        if let session = response.session {
            await MainActor.run {
                currentUserId = session.user.id.uuidString
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        await MainActor.run {
            currentUserId = session.user.id.uuidString
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            currentUserId = nil
        }
    }

    func restoreSession() async -> Bool {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                currentUserId = session.user.id.uuidString
            }
            return true
        } catch {
            return false
        }
    }

    func deleteAccount() async throws {
        // Kullanici verilerini sil, auth kaydini sil
        guard let userId = currentUserId else { return }

        // Oncelikle kitaplari sil
        try await client.from("books")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        try await client.auth.signOut()
        await MainActor.run { currentUserId = nil }
    }

    // MARK: - Database — Books

    struct BookRow: Codable, Sendable {
        let id: String?
        let userId: String?
        let title: String
        let author: String
        let totalPages: Int
        let coverUrl: String?
        let pdfStoragePath: String
        let createdAt: String?
        let updatedAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case title
            case author
            case totalPages = "total_pages"
            case coverUrl = "cover_url"
            case pdfStoragePath = "pdf_storage_path"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    func insertBook(_ data: [String: Any]) async throws -> String {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let row = BookRow(
            id: nil,
            userId: userId,
            title: data["title"] as? String ?? "",
            author: data["author"] as? String ?? "Unknown",
            totalPages: data["total_pages"] as? Int ?? 0,
            coverUrl: data["cover_url"] as? String,
            pdfStoragePath: data["pdf_storage_path"] as? String ?? "",
            createdAt: nil,
            updatedAt: nil
        )

        let result: BookRow = try await client.from("books")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        return result.id ?? ""
    }

    // MARK: - Database — Pages

    struct PageRow: Codable, Sendable {
        let id: String?
        let bookId: String
        let pageNumber: Int
        let textContent: String
        let audioUrl: String?
        let audioDurationSec: Double?
        let contextAnalysis: String?
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case bookId = "book_id"
            case pageNumber = "page_number"
            case textContent = "text_content"
            case audioUrl = "audio_url"
            case audioDurationSec = "audio_duration_sec"
            case contextAnalysis = "context_analysis"
            case createdAt = "created_at"
        }
    }

    func insertPages(_ pages: [[String: Any]], bookId: String) async throws {
        let rows = pages.map { data in
            PageRow(
                id: nil,
                bookId: bookId,
                pageNumber: data["page_number"] as? Int ?? 0,
                textContent: data["text_content"] as? String ?? "",
                audioUrl: nil,
                audioDurationSec: nil,
                contextAnalysis: nil,
                createdAt: nil
            )
        }

        // 50'lik batch'ler halinde ekle (Supabase limit)
        for batch in stride(from: 0, to: rows.count, by: 50) {
            let end = min(batch + 50, rows.count)
            let chunk = Array(rows[batch..<end])
            try await client.from("pages")
                .insert(chunk)
                .execute()
        }
    }

    func updatePageAudio(pageId: String, audioURL: String, duration: Double) async throws {
        try await client.from("pages")
            .update([
                "audio_url": audioURL,
                "audio_duration_sec": String(duration)
            ])
            .eq("id", value: pageId)
            .execute()
    }

    func fetchBooks() async throws -> [BookRow] {
        guard currentUserId != nil else {
            throw SupabaseError.notAuthenticated
        }

        let result: [BookRow] = try await client.from("books")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value

        return result
    }

    // MARK: - Database — Reading Progress

    struct ProgressRow: Codable, Sendable {
        let userId: String?
        let bookId: String
        let currentPage: Int
        let currentPositionSec: Double
        let updatedAt: String?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case bookId = "book_id"
            case currentPage = "current_page"
            case currentPositionSec = "current_position_sec"
            case updatedAt = "updated_at"
        }
    }

    func upsertProgress(bookId: String, page: Int, positionSec: Double) async throws {
        guard let userId = currentUserId else { return }

        let row = ProgressRow(
            userId: userId,
            bookId: bookId,
            currentPage: page,
            currentPositionSec: positionSec,
            updatedAt: nil
        )

        try await client.from("reading_progress")
            .upsert(row, onConflict: "user_id,book_id")
            .execute()
    }

    // MARK: - Database — Bookmarks

    struct BookmarkRow: Codable, Sendable {
        let id: String?
        let userId: String?
        let bookId: String
        let pageNumber: Int
        let note: String?
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case bookId = "book_id"
            case pageNumber = "page_number"
            case note
            case createdAt = "created_at"
        }
    }

    func insertBookmark(bookId: String, pageNumber: Int, note: String?) async throws {
        guard let userId = currentUserId else { return }

        let row = BookmarkRow(
            id: nil,
            userId: userId,
            bookId: bookId,
            pageNumber: pageNumber,
            note: note,
            createdAt: nil
        )

        try await client.from("bookmarks")
            .insert(row)
            .execute()
    }

    func deleteBookmark(bookId: String, pageNumber: Int) async throws {
        guard let userId = currentUserId else { return }

        try await client.from("bookmarks")
            .delete()
            .eq("user_id", value: userId)
            .eq("book_id", value: bookId)
            .eq("page_number", value: pageNumber)
            .execute()
    }

    // MARK: - Storage

    func uploadPDF(data: Data, path: String) async throws -> String {
        try await client.storage
            .from(Constants.Supabase.storageBucket)
            .upload(path, data: data, options: FileOptions(contentType: "application/pdf"))

        let url = try client.storage
            .from(Constants.Supabase.storageBucket)
            .getPublicURL(path: path)

        return url.absoluteString
    }

    func uploadCover(data: Data, bookId: String) async throws -> String {
        let path = "covers/\(bookId).jpg"

        try await client.storage
            .from(Constants.Supabase.storageBucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        let url = try client.storage
            .from(Constants.Supabase.storageBucket)
            .getPublicURL(path: path)

        return url.absoluteString
    }

    func downloadPDF(path: String) async throws -> Data {
        return try await client.storage
            .from(Constants.Supabase.storageBucket)
            .download(path: path)
    }

    // MARK: - Errors

    enum SupabaseError: LocalizedError {
        case notAuthenticated
        case networkError
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: "Oturum acmaniz gerekiyor"
            case .networkError: "Ag baglantisi kontrol edin"
            case .serverError(let msg): "Sunucu hatasi: \(msg)"
            }
        }
    }
}
