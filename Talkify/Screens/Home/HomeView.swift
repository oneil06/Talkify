import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Greeting
                    GreetingSection()
                    
                    // Continue Listening
                    if !appState.audioContents.isEmpty {
                        ContinueListeningSection(audios: appState.audioContents)
                    }
                    
                    // Recent Uploads
                    RecentUploadsSection()
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Recommended
                    RecommendedSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(Color.appBackgroundPrimary)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Greeting Section
struct GreetingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.headlineMedium)
                .foregroundColor(.textSecondary)
            
            Text("Your listening space")
                .font(.displaySmall)
                .foregroundColor(.textPrimary)
        }
        .padding(.top, 16)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Continue Listening Section
struct ContinueListeningSection: View {
    let audios: [AudioContent]
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Continue Listening")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(audios.prefix(3)) { audio in
                        ContinueListeningCard(
                            audio: audio,
                            progress: audio.currentPosition,
                            onTap: {
                                appState.playAudio(audio)
                            }
                        )
                        .frame(width: 320)
                    }
                }
            }
        }
    }
}

// MARK: - Recent Uploads Section
struct RecentUploadsSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Recent Uploads", actionTitle: "See All", action: {})
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(appState.audioContents) { audio in
                        AudioContentCard(audio: audio, onTap: {
                            appState.playAudio(audio)
                        })
                        .frame(width: 180)
                    }
                }
            }
        }
    }
}

// MARK: - Recommended Section
struct RecommendedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Recommended for You")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    RecommendedCard(
                        title: "The Psychology of Money",
                        author: "Morgan Housel",
                        duration: "5h 30m",
                        coverURL: "https://picsum.photos/seed/rec1/300/400"
                    ) {}
                    
                    RecommendedCard(
                        title: "Atomic Habits",
                        author: "James Clear",
                        duration: "4h 15m",
                        coverURL: "https://picsum.photos/seed/rec2/300/400"
                    ) {}
                    
                    RecommendedCard(
                        title: "Deep Work",
                        author: "Cal Newport",
                        duration: "6h 45m",
                        coverURL: "https://picsum.photos/seed/rec3/300/400"
                    ) {}
                }
            }
        }
    }
}

struct RecommendedCard: View {
    let title: String
    let author: String
    let duration: String
    let coverURL: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                AsyncImage(url: URL(string: coverURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gradientMid, Color.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 130, height: 195)
                .cornerRadius(16)
                .clipped()
                .softShadow(radius: 10, x: 0, y: 5)
                
                Text(title)
                    .font(.labelLarge)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .frame(width: 130, alignment: .leading)
                
                Text(author)
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                
                Text(duration)
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Quick Actions")
            
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "doc.badge.plus",
                    title: "Upload PDF",
                    color: .brandPrimary
                ) {}
                
                QuickActionButton(
                    icon: "camera.viewfinder",
                    title: "Scan Book",
                    color: .brandSecondary
                ) {}
                
                QuickActionButton(
                    icon: "link",
                    title: "Paste Link",
                    color: .accentTeal
                ) {}
                
                QuickActionButton(
                    icon: "photo.on.rectangle.angled",
                    title: "Images",
                    color: .accentPink
                ) {}
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                .softShadow(radius: 8, x: 0, y: 4)
                
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
