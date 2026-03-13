import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ContentCategory = .trending
    @State private var searchText: String = ""
    
    // Mock discover content
    private let discoverContent: [DiscoverContent] = [
        DiscoverContent(id: "1", title: "Atomic Habits", author: "James Clear", category: .books, coverImageURL: "https://picsum.photos/seed/disc1/300/400", duration: 9000, isTrending: true, isNew: false),
        DiscoverContent(id: "2", title: "The Psychology of Money", author: "Morgan Housel", category: .books, coverImageURL: "https://picsum.photos/seed/disc2/300/400", duration: 7200, isTrending: true, isNew: false),
        DiscoverContent(id: "3", title: "Deep Work", author: "Cal Newport", category: .books, coverImageURL: "https://picsum.photos/seed/disc3/300/400", duration: 10800, isTrending: false, isNew: true),
        DiscoverContent(id: "4", title: "AI Revolution", author: "Tech Weekly", category: .articles, coverImageURL: "https://picsum.photos/seed/disc4/300/400", duration: 1800, isTrending: true, isNew: false),
        DiscoverContent(id: "5", title: "Climate Change 101", author: "Science Daily", category: .educational, coverImageURL: "https://picsum.photos/seed/disc5/300/400", duration: 3600, isTrending: false, isNew: true),
        DiscoverContent(id: "6", title: "Start With Why", author: "Simon Sinek", category: .books, coverImageURL: "https://picsum.photos/seed/disc6/300/400", duration: 8400, isTrending: false, isNew: false)
    ]
    
    var filteredContent: [DiscoverContent] {
        var content = discoverContent
        
        if !searchText.isEmpty {
            content = content.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        if selectedCategory != .trending {
            content = content.filter { $0.category == selectedCategory }
        }
        
        return content
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                // Category Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ContentCategory.allCases, id: \.self) { category in
                            CategoryTab(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Content Grid
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        // Featured Section (if trending)
                        if selectedCategory == .trending && searchText.isEmpty {
                            FeaturedSection()
                        }
                        
                        // Content Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredContent) { item in
                                DiscoverContentCard(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: ContentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.appSubheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .appPrimaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.appPrimary : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Featured Section
struct FeaturedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured")
                .font(.appTitle3)
                .foregroundColor(.appPrimaryText)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    FeaturedCard(
                        title: "The Future of AI",
                        subtitle: "Technology",
                        duration: "2h 15m",
                        coverURL: "https://picsum.photos/seed/featured1/600/300"
                    ) {}
                    
                    FeaturedCard(
                        title: "Mindful Leadership",
                        subtitle: "Business",
                        duration: "1h 45m",
                        coverURL: "https://picsum.photos/seed/featured2/600/300"
                    ) {}
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let duration: String
    let coverURL: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: coverURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.appGradientStart)
                }
                .frame(width: 280, height: 160)
                .cornerRadius(16)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimaryText)
                    
                    HStack {
                        Text(subtitle)
                            .font(.appCaption1)
                            .foregroundColor(.appSecondaryText)
                        
                        Text("•")
                            .font(.appCaption1)
                            .foregroundColor(.appSecondaryText)
                        
                        Text(duration)
                            .font(.appCaption1)
                            .foregroundColor(.appSecondaryText)
                    }
                }
                .padding(.top, 12)
            }
            .frame(width: 280)
        }
    }
}

// MARK: - Discover Content Card
struct DiscoverContentCard: View {
    let item: DiscoverContent
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            // Create audio content and play
            let audio = AudioContent(
                id: item.id,
                documentId: item.id,
                title: item.title,
                mode: .narration,
                voice: .calmNarrator,
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                duration: item.duration,
                coverImageURL: item.coverImageURL,
                createdAt: Date()
            )
            appState.playAudio(audio)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: item.coverImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.appGradientStart)
                    }
                    .frame(height: 180)
                    .cornerRadius(12)
                    .clipped()
                    
                    // Badges
                    HStack(spacing: 4) {
                        if item.isNew {
                            BadgeView(text: "New", color: .appSuccess)
                        }
                        if item.isTrending {
                            BadgeView(text: "Hot", color: .appPrimary)
                        }
                    }
                    .padding(8)
                }
                
                Text(item.title)
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appPrimaryText)
                    .lineLimit(2)
                
                Text(item.author)
                    .font(.appCaption1)
                    .foregroundColor(.appSecondaryText)
                
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 10))
                    Text(item.category.displayName)
                        .font(.appCaption2)
                }
                .foregroundColor(.appTertiaryText)
            }
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AppState())
}
