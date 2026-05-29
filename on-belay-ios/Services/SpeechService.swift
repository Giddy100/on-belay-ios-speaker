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

    private var wakeupPhrase = "hey moses"
    private var wakeupWords = ["hey","moses"]
    private var isWaitingForCommand = false
    private var commandTimer: Timer?
    private var lastPushTime: Date?

    private var selectedGroup: Group?
    private var volume: Float = 1.0
    
    private var converter = BufferConverter()
    
    func setup(wakeupPhrase: String, selectedGroup: Group?, volume: Float?) {
        self.wakeupPhrase = wakeupPhrase.lowercased()
        wakeupWords.removeAll()
        let words = wakeupPhrase.split(separator: " ")
        for word in words {
            self.wakeupWords.append(String(word.lowercased()))
        }
        self.selectedGroup = selectedGroup
        self.volume = volume ?? 1.0
    }

    func startListening() {
        if (isListening){
            return
        }
        isListening = true
        print("SpeechService: Requesting authorization...")
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("SpeechService: Authorization status: \(status.rawValue)")
                switch status {
                case .authorized:
                    Task {
                        await self.doStartListening()
                    }
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

    private func doStartListening() async {
        print("SpeechService: doStartListening called")
        guard !audioEngine.isRunning else {
            print("SpeechService: Audio engine already running")
            return
        }

        do {
            try configureAudioSession()

            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.removeTap(onBus: 0)

            guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
                /* Note unsupported language */
                print("English is not supported on this device")
                return
            }
            let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
            
            if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await installationRequest.downloadAndInstall()
            }
            
            let (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)

            let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            
            // Initialize the modern SpeechAnalyzer
            self.analyzer = analyzer

            task = Task {
                print("SpeechService: Starting analyzer results loop")
                do {
                    for try await result in transcriber.results {
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

            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self]buffer, _ in
                guard let audioFormat else { return }
                do {
                    let converted = try self!.converter.convertBuffer(buffer, to: audioFormat)
                    inputBuilder.yield(AnalyzerInput(buffer: converted))
                } catch {
                    print("Exception when converting audio")
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            print("SpeechService: Audio engine started")
            
            try await analyzer.start(inputSequence: inputSequence)

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
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func handleAnalyzerResult(_ result: SpeechTranscriber.Result) {
        if result.isFinal {
            handleTranscription(result.text)
        }

        /*
        if let detection = result.speechDetection {
            if detection.isSpeechDetected {
                print("SpeechService: Voice activity detected")
            }
        }
         */
    }

    private func handleTranscription(_ transcription: AttributedString) {
        let transcript = String(transcription.characters).lowercased()
        print("Speech transcription: \(transcript)")
        if (transcript.isEmpty
            || transcript.contains("it's moses")
            || transcript.contains("no command")
            || transcript.contains("unknown command")
            ){
            return
        }

        if !isWaitingForCommand {
            if let lastPush = lastPushTime, Date().timeIntervalSince(lastPush) <= 20 {
                if transcript.contains("ok") {
                    if let okPhrase = findPhraseByName("OK") {
                        processCommand(okPhrase)
                        lastPushTime = nil // Reset after successful OK
                        return
                    }
                }
            }

            if isWakeupPhrase(transcript) {
                addLog("Wakeup phrase '\(wakeupPhrase)' detected")
                enterCommandMode()
            }
        } else {
            if let matchedPhrase = findMatchedPhrase(in: transcript) {
                processCommand(matchedPhrase)
            } else {
                handleUnknownCommand()
            }
        }
    }

    private func findPhraseByName(_ name: String) -> Phrase? {
        guard let phrases = selectedGroup?.phrases else { return nil }
        return phrases.first { $0.name == name }
    }
    
    private func isWakeupPhrase(_ phrase: String) -> Bool {
        if phrase.contains(wakeupPhrase) { return true }
        for word in wakeupWords {
            if !phrase.contains(word) { return false }
        }
        return true
            
    }

    private func enterCommandMode() {
        print("Entering command mode. Looking for commands...")
        isWaitingForCommand = true
        AudioService.shared.playSound("its_moses.wav", volume: volume)
        addLog(NSLocalizedString("waiting_command", comment: ""))

        // Reset analyzer to get a clean transcript for the command
        // resetAnalyzer()

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

        AudioService.shared.playSounds(["notifying", phrase.soundFileName], volume: volume)

        if let groupId = selectedGroup?.groupId {
            Task {
                await FirebaseService.shared.notifyGroupMembers(groupId: groupId, phraseId: phrase.phraseId)
            }
        }

        Task {
            // await resetAnalyzer()
            addLog(NSLocalizedString("waiting_wakeup", comment: ""))
        }
    }

    private func handleUnknownCommand() {
        addLog(NSLocalizedString("unknown_command", comment: ""))
        AudioService.shared.playSound("unknown_command.wav", volume: volume)
        commandTimer?.invalidate()
        commandTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.handleCommandTimeout()
        }
    }

    private func handleCommandTimeout() {
        if isWaitingForCommand {
            isWaitingForCommand = false
            addLog(NSLocalizedString("no_command", comment: ""))
            AudioService.shared.playSound("no_command.wav", volume: volume)
            Task {
                // await resetAnalyzer()
                addLog(NSLocalizedString("waiting_wakeup", comment: ""))
            }
        }
    }

    private func resetAnalyzer() async {
        print("SpeechService: Resetting analyzer")
        task?.cancel()
        task = nil
        analyzer = nil

        do {
            guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
                /* Note unsupported language */
                print("English is not supported on this device")
                return
            }
            let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
            
            // Note: SpeechAnalyzer.bestAvailableAudioFormat is not needed here as we don't install a tap in resetAnalyzer
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer

            task = Task {
                do {
                    for try await result in transcriber.results {
                        if Task.isCancelled { break }
                        self.handleAnalyzerResult(result)
                    }
                } catch {
                    print("SpeechService: Error resetting analyzer: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restartRecognition() {
        print("SpeechService: restartRecognition called")

        // Stop current task and engine but keep isListening = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isListening {
                Task {
                    await self.analyzer?.cancelAndFinishNow()
                    self.analyzer = nil
                    await self.doStartListening()
                }
            }
        }
    }

    func notifyPushReceived() {
        lastPushTime = Date()
        print("SpeechService: Push received, 20s window for 'OK' started")
    }

    func addLog(_ message: String) {
        DispatchQueue.main.async {
            self.logs.append(message)
        }
    }
}

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
