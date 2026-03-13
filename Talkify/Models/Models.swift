import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let email: String
    var displayName: String
    var isAppleSignIn: Bool
    var subscriptionPlan: SubscriptionPlan
    let createdAt: Date
    
    init(id: String, email: String, displayName: String? = nil, isAppleSignIn: Bool = false, subscriptionPlan: SubscriptionPlan = .free, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName ?? email.components(separatedBy: "@").first ?? "User"
        self.isAppleSignIn = isAppleSignIn
        self.subscriptionPlan = subscriptionPlan
        self.createdAt = createdAt
    }
}

enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    var monthlyListeningHours: Int {
        switch self {
        case .free: return 1
        case .pro: return -1 // Unlimited
        case .premium: return -1 // Unlimited
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "1 hour listening per month",
                "Basic voices",
                "Narration mode only"
            ]
        case .pro:
            return [
                "Unlimited listening",
                "All voices",
                "Podcast & Lecture modes",
                "AI explanations"
            ]
        case .premium:
            return [
                "Everything in Pro",
                "Voice cloning",
                "Offline downloads",
                "Custom podcast voices"
            ]
        }
    }
}

// MARK: - Document Model
struct Document: Identifiable, Codable {
    let id: String
    let userId: String
    var title: String
    let fileURL: String
    var textContent: String
    var coverImageURL: String?
    var chapters: [Chapter]?
    let createdAt: Date
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct Chapter: Identifiable, Codable {
    let id: String
    let title: String
    let startPage: Int
    let endPage: Int
    var sections: [Section]?
}

struct Section: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    var subsections: [Section]?
}

// MARK: - Audio Content Model
struct AudioContent: Identifiable, Codable {
    let id: String
    let documentId: String
    var title: String
    var mode: ListeningMode
    var voice: VoiceOption
    let audioURL: String
    var duration: Int // in seconds
    var coverImageURL: String
    var currentPosition: Double = 0
    let createdAt: Date
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
    
    var remainingTime: Int {
        max(0, Int(Double(duration) * (1 - currentPosition)))
    }
    
    var formattedRemainingTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Listening Mode
enum ListeningMode: String, Codable, CaseIterable, Identifiable {
    case narration = "narration"
    case podcast = "podcast"
    case summary = "summary"
    case lecture = "lecture"
    case story = "story"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .narration: return "Narration"
        case .podcast: return "Podcast"
        case .summary: return "Summary"
        case .lecture: return "Lecture"
        case .story: return "Story"
        }
    }
    
    var description: String {
        switch self {
        case .narration: return "Standard audiobook reading with natural pacing"
        case .podcast: return "Two hosts discussing the content"
        case .summary: return "5-minute explanation of key insights"
        case .lecture: return "Teacher-style explanation for studying"
        case .story: return "Emotional, cinematic storytelling"
        }
    }
    
    var icon: String {
        switch self {
        case .narration: return "book.fill"
        case .podcast: return "person.2.fill"
        case .summary: return "lightbulb.fill"
        case .lecture: return "graduationcap.fill"
        case .story: return "theatermasks.fill"
        }
    }
    
    var isAvailableForFree: Bool {
        self == .narration
    }
}

// MARK: - Voice Option
enum VoiceOption: String, Codable, CaseIterable, Identifiable {
    case calmNarrator = "calm_narrator"
    case documentaryVoice = "documentary_voice"
    case storyteller = "storyteller"
    case podcastHost = "podcast_host"
    case teacherVoice = "teacher_voice"
    case maleVoice1 = "male_voice_1"
    case femaleVoice1 = "female_voice_1"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .calmNarrator: return "Calm Narrator"
        case .documentaryVoice: return "Documentary"
        case .storyteller: return "Storyteller"
        case .podcastHost: return "Podcast Host"
        case .teacherVoice: return "Teacher"
        case .maleVoice1: return "James"
        case .femaleVoice1: return "Sarah"
        }
    }
    
    var icon: String {
        switch self {
        case .calmNarrator: return "waveform"
        case .documentaryVoice: return "mic.fill"
        case .storyteller: return "book.circle.fill"
        case .podcastHost: return "person.wave.2.fill"
        case .teacherVoice: return "graduationcap"
        case .maleVoice1: return "person.fill"
        case .femaleVoice1: return "person.fill"
        }
    }
    
    var gender: String {
        switch self {
        case .maleVoice1: return "Male"
        case .femaleVoice1: return "Female"
        default: return "Neutral"
        }
    }
}

// MARK: - Bookmark Model
struct Bookmark: Identifiable, Codable {
    let id: String
    let userId: String
    let audioId: String
    var timestamp: Double // in seconds
    var note: String?
    let createdAt: Date
    
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Discover Content
struct DiscoverContent: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let category: ContentCategory
    let coverImageURL: String
    let duration: Int
    let isTrending: Bool
    let isNew: Bool
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

enum ContentCategory: String, Codable, CaseIterable {
    case trending = "trending"
    case books = "books"
    case articles = "articles"
    case educational = "educational"
    case newReleases = "new_releases"
    
    var displayName: String {
        switch self {
        case .trending: return "Trending"
        case .books: return "Books"
        case .articles: return "Articles"
        case .educational: return "Educational"
        case .newReleases: return "New Releases"
        }
    }
    
    var icon: String {
        switch self {
        case .trending: return "flame.fill"
        case .books: return "book.fill"
        case .articles: return "doc.text.fill"
        case .educational: return "graduationcap.fill"
        case .newReleases: return "sparkles"
        }
    }
}
