import Foundation
import Speech
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var task: Task<Void, Never>?

    @Published var isListening = false
    @Published var logs: [String] = []
    @Published var lastError: String?

    private var wakeupPhrase = "Hey Moses"
    private var isWaitingForCommand = false
    private var commandTimer: Timer?

    private var selectedGroup: Group?
    private var volume: Float = 1.0

    func setup(wakeupPhrase: String, selectedGroup: Group?, volume: Float?) {
        self.wakeupPhrase = wakeupPhrase
        self.selectedGroup = selectedGroup
        self.volume = volume ?? 1.0
    }

    func startListening() {
        isListening = true
        print("SpeechService: Requesting authorization...")
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("SpeechService: Authorization status: \(status.rawValue)")
                switch status {
                case .authorized:
                    self.doStartListening()
                default:
                    self.isListening = false
                    self.lastError = "Speech recognition not authorized"
                    self.addLog("Error: Speech recognition not authorized")
                }
            }
        }
    }

    func stopListening() {
        print("SpeechService: stopListening called")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        analyzer = nil
        isListening = false
        isWaitingForCommand = false
        commandTimer?.invalidate()
    }

    private func doStartListening() {
        print("SpeechService: doStartListening called")
        guard !audioEngine.isRunning else {
            print("SpeechService: Audio engine already running")
            return
        }

        do {
            try configureAudioSession()

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)

            // Initialize the modern SpeechAnalyzer
            let analyzer = try SpeechAnalyzer(audioFormat: recordingFormat)
            self.analyzer = analyzer

            let transcriber = SpeechTranscriber()
            let detector = SpeechDetector()

            task = Task {
                print("SpeechService: Starting analyzer results loop")
                do {
                    for await result in analyzer.results(modules: [transcriber, detector]) {
                        if Task.isCancelled { break }
                        self.handleAnalyzerResult(result)
                    }
                } catch {
                    print("SpeechService: Analyzer error: \(error.localizedDescription)")

                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 203 {
                        self.addLog(NSLocalizedString("error_siri_disabled", comment: ""))
                        self.stopListening()
                    } else if self.isListening {
                        self.restartRecognition()
                    }
                }
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.analyzer?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            print("SpeechService: Audio engine started")

            isListening = true
            addLog(NSLocalizedString("waiting_wakeup", comment: ""))
        } catch {
            print("SpeechService: Error starting listening: \(error.localizedDescription)")
            addLog("Error starting listening: \(error.localizedDescription)")
            lastError = error.localizedDescription
            isListening = false
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func handleAnalyzerResult(_ result: SpeechAnalyzer.Result) {
        if let transcription = result.transcription {
            handleTranscription(transcription)
        }

        if let detection = result.speechDetection {
            if detection.isSpeechDetected {
                print("SpeechService: Voice activity detected")
            }
        }
    }

    private func handleTranscription(_ transcription: SpeechTranscriber.Result) {
        let transcript = transcription.bestTranscription.formattedString.lowercased()
        print("Speech transcription: \(transcript)")

        if !isWaitingForCommand {
            if transcript.contains(wakeupPhrase.lowercased()) {
                addLog("Wakeup phrase '\(wakeupPhrase)' detected")
                enterCommandMode()
            }
        } else {
            if let matchedPhrase = findMatchedPhrase(in: transcript) {
                processCommand(matchedPhrase)
            }
        }
    }

    private func enterCommandMode() {
        print("Entering command mode. Looking for commands...")
        isWaitingForCommand = true
        addLog(NSLocalizedString("waiting_command", comment: ""))

        // Reset analyzer to get a clean transcript for the command
        resetAnalyzer()

        commandTimer?.invalidate()
        commandTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.handleCommandTimeout()
        }
    }

    private func findMatchedPhrase(in transcript: String) -> Phrase? {
        guard let phrases = selectedGroup?.phrases else { return nil }
        return phrases.filter { $0.selected }.first { phrase in
            phrase.utterances.contains { utterance in
                transcript.contains(utterance.lowercased())
            }
        }
    }

    private func processCommand(_ phrase: Phrase) {
        print("Command identified: \(phrase.name)")
        commandTimer?.invalidate()
        isWaitingForCommand = false
        addLog(String(format: NSLocalizedString("command_identified", comment: ""), phrase.name))

        AudioService.shared.playSound(phrase.soundFileName, volume: volume)

        if let groupId = selectedGroup?.groupId {
            Task {
                await FirebaseService.shared.notifyGroupMembers(groupId: groupId, phraseId: phrase.phraseId)
            }
        }

        resetAnalyzer()
        addLog(NSLocalizedString("waiting_wakeup", comment: ""))
    }

    private func handleCommandTimeout() {
        if isWaitingForCommand {
            isWaitingForCommand = false
            addLog(NSLocalizedString("no_command", comment: ""))
            AudioService.shared.playSound("no_command.wav", volume: volume)
            resetAnalyzer()
            addLog(NSLocalizedString("waiting_wakeup", comment: ""))
        }
    }

    private func resetAnalyzer() {
        print("SpeechService: Resetting analyzer")
        task?.cancel()
        task = nil
        analyzer = nil

        guard let inputNode = try? audioEngine.inputNode else { return }
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        do {
            let analyzer = try SpeechAnalyzer(audioFormat: recordingFormat)
            self.analyzer = analyzer

            let transcriber = SpeechTranscriber()
            let detector = SpeechDetector()

            task = Task {
                for await result in analyzer.results(modules: [transcriber, detector]) {
                    if Task.isCancelled { break }
                    self.handleAnalyzerResult(result)
                }
            }
        } catch {
            print("SpeechService: Error resetting analyzer: \(error.localizedDescription)")
        }
    }

    private func restartRecognition() {
        print("SpeechService: restartRecognition called")

        // Stop current task and engine but keep isListening = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        analyzer = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isListening {
                self.doStartListening()
            }
        }
    }

    func addLog(_ message: String) {
        DispatchQueue.main.async {
            self.logs.append(message)
        }
    }
}

class AudioService {
    static let shared = AudioService()
    private var player: AVAudioPlayer?

    func playSound(_ filename: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".wav", with: ""), withExtension: "wav") else {
            print("Sound file not found: \(filename)")
            return
        }

        do {
            // Use the current session instead of switching to .playback which might stop recording
            let audioSession = AVAudioSession.sharedInstance()
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
                try audioSession.setActive(true)
            }

            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
}
