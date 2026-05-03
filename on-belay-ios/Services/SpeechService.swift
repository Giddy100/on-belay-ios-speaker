import Foundation
import Speech
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

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
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
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

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                print("SpeechService: Unable to create recognition request")
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    self.handleSpeechResult(result)
                }

                if let error = error {
                    print("SpeechService: Recognition error: \(error.localizedDescription)")
                    if self.isListening {
                        self.restartRecognition()
                    }
                } else if result?.isFinal == true {
                    print("SpeechService: Recognition final")
                    if self.isListening {
                        self.restartRecognition()
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
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

    private func handleSpeechResult(_ result: SFSpeechRecognitionResult) {
        let transcript = result.bestTranscription.formattedString.lowercased()
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

        // Reset transcript by starting a new request
        resetRecognitionRequest()

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

        resetRecognitionRequest()
        addLog(NSLocalizedString("waiting_wakeup", comment: ""))
    }

    private func handleCommandTimeout() {
        if isWaitingForCommand {
            isWaitingForCommand = false
            addLog(NSLocalizedString("no_command", comment: ""))
            AudioService.shared.playSound("no_command.wav", volume: volume)
            resetRecognitionRequest()
            addLog(NSLocalizedString("waiting_wakeup", comment: ""))
        }
    }

    private func resetRecognitionRequest() {
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.handleSpeechResult(result)
            }
            if let error = error {
                print("SpeechService: Recognition error (reset): \(error.localizedDescription)")
                if self.isListening {
                    self.restartRecognition()
                }
            } else if result?.isFinal == true {
                print("SpeechService: Recognition final (reset)")
                if self.isListening {
                    self.restartRecognition()
                }
            }
        }
    }

    private func restartRecognition() {
        print("SpeechService: restartRecognition called")

        // Stop current task and engine but keep isListening = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

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
