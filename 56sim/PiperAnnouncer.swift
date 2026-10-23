import Foundation
import piper_player

/// Voice of the people: Piper TTS with the reza_ibrahim medium voice,
/// fetched once from huggingface and cached in Application Support.
@MainActor
@Observable
final class PiperAnnouncer {
    enum VoicePhase: Equatable { case notDownloaded, downloading(Double), ready, failed(String) }

    private(set) var phase: VoicePhase = .notDownloaded
    private(set) var isSpeaking = false

    private var player: PiperPlayer?
    private var downloadTask: Task<Void, Never>?

    static let voiceBase = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/reza_ibrahim/medium/en_US-reza_ibrahim-medium"
    static let voiceName = "en_US-reza_ibrahim-medium"

    /// Downloads if needed, then speaks `text`; cancels any current speech first
    /// (the radio always reads the freshest bulletin, never a backlog).
    func speak(_ text: String) {
        Task {
            do {
                let p = try await ensurePlayer()
                await p.stopAndCancel()
                isSpeaking = true
                try await p.play(text: text)
            } catch {
                phase = .failed("Foreign sabotage of the loudspeaker: \(error.localizedDescription)")
            }
            isSpeaking = false
        }
    }

    func stop() {
        let p = player
        Task { await p?.stopAndCancel() }
        isSpeaking = false
    }

    private func ensurePlayer() async throws -> PiperPlayer {
        if let player { return player }
        let dir = try Self.voiceDirectory()
        let onnx = dir.appendingPathComponent("\(Self.voiceName).onnx")
        let json = dir.appendingPathComponent("\(Self.voiceName).onnx.json")
        if !FileManager.default.fileExists(atPath: onnx.path) || !FileManager.default.fileExists(atPath: json.path) {
            try await download(into: dir, onnx: onnx, json: json)
        }
        let params = PiperPlayer.Params(
            modelPath: onnx.path, configPath: json.path, espeakNGData: ""
        )
        let p = try PiperPlayer(params: params)
        player = p
        phase = .ready
        return p
    }

    private func download(into dir: URL, onnx: URL, json: URL) async throws {
        phase = .downloading(0)
        try await Self.downloadFile(from: URL(string: "\(Self.voiceBase).onnx.json")!, to: json)
        try await Self.downloadFile(from: URL(string: "\(Self.voiceBase).onnx")!, to: onnx,
            progress: { done, total in self.phase = .downloading(total > 0 ? Double(done) / Double(total) : 0) })
    }

    private static func voiceDirectory() throws -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("PiperVoices", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func downloadFile(from url: URL, to dest: URL, progress: ((Int64, Int64) -> Void)? = nil) async throws {
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let total = http.expectedContentLength
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count % 65_536 == 0 { progress?(Int64(data.count), total) }
        }
        progress?(Int64(data.count), total)
        try data.write(to: dest)
    }
}
