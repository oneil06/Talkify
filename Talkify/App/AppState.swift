import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var currentUser: User?
    @Published var documents: [Document] = []
    @Published var audioContents: [AudioContent] = []
    @Published var currentPlayingAudio: AudioContent?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var playbackSpeed: Double = 1.0
    @Published var showPlayer: Bool = false
    
    // Shared AudioService for playback across the app
    let audioService = AudioService()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
    }
    
    private func loadData() {
        // Load saved data from storage
        let savedDocuments = StorageService.shared.loadDocuments()
        let savedAudioContents = StorageService.shared.loadAudioContents()
        
        // If no saved data, load mock data
        if savedDocuments.isEmpty && savedAudioContents.isEmpty {
            loadMockData()
        } else {
            documents = savedDocuments
            audioContents = savedAudioContents
            loadDefaultUser()
        }
    }
    
    private func loadDefaultUser() {
        currentUser = User(
            id: "user_001",
            email: "user@talkify.app",
            subscriptionPlan: .pro,
            createdAt: Date()
        )
    }
    
    private func loadMockData() {
        // Load mock user
        currentUser = User(
            id: "user_001",
            email: "demo@talkify.app",
            subscriptionPlan: .pro,
            createdAt: Date()
        )
        
        // Load mock documents
        documents = [
            Document(
                id: "doc_001",
                userId: "user_001",
                title: "The Art of Thinking Clearly",
                fileURL: "https://example.com/book.pdf",
                textContent: "Sample text content about thinking clearly...",
                coverImageURL: "https://picsum.photos/seed/book1/300/400",
                createdAt: Date().addingTimeInterval(-86400)
            ),
            Document(
                id: "doc_002",
                userId: "user_001",
                title: "Atomic Habits",
                fileURL: "https://example.com/atomic.pdf",
                textContent: "Sample text about building good habits...",
                coverImageURL: "https://picsum.photos/seed/book2/300/400",
                createdAt: Date().addingTimeInterval(-172800)
            ),
            Document(
                id: "doc_003",
                userId: "user_001",
                title: "Deep Work",
                fileURL: "https://example.com/deepwork.pdf",
                textContent: "Sample text about focused work...",
                coverImageURL: "https://picsum.photos/seed/book3/300/400",
                createdAt: Date().addingTimeInterval(-259200)
            )
        ]
        
        // Load mock audio content with working audio URLs
        audioContents = [
            AudioContent(
                id: "audio_001",
                documentId: "doc_001",
                title: "The Art of Thinking Clearly",
                mode: .narration,
                voice: .calmNarrator,
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                duration: 3600,
                coverImageURL: "https://picsum.photos/seed/book1/300/400",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            AudioContent(
                id: "audio_002",
                documentId: "doc_002",
                title: "Atomic Habits - Podcast Summary",
                mode: .podcast,
                voice: .podcastHost,
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
                duration: 1800,
                coverImageURL: "https://picsum.photos/seed/book2/300/400",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            AudioContent(
                id: "audio_003",
                documentId: "doc_003",
                title: "Deep Work - Lecture Mode",
                mode: .lecture,
                voice: .documentaryVoice,
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
                duration: 2400,
                coverImageURL: "https://picsum.photos/seed/book3/300/400",
                createdAt: Date().addingTimeInterval(-10800)
            )
        ]
        
        // Save mock data
        StorageService.shared.saveDocuments(documents)
        StorageService.shared.saveAudioContents(audioContents)
    }
    
    func playAudio(_ audio: AudioContent) {
        currentPlayingAudio = audio
        isPlaying = true
        showPlayer = true
        
        // Load and play audio using shared service
        Task {
            await audioService.loadAudio(from: audio.audioURL)
            audioService.play()
        }
        
        // Save last played
        StorageService.shared.lastPlayedAudioId = audio.id
    }
    
    func togglePlayPause() {
        if isPlaying {
            audioService.pause()
        } else {
            audioService.play()
        }
        isPlaying = audioService.isPlaying
    }
    
    func stopPlayback() {
        audioService.stop()
        isPlaying = false
        currentPlayingAudio = nil
        showPlayer = false
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = speed
        audioService.setPlaybackRate(Float(speed))
        StorageService.shared.playbackSpeed = speed
    }
    
    func updateAudioPosition(_ audioId: String, position: Double) {
        if let index = audioContents.firstIndex(where: { $0.id == audioId }) {
            audioContents[index].currentPosition = position
            StorageService.shared.saveAudioContents(audioContents)
        }
    }
}
