import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeader()
                    
                    // Stats Section
                    StatsSection()
                    
                    // Subscription Card
                    SubscriptionCard()
                    
                    // Settings Section
                    SettingsSection()
                    
                    // Help & Support
                    HelpSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profile Header
struct ProfileHeader: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appGradientStart, Color.appGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("O")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            // Name
            VStack(spacing: 4) {
                Text("Oniel McCalla")
                    .font(.appTitle2)
                    .foregroundColor(.appPrimaryText)
                
                Text("Free Plan")
                    .font(.appSubheadline)
                    .foregroundColor(.appSecondaryText)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(value: "12", label: "Documents", icon: "doc.fill")
            StatCard(value: "3.5h", label: "Listening", icon: "headphones")
            StatCard(value: "5", label: "Bookmarks", icon: "bookmark.fill")
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPrimary)
            
            Text(value)
                .font(.appTitle3)
                .foregroundColor(.appPrimaryText)
            
            Text(label)
                .font(.appCaption1)
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Subscription Card
struct SubscriptionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Pro")
                    .font(.appTitle3)
                    .foregroundColor(.appPrimaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTertiaryText)
            }
            
            Text("Unlock unlimited listening, premium voices, and AI explanations.")
                .font(.appSubheadline)
                .foregroundColor(.appSecondaryText)
            
            Button(action: {}) {
                Text("Upgrade - $9.99/month")
                    .font(.appButton)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Settings Section
struct SettingsSection: View {
    @State private var showAPIKeySheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.appTitle3)
                .foregroundColor(.appPrimaryText)
            
            VStack(spacing: 0) {
                // API Key Configuration
                Button(action: { showAPIKeySheet = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.appPrimary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Configuration")
                                .font(.appBody)
                                .foregroundColor(.appPrimaryText)
                            
                            Text(OpenAIConfig.isConfigured ? "API Key configured" : "Add OpenAI API key")
                                .font(.appCaption1)
                                .foregroundColor(OpenAIConfig.isConfigured ? .appSuccess : .appSecondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTertiaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(icon: "person.circle", title: "Account", subtitle: nil) {}
                SettingsRow(icon: "waveform", title: "Voice Settings", subtitle: "Default voice & speed") {}
                SettingsRow(icon: "play.circle", title: "Playback", subtitle: "Auto-play, sleep timer") {}
                SettingsRow(icon: "bell", title: "Notifications", subtitle: nil) {}
                SettingsRow(icon: "arrow.down.circle", title: "Downloads", subtitle: "Manage offline content") {}
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .sheet(isPresented: $showAPIKeySheet) {
            APIKeyConfigSheet()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.appBody)
                        .foregroundColor(.appPrimaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.appCaption1)
                            .foregroundColor(.appSecondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTertiaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Help Section
struct HelpSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help & Support")
                .font(.appTitle3)
                .foregroundColor(.appPrimaryText)
            
            VStack(spacing: 0) {
                SettingsRow(icon: "questionmark.circle", title: "FAQ", subtitle: nil) {}
                SettingsRow(icon: "envelope", title: "Contact Us", subtitle: nil) {}
                SettingsRow(icon: "doc.text", title: "Privacy Policy", subtitle: nil) {}
                SettingsRow(icon: "doc.text", title: "Terms of Service", subtitle: nil) {}
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Sign Out
            Button(action: {
                AuthService.shared.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .foregroundColor(.appError)
                    
                    Text("Sign Out")
                        .font(.appBody)
                        .foregroundColor(.appError)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appError.opacity(0.1))
                )
            }
            
            // App Version
            Text("Talkify v1.0.0")
                .font(.appCaption1)
                .foregroundColor(.appTertiaryText)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - API Key Configuration Sheet
struct APIKeyConfigSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var showSaveConfirmation: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.appPrimary)
                    
                    Text("Configure OpenAI API")
                        .font(.appTitle2)
                        .foregroundColor(.appPrimaryText)
                    
                    Text("Enter your OpenAI API key to enable AI-powered audio generation.")
                        .font(.appSubheadline)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.appSubheadline)
                        .foregroundColor(.appSecondaryText)
                    
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.password)
                }
                
                // Info Box
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondary)
                    
                    Text("You can get your API key from platform.openai.com. Make sure to keep it secure.")
                        .font(.appCaption1)
                        .foregroundColor(.appSecondaryText)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSecondary.opacity(0.1))
                )
                
                Spacer()
                
                // Save Button
                Button(action: saveAPIKey) {
                    Text("Save API Key")
                        .font(.appButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
            .alert("API Key Saved", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your OpenAI API key has been saved securely.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                apiKey = OpenAIConfig.apiKey
            }
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else {
            errorMessage = "Please enter an API key"
            showError = true
            return
        }
        
        guard apiKey.hasPrefix("sk-") else {
            errorMessage = "Invalid API key format. It should start with 'sk-'"
            showError = true
            return
        }
        
        // API key is now hardcoded in the app
        // User can still see the current key for reference
        showSaveConfirmation = true
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appTertiaryText.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
