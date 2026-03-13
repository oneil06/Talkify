import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText: String = ""
    
    enum LibraryFilter: String, CaseIterable {
        case all = "All"
        case books = "Books"
        case articles = "Articles"
        case audiobooks = "Audiobooks"
    }
    
    var filteredAudios: [AudioContent] {
        var audios = appState.audioContents
        
        if !searchText.isEmpty {
            audios = audios.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return audios
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(LibraryFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Content
                if filteredAudios.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "books.vertical",
                        title: "No content yet",
                        subtitle: "Upload documents to start listening"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAudios) { audio in
                                LibraryItemRow(audio: audio)
                                    .onTapGesture {
                                        appState.playAudio(audio)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryText)
            
            TextField("Search your library", text: $text)
                .font(.appBody)
                .foregroundColor(.appPrimaryText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appSubheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .appPrimaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
    }
}

// MARK: - Library Item Row
struct LibraryItemRow: View {
    let audio: AudioContent
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover Image
            AsyncImage(url: URL(string: audio.coverImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.appGradientStart)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 20))
                            .foregroundColor(.appPrimary.opacity(0.5))
                    )
            }
            .frame(width: 70, height: 70)
            .cornerRadius(10)
            .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(audio.title)
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appPrimaryText)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(audio.mode.displayName)
                        .font(.appCaption1)
                        .foregroundColor(.appSecondaryText)
                    
                    Text("•")
                        .font(.appCaption1)
                        .foregroundColor(.appSecondaryText)
                    
                    Text(audio.formattedDuration)
                        .font(.appCaption1)
                        .foregroundColor(.appSecondaryText)
                }
                
                // Progress indicator
                if audio.currentPosition > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.appDivider)
                                .frame(height: 2)
                                .cornerRadius(1)
                            
                            Rectangle()
                                .fill(Color.appPrimary)
                                .frame(width: geometry.size.width * audio.currentPosition, height: 2)
                                .cornerRadius(1)
                        }
                    }
                    .frame(height: 2)
                }
            }
            
            Spacer()
            
            // More Button
            Menu {
                Button(action: {}) {
                    Label("Play", systemImage: "play.fill")
                }
                Button(action: {}) {
                    Label("Add to playlist", systemImage: "plus")
                }
                Button(action: {}) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive, action: {}) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appSecondaryText)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppState())
}
