import Foundation

// MARK: - TTS Worker API servisi
// Railway uzerindeki FastAPI worker ile iletisim

struct TTSService {

    // Kullanilabilir ses tonlari
    enum Tone: String, CaseIterable, Identifiable {
        case standard
        case storyteller
        case academic
        case intimate
        case dramatic

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .standard: "Standard"
            case .storyteller: "Storyteller"
            case .academic: "Academic"
            case .intimate: "Intimate"
            case .dramatic: "Dramatic"
            }
        }

        var icon: String {
            switch self {
            case .standard: "waveform"
            case .storyteller: "book"
            case .academic: "graduationcap"
            case .intimate: "heart"
            case .dramatic: "theatermasks"
            }
        }
    }

    struct RenderResponse: Decodable {
        let audioURL: String
        let durationSec: Double

        enum CodingKeys: String, CodingKey {
            case audioURL = "audio_url"
            case durationSec = "duration_sec"
        }
    }

    struct BatchResult: Decodable {
        let page: Int
        let audioURL: String
        let durationSec: Double

        enum CodingKeys: String, CodingKey {
            case page
            case audioURL = "audio_url"
            case durationSec = "duration_sec"
        }
    }

    struct BatchResponse: Decodable {
        let results: [BatchResult]
    }

    // Tek sayfa icin TTS renderla
    static func renderPage(
        bookId: String,
        pageNumber: Int,
        tone: Tone,
        textContent: String
    ) async throws -> RenderResponse {
        let url = Constants.TTS.baseURL.appendingPathComponent("render-page")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "book_id": bookId,
            "page_number": pageNumber,
            "tone": tone.rawValue,
            "text_content": textContent
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        request.timeoutInterval = Constants.TTS.requestTimeoutSec

        return try await RetryHelper.withRetry {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw TTSError.renderFailed
            }
            return try JSONDecoder().decode(RenderResponse.self, from: data)
        }
    }

    // Birden fazla sayfa icin toplu TTS renderla
    static func renderBatch(
        bookId: String,
        pages: [Int],
        tone: Tone
    ) async throws -> BatchResponse {
        let url = Constants.TTS.baseURL.appendingPathComponent("render-batch")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "book_id": bookId,
            "pages": pages,
            "tone": tone.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = Constants.TTS.requestTimeoutSec

        return try await RetryHelper.withRetry {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw TTSError.renderFailed
            }
            return try JSONDecoder().decode(BatchResponse.self, from: data)
        }
    }

    enum TTSError: LocalizedError {
        case renderFailed
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .renderFailed: "TTS render islemi basarisiz"
            case .invalidResponse: "Gecersiz API yaniti"
            }
        }
    }
}
