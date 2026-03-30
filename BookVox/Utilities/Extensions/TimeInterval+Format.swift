import Foundation

extension TimeInterval {
    /// "3:45" formatinda mm:ss string dondurur
    var mmss: String {
        let totalSeconds = Int(self)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
