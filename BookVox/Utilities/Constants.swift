import Foundation

// MARK: - Uygulama sabitleri
// API URL'leri ve konfigürasyon — xcconfig veya environment variable'dan okunur

enum Constants {

    // MARK: - Supabase
    enum Supabase {
        static let projectURL: URL = {
            guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  !urlString.isEmpty,
                  let url = URL(string: urlString)
            else {
                // Fallback — gelistirme ortami icin
                return URL(string: "https://YOUR_PROJECT.supabase.co")!
            }
            return url
        }()

        static let anonKey: String = {
            if let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty {
                return key
            }
            // Fallback — gelistirme ortami icin
            return "YOUR_ANON_KEY"
        }()

        static let storageBucket = "books"
    }

    // MARK: - TTS Worker (Railway)
    enum TTS {
        static let baseURL: URL = {
            if let urlString = Bundle.main.infoDictionary?["TTS_API_URL"] as? String,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }
            return URL(string: "https://bookvox-tts-worker.up.railway.app/api")!
        }()

        static let renderPagePath = "/render-page"
        static let renderBatchPath = "/render-batch"
        static let tonesPath = "/tones"
        static let prefetchPageCount = 2
        static let requestTimeoutSec: TimeInterval = 120
    }

    // MARK: - Cloudflare R2
    enum Storage {
        static let r2BaseURL: URL = {
            if let urlString = Bundle.main.infoDictionary?["R2_BASE_URL"] as? String,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }
            return URL(string: "https://YOUR_R2_BUCKET.r2.dev")!
        }()
    }

    // MARK: - Uygulama
    enum App {
        static let freeBookLimit = 3
        static let freeTones: Set<String> = [
            TTSService.Tone.standard.rawValue,
            TTSService.Tone.storyteller.rawValue
        ]
        static let appStoreId = "YOUR_APP_STORE_ID"
        static let supportEmail = "support@bookvox.app"
        static let websiteURL = URL(string: "https://bookvox.app")!
    }

    // MARK: - TelemetryDeck
    enum Analytics {
        static let appID: String = {
            if let id = Bundle.main.infoDictionary?["TELEMETRYDECK_APP_ID"] as? String, !id.isEmpty {
                return id
            }
            return ""
        }()
    }
}
