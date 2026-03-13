import SwiftUI

struct AudioPlayerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var audioService: AudioService { appState.audioService }
    let audio: AudioContent
    
    
    @State private var showSpeedPicker: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Cover Art
                            coverArtView
                                .padding(.top, 20)
                            
                            // Title & Info
                            titleSection
                            
                            // Progress
                            progressSection
                            
                            // Controls
                            controlsSection
                            
                            // Speed Control
                            speedSection
                            
                            // Actions
                            actionsSection
                                .padding(.top, 20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .onChange(of: audioService.isPlaying) { isPlaying in
            appState.isPlaying = isPlaying
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color.gradientStart,
                    Color.gradientMid,
                    Color.gradientEnd.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blurred Circle Accents
            Circle()
                .fill(Color.brandPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -100, y: -100)
            
            Circle()
                .fill(Color.brandSecondary.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: 200)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Now Playing")
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
                
                Text(audio.mode.displayName)
                    .font(.labelMedium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Menu {
                Button(action: {}) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(action: {}) {
                    Label("Add to playlist", systemImage: "plus")
                }
                Button(action: {}) {
                    Label("Report issue", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Cover Art View
    private var coverArtView: some View {
        AsyncImage(url: URL(string: audio.coverImageURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                LinearGradient(
                    colors: [Color.gradientMid, Color.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Image(systemName: "waveform")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .frame(width: 300, height: 300)
        .cornerRadius(32)
        .softShadow(radius: 40, x: 0, y: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(audio.title)
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                Label(audio.mode.displayName, systemImage: audio.mode.icon)
                    .font(.labelMedium)
                
                Label(audio.voice.displayName, systemImage: audio.voice.icon)
                    .font(.labelMedium)
            }
            .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Waveform
            WaveformView(isPlaying: audioService.isPlaying)
                .frame(height: 50)
            
            // Slider
            Slider(
                value: Binding(
                    get: { audioService.currentTime },
                    set: { audioService.seek(to: $0) }
                ),
                in: 0...max(audioService.duration, 1)
            )
            .tint(.brandPrimary)
            
            // Time Labels
            HStack {
                Text(audioService.formattedCurrentTime)
                    .font(.labelMedium)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(audioService.formattedRemainingTime)
                    .font(.labelMedium)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
            }
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Skip Backward
            Button(action: { audioService.skipBackward() }) {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
            
            // Play/Pause
            Button(action: { audioService.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 80, height: 80)
                        .floatingShadow()
                    
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Skip Forward
            Button(action: { audioService.skipForward() }) {
                Image(systemName: "goforward.15")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
        }
    }
    
    // MARK: - Speed Section
    private var speedSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSpeedPicker.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 14))
                    Text(String(format: "%.1fx", audioService.playbackRate))
                        .font(.labelLarge)
                        .kerning(0.5)
                }
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }
            
            if showSpeedPicker {
                PlaybackSpeedPicker(speed: Binding(
                    get: { Double(audioService.playbackRate) },
                    set: { audioService.setPlaybackRate(Float($0)) }
                ))
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        HStack(spacing: 48) {
            ActionButton(icon: "bookmark", title: "Save") {}
            ActionButton(icon: "text.alignleft", title: "Transcript") {}
            ActionButton(icon: "square.and.arrow.up", title: "Share") {}
            ActionButton(icon: "list.bullet", title: "Chapters") {}
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
                
                Text(title)
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let isPlaying: Bool
    @State private var animatedBars: [CGFloat] = Array(repeating: 0.3, count: 50)
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<50, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary.opacity(0.6), .brandPrimary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: animatedBars[index] * 50)
                    .animation(
                        isPlaying ?
                            Animation.easeInOut(duration: Double.random(in: 0.3...0.7))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.015) :
                            .easeInOut(duration: 0.3),
                        value: isPlaying
                    )
            }
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        animatedBars = (0..<50).map { _ in CGFloat.random(in: 0.3...1.0) }
    }
}

#Preview {
    AudioPlayerView(audio: AudioContent(
        id: "1",
        documentId: "1",
        title: "The Art of Thinking Clearly",
        mode: .podcast,
        voice: .podcastHost,
        audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        duration: 3600,
        coverImageURL: "https://picsum.photos/seed/book1/300/400",
        createdAt: Date()
    ))
    .environmentObject(AppState())
}
