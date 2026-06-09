import Foundation
import AVFoundation

class AudioService: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioService()
    private var player: AVAudioPlayer?
    private var queue: [String] = []
    private var currentVolume: Float = 1.0

    func playSound(_ filename: String, volume: Float) {
        playSounds([filename], volume: volume)
    }

    func playSounds(_ filenames: [String], volume: Float) {
        self.queue = filenames
        self.currentVolume = volume
        playNextInQueue()
    }

    private func playNextInQueue() {
        guard !queue.isEmpty else { return }
        let filename = queue.removeFirst()

        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".wav", with: ""), withExtension: "wav") else {
            print("Sound file not found: \(filename)")
            playNextInQueue()
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
                try audioSession.setActive(true)
            }

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = currentVolume
            player?.play()
        } catch {
            print("Error playing sound: \(error)")
            playNextInQueue()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextInQueue()
    }
}
