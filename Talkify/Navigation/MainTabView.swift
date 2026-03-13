import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home
    @State private var showPlayer: Bool = false
    
    enum Tab {
        case home
        case library
        case upload
        case discover
        case profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                LibraryView()
                    .tag(Tab.library)
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }
                
                UploadView()
                    .tag(Tab.upload)
                    .tabItem {
                        Label("Upload", systemImage: "plus.circle.fill")
                    }
                
                DiscoverView()
                    .tag(Tab.discover)
                    .tabItem {
                        Label("Discover", systemImage: "sparkles")
                    }
                
                ProfileView()
                    .tag(Tab.profile)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .tint(.brandPrimary)
            
            // Mini Player
            if appState.showPlayer, let audio = appState.currentPlayingAudio {
                VStack(spacing: 0) {
                    MiniPlayerView(audio: audio)
                        .onTapGesture {
                            showPlayer = true
                        }
                    
                    Spacer()
                        .frame(height: 49)
                }
            }
        }
        .sheet(isPresented: $showPlayer) {
            if let audio = appState.currentPlayingAudio {
                AudioPlayerView(audio: audio)
            }
        }
    }
}

// MARK: - Mini Player View
struct MiniPlayerView: View {
    @EnvironmentObject var appState: AppState
    let audio: AudioContent
    
    var body: some View {
        HStack(spacing: 14) {
            // Cover Image
            AsyncImage(url: URL(string: audio.coverImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gradientMid)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 16))
                            .foregroundColor(.brandPrimary.opacity(0.5))
                    )
            }
            .frame(width: 52, height: 52)
            .cornerRadius(12)
            .clipped()
            .softShadow(radius: 5, x: 0, y: 2)
            
            // Title & Mode
            VStack(alignment: .leading, spacing: 3) {
                Text(audio.title)
                    .font(.labelLarge)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(audio.mode.displayName)
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Play/Pause Button
            Button(action: {
                appState.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .softShadow(radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .floatingShadow()
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
