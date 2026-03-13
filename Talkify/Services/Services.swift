import Foundation
import AVFoundation
import Combine
import PDFKit
import UniformTypeIdentifiers

// MARK: - Audio Service
@MainActor
class AudioService: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    func loadAudio(from urlString: String) async {
        isLoading = true
        error = nil
        
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        // Stop any existing playback
        stop()
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe duration
        await observePlayerItem()
        
        // Add time observer
        addTimeObserver()
        
        isLoading = false
    }
    
    private func observePlayerItem() async {
        guard let playerItem = playerItem else { return }
        
        // Wait for the item to be ready
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if let duration = player?.currentItem?.duration.seconds, duration.isFinite {
            self.duration = duration
        }
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if let duration = self.player?.currentItem?.duration.seconds, duration.isFinite {
                    self.duration = duration
                }
            }
        }
    }
    
    func play() {
        player?.play()
        player?.rate = playbackRate
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func skipForward(seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return "-" + formatTime(remaining)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Document Service
class DocumentService {
    static let shared = DocumentService()
    
    private init() {}
    
    // Universal text extraction - detects file type automatically
    func extractText(from url: URL) async throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try await extractTextFromPDF(url: url)
        case "epub":
            return try await extractTextFromEPUB(url: url)
        case "txt", "text":
            return try await extractTextFromTXT(url: url)
        default:
            throw DocumentError.unsupportedFormat
        }
    }
    
    // Extract text from PDF file URL
    func extractTextFromPDF(url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentError.invalidPDF
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for pageIndex in 0..<pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        if fullText.isEmpty {
            throw DocumentError.emptyPDF
        }
        
        return fullText
    }
    
    // Extract text from EPUB file (basic implementation without external library)
    func extractTextFromEPUB(url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileManager = FileManager.default
        
        // Check if it's an extracted EPUB directory (some systems unzip automatically)
        let epubDirectory = url.deletingPathExtension()
        
        if fileManager.fileExists(atPath: epubDirectory.path) {
            // It's an extracted EPUB directory
            return try await extractTextFromExtractedEPUB(directory: epubDirectory)
        }
        
        // Try to read EPUB as a container - EPUB files are ZIP archives
        // For proper EPUB parsing, we'd need a library like ZIPFoundation
        // For now, return informative message
        
        // Check if we can access as ZIP (iOS 16+ has limited ZIP support)
        // Return a message about the limitation
        return """
        EPUB file detected: \(url.lastPathComponent)
        
        This file appears to be an EPUB ebook. For best results with EPUB files:
        
        1. Convert the EPUB to PDF using an online converter
        2. Or use the PDF upload option
        
        EPUB parsing requires additional libraries. This feature is coming soon!
        """
    }
    
    // Extract text from extracted EPUB directory
    private func extractTextFromExtractedEPUB(directory: URL) async throws -> String {
        let fileManager = FileManager.default
        var fullText = ""
        
        // Find and parse content.opf for spine order
        let contentsDir = directory.appendingPathComponent("OEBPS")
        
        if fileManager.fileExists(atPath: contentsDir.path) {
            // Read HTML files
            let htmlFiles = try fileManager.contentsOfDirectory(at: contentsDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "html" || $0.pathExtension == "xhtml" || $0.pathExtension == "htm" }
            
            for htmlFile in htmlFiles.prefix(50) { // Limit to first 50 files
                if let htmlContent = try? String(contentsOf: htmlFile, encoding: .utf8) {
                    // Strip HTML tags for basic text extraction
                    let text = stripHTMLTags(htmlContent)
                    fullText += text + "\n\n"
                }
            }
        }
        
        return fullText
    }
    
    // Strip HTML tags for basic text extraction
    private func stripHTMLTags(_ html: String) -> String {
        var result = html
        // Remove script and style tags with content
        let patterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<[^>]+>" // All HTML tags
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: " ")
            }
        }
        
        // Clean up whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Extract text from TXT file
    func extractTextFromTXT(url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Try different encodings
        let encodings: [String.Encoding] = [.utf8, .utf16, .isoLatin1, .windowsCP1252]
        
        for encoding in encodings {
            if let text = try? String(contentsOf: url, encoding: encoding), !text.isEmpty {
                return text
            }
        }
        
        throw DocumentError.invalidTXT
    }
    
    // Generate chapters from text
    func generateChapters(from text: String) -> [Chapter] {
        let lines = text.components(separatedBy: "\n")
        var chapters: [Chapter] = []
        var currentTitle = "Introduction"
        var chapterId = 1
        
        // Split by sections that look like chapters
        let chapterPatterns = ["Chapter", "SECTION", "Part", "Chapter"]
        
        var chapterContent: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line looks like a chapter heading
            let isChapterHeading = chapterPatterns.contains { pattern in
                trimmedLine.lowercased().contains(pattern.lowercased())
            }
            
            if isChapterHeading && !trimmedLine.isEmpty {
                // Save previous chapter if exists
                if !chapterContent.isEmpty {
                    chapters.append(Chapter(
                        id: "chapter_\(chapterId)",
                        title: currentTitle,
                        startPage: chapterId,
                        endPage: chapterId,
                        sections: nil
                    ))
                    chapterId += 1
                }
                currentTitle = trimmedLine
                chapterContent = []
            } else {
                chapterContent.append(line)
            }
        }
        
        // Add final chapter
        if !chapterContent.isEmpty {
            chapters.append(Chapter(
                id: "chapter_\(chapterId)",
                title: currentTitle,
                startPage: chapterId,
                endPage: chapterId,
                sections: nil
            ))
        }
        
        // If no chapters found, create one default chapter
        if chapters.isEmpty {
            chapters.append(Chapter(
                id: "chapter_1",
                title: "Full Content",
                startPage: 1,
                endPage: 1,
                sections: nil
            ))
        }
        
        return chapters
    }
    
    // Generate cover image URL (mock)
    func generateCoverImage(for title: String) -> String {
        let seed = abs(title.hashValue)
        return "https://picsum.photos/seed/\(seed)/300/400"
    }
}

// MARK: - AI Generation Service
class AIGenerationService {
    static let shared = AIGenerationService()
    
    private let openAIService = OpenAIService.shared
    private let appleIntelligenceService = AppleIntelligenceService.shared
    private let fileManager = AudioFileManager.shared
    
    // Use Apple Intelligence by default (free), with OpenAI as option
    var useAppleIntelligence: Bool = true
    
    private init() {}
    
    // Generate audio from text - uses Apple Intelligence by default (free)
    func generateAudio(from text: String, mode: ListeningMode, voice: VoiceOption) async throws -> GeneratedAudio {
        // Use Apple Intelligence by default
        if useAppleIntelligence {
            return try await generateWithAppleIntelligence(from: text, mode: mode, voice: voice)
        } else if OpenAIConfig.isConfigured {
            return try await generateRealAudio(from: text, mode: mode, voice: voice)
        } else {
            // Fall back to mock audio
            return try await generateMockAudio(from: text, mode: mode, voice: voice)
        }
    }
    
    // Generate audio using Apple Intelligence (free)
    private func generateWithAppleIntelligence(from text: String, mode: ListeningMode, voice: VoiceOption) async throws -> GeneratedAudio {
        // Generate script using Apple Intelligence
        let processedText = try await appleIntelligenceService.generateScript(from: text, mode: mode)
        
        // Calculate estimated duration
        let wordCount = processedText.components(separatedBy: .whitespacesAndNewlines).count
        let wpm = 150 // Average speaking rate
        let duration = Int((Double(wordCount) / Double(wpm)) * 60)
        
        // For Apple Intelligence, we'll create a reference to play using the synthesizer
        // The audio will be generated on-demand during playback
        let filename = UUID().uuidString
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).txt")
        
        // Save the script for playback
        try processedText.write(to: localURL, atomically: true, encoding: .utf8)
        
        return GeneratedAudio(
            audioURL: localURL.absoluteString,
            duration: max(duration, 30),
            transcript: processedText,
            useAppleSpeech: true
        )
    }
    
    // Real OpenAI TTS generation with GPT script generation
    private func generateRealAudio(from text: String, mode: ListeningMode, voice: VoiceOption) async throws -> GeneratedAudio {
        // Generate intelligent script using GPT
        let processedText = try await openAIService.generateScript(from: text, mode: mode)
        
        // Map voice option to OpenAI voice
        let openAIVoice = openAIService.mapVoiceOption(voice)
        
        // Generate speech using OpenAI TTS
        let audioData = try await openAIService.generateSpeech(
            text: processedText,
            voice: openAIVoice,
            model: OpenAIModels.tts1
        )
        
        // Save audio to file
        let filename = UUID().uuidString
        let localURL = try fileManager.saveAudio(audioData, filename: filename)
        
        // Estimate duration based on word count and speaking rate
        let wordCount = processedText.components(separatedBy: .whitespacesAndNewlines).count
        let wpm = 150 // Average speaking rate
        let duration = Int((Double(wordCount) / Double(wpm)) * 60)
        
        return GeneratedAudio(
            audioURL: localURL.absoluteString,
            duration: max(duration, 30),
            transcript: processedText
        )
    }
    
    // Generate script-only (for previewing the AI-generated script before audio)
    func generateScriptOnly(from text: String, mode: ListeningMode) async throws -> String {
        // Use Apple Intelligence by default
        if useAppleIntelligence {
            return try await appleIntelligenceService.generateScript(from: text, mode: mode)
        } else if OpenAIConfig.isConfigured {
            return try await openAIService.generateScript(from: text, mode: mode)
        } else {
            // Fall back to mock scripts
            return prepareTextForMode(text, mode: mode)
        }
    }
    
    // Prepare text based on listening mode (fallback when no API)
    private func prepareTextForMode(_ text: String, mode: ListeningMode) -> String {
        switch mode {
        case .narration:
            return cleanTextForNarration(text)
        case .podcast:
            return generatePodcastScript(from: text)
        case .summary:
            return generateSummary(from: text)
        case .lecture:
            return generateLecture(from: text)
        case .story:
            return generateStoryNarration(from: text)
        }
    }
    
    private func cleanTextForNarration(_ text: String) -> String {
        return text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generatePodcastScript(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let preview = words.prefix(200).joined(separator: " ")
        
        return """
        Host 1: Welcome to today's episode! I'm excited to dive into this content with you.
        
        Host 2: Thanks for having me! This is really fascinating material.
        
        Host 1: So let's get started. The main topic here is about \(preview)...
        
        Host 2: That's really interesting. Can you elaborate more on the key points?
        
        Host 1: Absolutely. The content discusses several important concepts...
        
        [The discussion continues covering the main points from the material]
        
        Host 1: Well, that's all the time we have today. Thanks for listening!
        
        Host 2: Don't forget to like and subscribe for more content!
        """
    }
    
    private func generateSummary(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let summary = words.prefix(300).joined(separator: " ")
        
        return """
        Summary:
        
        This content covers important topics including: \(summary)
        
        Key Takeaways:
        - The main ideas are presented clearly
        - Important concepts are explained in depth
        - Practical applications are discussed
        """
    }
    
    private func generateLecture(from text: String) -> String {
        return """
        Welcome to today's lecture.
        
        Let's begin by discussing the main topic. This content provides valuable insights.
        
        First, let's understand the fundamental principles...
        
        Now, let's dive deeper into each point...
        
        In conclusion, these concepts have practical applications.
        
        Thank you for your attention.
        """
    }
    
    private func generateStoryNarration(from text: String) -> String {
        return """
        Once upon a time, in the world of knowledge and discovery...
        
        Let me share with you this fascinating journey through ideas...
        
        It all begins with understanding the core concepts...
        
        As we explore further, we discover amazing truths...
        
        The end... for now.
        """
    }
    
    // Fallback mock generation
    private func generateMockAudio(from text: String, mode: ListeningMode, voice: VoiceOption) async throws -> GeneratedAudio {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        let audioURL = generateMockAudioURL(mode: mode)
        
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        let baseWPM = 150
        let modeMultiplier: Double
        
        switch mode {
        case .narration: modeMultiplier = 1.0
        case .podcast: modeMultiplier = 1.3
        case .summary: modeMultiplier = 0.2
        case .lecture: modeMultiplier = 0.9
        case .story: modeMultiplier = 1.1
        }
        
        let duration = Int((Double(wordCount) / Double(baseWPM)) * 60 * modeMultiplier)
        
        return GeneratedAudio(
            audioURL: audioURL,
            duration: max(duration, 60),
            transcript: text
        )
    }
    
    private func generateMockAudioURL(mode: ListeningMode) -> String {
        let sampleURLs = [
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
            "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"
        ]
        
        let index = abs(mode.rawValue.hashValue) % sampleURLs.count
        return sampleURLs[index]
    }
}

// MARK: - Generated Audio
struct GeneratedAudio {
    let audioURL: String
    let duration: Int
    let transcript: String
    var useAppleSpeech: Bool = false
}

// MARK: - Document Error
enum DocumentError: LocalizedError {
    case accessDenied
    case invalidPDF
    case emptyPDF
    case invalidEPUB
    case emptyEPUB
    case invalidTXT
    case unsupportedFormat
    case generationFailed
    case ocrFailed
    case webScrapingFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the selected file"
        case .invalidPDF:
            return "The file is not a valid PDF"
        case .emptyPDF:
            return "The PDF appears to be empty"
        case .invalidEPUB:
            return "The file is not a valid EPUB"
        case .emptyEPUB:
            return "The EPUB appears to be empty"
        case .invalidTXT:
            return "Unable to read the text file"
        case .unsupportedFormat:
            return "Unsupported file format. Please use PDF, EPUB, or TXT."
        case .generationFailed:
            return "Failed to generate audio"
        case .ocrFailed:
            return "Failed to extract text from image"
        case .webScrapingFailed:
            return "Failed to extract content from URL"
        }
    }
}

// MARK: - Storage Service
class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let userId = "user_id"
        static let lastPlayedAudioId = "last_played_audio_id"
        static let playbackSpeed = "playback_speed"
        static let onboardingCompleted = "onboarding_completed"
        static let documents = "saved_documents"
        static let audioContents = "saved_audio_contents"
    }
    
    private init() {}
    
    var userId: String? {
        get { defaults.string(forKey: Keys.userId) }
        set { defaults.set(newValue, forKey: Keys.userId) }
    }
    
    var lastPlayedAudioId: String? {
        get { defaults.string(forKey: Keys.lastPlayedAudioId) }
        set { defaults.set(newValue, forKey: Keys.lastPlayedAudioId) }
    }
    
    var playbackSpeed: Double {
        get { defaults.double(forKey: Keys.playbackSpeed) == 0 ? 1.0 : defaults.double(forKey: Keys.playbackSpeed) }
        set { defaults.set(newValue, forKey: Keys.playbackSpeed) }
    }
    
    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }
    
    func saveDocuments(_ documents: [Document]) {
        if let encoded = try? JSONEncoder().encode(documents) {
            defaults.set(encoded, forKey: Keys.documents)
        }
    }
    
    func loadDocuments() -> [Document] {
        guard let data = defaults.data(forKey: Keys.documents),
              let documents = try? JSONDecoder().decode([Document].self, from: data) else {
            return []
        }
        return documents
    }
    
    func saveAudioContents(_ contents: [AudioContent]) {
        if let encoded = try? JSONEncoder().encode(contents) {
            defaults.set(encoded, forKey: Keys.audioContents)
        }
    }
    
    func loadAudioContents() -> [AudioContent] {
        guard let data = defaults.data(forKey: Keys.audioContents),
              let contents = try? JSONDecoder().decode([AudioContent].self, from: data) else {
            return []
        }
        return contents
    }
    
    func clearAll() {
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.lastPlayedAudioId)
        defaults.removeObject(forKey: Keys.playbackSpeed)
        defaults.removeObject(forKey: Keys.onboardingCompleted)
        defaults.removeObject(forKey: Keys.documents)
        defaults.removeObject(forKey: Keys.audioContents)
    }
}
