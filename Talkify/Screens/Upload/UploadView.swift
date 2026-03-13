import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PDFKit
import UIKit

struct UploadView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: ListeningMode = .narration
    @State private var selectedVoice: VoiceOption = .calmNarrator
    @State private var isProcessing: Bool = false
    @State private var processingProgress: Double = 0
    @State private var showLinkInput: Bool = false
    @State private var linkURL: String = ""
    @State private var showDocumentPicker: Bool = false
    @State private var selectedDocumentURL: URL?
    @State private var showImagePicker: Bool = false
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var processingStatus: String = ""
    @State private var currentUploadType: UploadType = .pdf
    
    enum UploadType {
        case pdf
        case epub
        case txt
        case image
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Upload Content")
                            .font(.headlineMedium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Transform documents into engaging audio")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    
                    // Upload Options
                    VStack(spacing: 14) {
                        UploadOptionCard(
                            title: "Upload PDF",
                            subtitle: "Convert PDF documents to audio",
                            icon: "doc.fill",
                            iconColor: .brandPrimary,
                            action: {
                                currentUploadType = .pdf
                                showDocumentPicker = true
                            }
                        )
                        
                        UploadOptionCard(
                            title: "Upload EPUB",
                            subtitle: "Convert EPUB books to audio",
                            icon: "book.fill",
                            iconColor: .brandSecondary,
                            action: {
                                currentUploadType = .epub
                                showDocumentPicker = true
                            }
                        )
                        
                        UploadOptionCard(
                            title: "Upload TXT",
                            subtitle: "Convert text files to audio",
                            icon: "doc.text.fill",
                            iconColor: .accentTeal,
                            action: {
                                currentUploadType = .txt
                                showDocumentPicker = true
                            }
                        )
                        
                        UploadOptionCard(
                            title: "Scan Book",
                            subtitle: "Use camera to scan pages",
                            icon: "camera.viewfinder",
                            iconColor: .brandSecondary,
                            action: {
                                currentUploadType = .image
                                showImagePicker = true
                            }
                        )
                        
                        UploadOptionCard(
                            title: "Paste Article Link",
                            subtitle: "Convert web articles to audio",
                            icon: "link",
                            iconColor: .accentTeal,
                            action: {
                                showLinkInput = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Listening Mode Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Listening Mode")
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ListeningMode.allCases) { mode in
                                    ListeningModeCard(
                                        mode: mode,
                                        isSelected: selectedMode == mode,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedMode = mode
                                            }
                                        }
                                    )
                                    .frame(width: 140)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Voice Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Voice")
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(VoiceOption.allCases.prefix(4)) { voice in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.brandPrimary.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "waveform")
                                                    .foregroundColor(.brandPrimary)
                                            )
                                        
                                        Text(voice.displayName)
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedVoice = voice
                                        }
                                    }
                                    .opacity(selectedVoice == voice ? 1.0 : 0.6)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Convert Button
                    if selectedDocumentURL != nil {
                        PrimaryButton("Generate Audio", icon: "waveform.badge.plus", isLoading: isProcessing) {
                            Task {
                                await processAndGenerateAudio()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    
                    // Processing View
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressView(value: processingProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
                            
                            Text(processingStatus)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.appBackgroundPrimary)
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: getAllowedContentTypes(),
                allowsMultipleSelection: false
            ) { result in
                handleDocumentSelection(result)
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedImages,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedImages) { newValue in
                if !newValue.isEmpty {
                    Task {
                        await processImages(newValue)
                    }
                }
            }
            .alert("Paste Article Link", isPresented: $showLinkInput) {
                TextField("Enter URL", text: $linkURL)
                Button("Cancel", role: .cancel) { }
                Button("Convert") {
                    Task {
                        await processWebURL(linkURL)
                    }
                }
            } message: {
                Text("Paste the URL of the article you want to convert")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func getAllowedContentTypes() -> [UTType] {
        switch currentUploadType {
        case .pdf:
            return [UTType.pdf]
        case .epub:
            return [UTType(filenameExtension: "epub") ?? .data]
        case .txt:
            return [UTType.plainText, UTType(filenameExtension: "txt") ?? .plainText]
        case .image:
            return [UTType.image]
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedDocumentURL = url
            }
        case .failure(let error):
            showErrorAlert("Error", error.localizedDescription)
        }
    }
    
    private func showErrorAlert(_ title: String, _ message: String) {
        errorMessage = message
        showError = true
    }
    
    // Process selected images using OCR
    private func processImages(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        processingProgress = 0.1
        processingStatus = "Loading images..."
        
        do {
            var extractedTexts: [String] = []
            let total = Double(items.count)
            
            for (index, item) in items.enumerated() {
                processingProgress = 0.1 + (Double(index) / total) * 0.4
                processingStatus = "Processing image \(index + 1) of \(items.count)..."
                
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let text = try await OCRService.shared.extractText(from: image)
                    extractedTexts.append(text)
                }
            }
            
            let combinedText = extractedTexts.joined(separator: "\n\n")
            
            if combinedText.isEmpty {
                showErrorAlert("OCR Failed", "Could not extract text from the images.")
                isProcessing = false
                return
            }
            
            processingProgress = 0.6
            processingStatus = "Generating audio..."
            
            let generatedAudio = try await AIGenerationService.shared.generateAudio(
                from: combinedText,
                mode: selectedMode,
                voice: selectedVoice
            )
            
            processingProgress = 0.9
            processingStatus = "Finalizing..."
            
            let title = "Scanned Document \(Date().formatted(date: .abbreviated, time: .shortened))"
            
            let newDocument = Document(
                id: UUID().uuidString,
                userId: appState.currentUser?.id ?? "user_001",
                title: title,
                fileURL: "",
                textContent: combinedText,
                coverImageURL: DocumentService.shared.generateCoverImage(for: title),
                chapters: DocumentService.shared.generateChapters(from: combinedText),
                createdAt: Date()
            )
            
            let newAudioContent = AudioContent(
                id: UUID().uuidString,
                documentId: newDocument.id,
                title: title,
                mode: selectedMode,
                voice: selectedVoice,
                audioURL: generatedAudio.audioURL,
                duration: generatedAudio.duration,
                coverImageURL: newDocument.coverImageURL ?? "",
                currentPosition: 0,
                createdAt: Date()
            )
            
            await MainActor.run {
                appState.documents.append(newDocument)
                appState.audioContents.insert(newAudioContent, at: 0)
                StorageService.shared.saveDocuments(appState.documents)
                StorageService.shared.saveAudioContents(appState.audioContents)
                processingProgress = 1.0
                processingStatus = "Done!"
                appState.playAudio(newAudioContent)
                isProcessing = false
                selectedImages = []
            }
            
        } catch {
            await MainActor.run {
                showErrorAlert("Processing Failed", error.localizedDescription)
                isProcessing = false
            }
        }
    }
    
    // Process web URL
    private func processWebURL(_ urlString: String) async {
        guard !urlString.isEmpty else {
            showErrorAlert("Error", "Please enter a valid URL")
            return
        }
        
        isProcessing = true
        processingProgress = 0.1
        processingStatus = "Fetching article..."
        
        do {
            let extractedContent = try await WebScraperService.shared.extractContent(from: urlString)
            
            // Parse title from extracted content
            var title = "Web Article"
            var content = extractedContent
            
            if extractedContent.hasPrefix("TITLE:") {
                let components = extractedContent.components(separatedBy: "\n\nCONTENT:")
                if components.count >= 2 {
                    title = components[0].replacingOccurrences(of: "TITLE: ", with: "")
                    content = components[1]
                }
            }
            
            processingProgress = 0.5
            processingStatus = "Generating audio..."
            
            let generatedAudio = try await AIGenerationService.shared.generateAudio(
                from: content,
                mode: selectedMode,
                voice: selectedVoice
            )
            
            processingProgress = 0.9
            processingStatus = "Finalizing..."
            
            let newDocument = Document(
                id: UUID().uuidString,
                userId: appState.currentUser?.id ?? "user_001",
                title: title,
                fileURL: urlString,
                textContent: content,
                coverImageURL: DocumentService.shared.generateCoverImage(for: title),
                chapters: DocumentService.shared.generateChapters(from: content),
                createdAt: Date()
            )
            
            let newAudioContent = AudioContent(
                id: UUID().uuidString,
                documentId: newDocument.id,
                title: title,
                mode: selectedMode,
                voice: selectedVoice,
                audioURL: generatedAudio.audioURL,
                duration: generatedAudio.duration,
                coverImageURL: newDocument.coverImageURL ?? "",
                currentPosition: 0,
                createdAt: Date()
            )
            
            await MainActor.run {
                appState.documents.append(newDocument)
                appState.audioContents.insert(newAudioContent, at: 0)
                StorageService.shared.saveDocuments(appState.documents)
                StorageService.shared.saveAudioContents(appState.audioContents)
                processingProgress = 1.0
                processingStatus = "Done!"
                appState.playAudio(newAudioContent)
                isProcessing = false
                linkURL = ""
            }
            
        } catch {
            await MainActor.run {
                showErrorAlert("Web Scraping Failed", error.localizedDescription)
                isProcessing = false
            }
        }
    }
    
    private func processAndGenerateAudio() async {
        guard let documentURL = selectedDocumentURL else { return }
        
        isProcessing = true
        processingProgress = 0.1
        processingStatus = "Reading PDF..."
        
        do {
            // Step 1: Extract text from PDF
            let text = try await DocumentService.shared.extractText(from: documentURL)
            processingProgress = 0.4
            processingStatus = "Analyzing content..."
            
            // Get document name
            let documentName = documentURL.deletingPathExtension().lastPathComponent
            
            // Step 2: Generate audio
            processingProgress = 0.6
            processingStatus = "Generating audio..."
            
            let generatedAudio = try await AIGenerationService.shared.generateAudio(
                from: text,
                mode: selectedMode,
                voice: selectedVoice
            )
            
            processingProgress = 0.9
            processingStatus = "Finalizing..."
            
            // Create new document and audio content
            let newDocument = Document(
                id: UUID().uuidString,
                userId: appState.currentUser?.id ?? "user_001",
                title: documentName,
                fileURL: documentURL.absoluteString,
                textContent: text,
                coverImageURL: DocumentService.shared.generateCoverImage(for: documentName),
                chapters: DocumentService.shared.generateChapters(from: text),
                createdAt: Date()
            )
            
            let newAudioContent = AudioContent(
                id: UUID().uuidString,
                documentId: newDocument.id,
                title: documentName,
                mode: selectedMode,
                voice: selectedVoice,
                audioURL: generatedAudio.audioURL,
                duration: generatedAudio.duration,
                coverImageURL: newDocument.coverImageURL ?? "",
                currentPosition: 0,
                createdAt: Date()
            )
            
            // Add to app state
            await MainActor.run {
                appState.documents.append(newDocument)
                appState.audioContents.insert(newAudioContent, at: 0)
                
                // Save to storage
                StorageService.shared.saveDocuments(appState.documents)
                StorageService.shared.saveAudioContents(appState.audioContents)
                
                processingProgress = 1.0
                processingStatus = "Done!"
                
                // Play the generated audio
                appState.playAudio(newAudioContent)
                
                // Reset state
                isProcessing = false
                selectedDocumentURL = nil
            }
            
        } catch {
            await MainActor.run {
                showErrorAlert("Processing Failed", error.localizedDescription)
                isProcessing = false
                processingProgress = 0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UploadView()
        .environmentObject(AppState())
}
