import SwiftUI

// MARK: - Glass Card with Blur
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .cardShadow()
    }
}

// MARK: - Primary Button (Modern)
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 10) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(title)
                            .font(.labelLarge)
                            .kerning(0.5)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primaryGradient)
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.labelLarge)
                    .kerning(0.5)
            }
            .foregroundColor(.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.brandPrimary.opacity(0.1))
            )
        }
    }
}

// MARK: - Icon Button (Modern Circle)
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void
    
    init(_ icon: String, size: CGFloat = 56, backgroundColor: Color = .white, iconColor: Color = .textPrimary, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .softShadow(radius: 10, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Audio Content Card (Modern)
struct AudioContentCard: View {
    let audio: AudioContent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: audio.coverImageURL)) { image in
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
                            .overlay(
                                Image(systemName: "waveform")
                                    .font(.system(size: 30))
                                    .foregroundColor(.brandPrimary.opacity(0.3))
                            )
                    }
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    
                    // Mode Badge
                    Text(audio.mode.displayName)
                        .font(.labelSmall)
                        .fontWeight(.semibold)
                        .kerning(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary)
                        )
                        .padding(12)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(audio.title)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Label(formatDuration(audio.duration), systemImage: "clock")
                            .font(.labelSmall)
                        
                        Spacer()
                        
                        Label(audio.voice.displayName, systemImage: audio.voice.icon)
                            .font(.labelSmall)
                    }
                    .foregroundColor(.textSecondary)
                }
                .padding(16)
            }
            .background(Color.cardBackground)
            .cornerRadius(20)
            .cardShadow()
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Continue Listening Card
struct ContinueListeningCard: View {
    let audio: AudioContent
    let progress: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
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
                                .font(.system(size: 20))
                                .foregroundColor(.brandPrimary.opacity(0.5))
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(16)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(audio.title)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(audio.mode.displayName)
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.divider)
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.primaryGradient)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                
                Spacer()
                
                // Play Button
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.primaryGradient)
                    )
                    .softShadow(radius: 8, x: 0, y: 4)
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(20)
            .cardShadow()
        }
    }
}

// MARK: - Upload Option Card
struct UploadOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.15), iconColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(20)
            .cardShadow()
        }
    }
}

// MARK: - Listening Mode Card
struct ListeningModeCard: View {
    let mode: ListeningMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            Color.primaryGradient :
                            LinearGradient(colors: [Color.divider], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : .textSecondary)
                }
                .softShadow(radius: isSelected ? 15 : 5, x: 0, y: isSelected ? 8 : 3)
                
                Text(mode.displayName)
                    .font(.titleSmall)
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                
                Text(mode.description)
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? Color.cardBackground : Color.appBackgroundPrimary)
                    .softShadow(radius: isSelected ? 15 : 5, x: 0, y: isSelected ? 8 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.labelLarge)
                        .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.brandPrimary.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headlineSmall)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.divider, lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
            }
            
            Text(message)
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Playback Speed Picker
struct PlaybackSpeedPicker: View {
    @Binding var speed: Double
    
    let speeds: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(speeds, id: \.self) { speedOption in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        speed = speedOption
                    }
                }) {
                    Text(formatSpeed(speedOption))
                        .font(.labelMedium)
                        .fontWeight(speed == speedOption ? .semibold : .regular)
                        .foregroundColor(speed == speedOption ? .white : .textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(speed == speedOption ? Color.brandPrimary : Color.divider)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.appBackgroundSecondary)
        )
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed == 1.0 {
            return "1x"
        }
        return String(format: "%.2gx", speed)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
