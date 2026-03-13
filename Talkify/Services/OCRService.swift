import Foundation
import Vision
import UIKit

// MARK: - OCR Service
class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    // Extract text from image using Vision framework
    func extractText(from imageURL: URL) async throws -> String {
        guard imageURL.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { imageURL.stopAccessingSecurityScopedResource() }
        
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw DocumentError.ocrFailed
        }
        
        return try await performOCR(on: cgImage)
    }
    
    // Extract text from UIImage
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw DocumentError.ocrFailed
        }
        
        return try await performOCR(on: cgImage)
    }
    
    // Perform OCR using Vision framework
    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DocumentError.ocrFailed)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentError.ocrFailed)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: DocumentError.ocrFailed)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Support multiple languages
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DocumentError.ocrFailed)
            }
        }
    }
    
    // Extract text from multiple images (for scanned books)
    func extractText(from imageURLs: [URL]) async throws -> String {
        var allText: [String] = []
        
        for url in imageURLs {
            let text = try await extractText(from: url)
            allText.append(text)
        }
        
        let combinedText = allText.joined(separator: "\n\n")
        
        if combinedText.isEmpty {
            throw DocumentError.ocrFailed
        }
        
        return combinedText
    }
}

// MARK: - Web Scraping Service
class WebScraperService {
    static let shared = WebScraperService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    // Extract article content from URL
    func extractContent(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw DocumentError.webScrapingFailed
        }
        
        // First try using OpenAI to extract content (works better for any URL)
        if OpenAIConfig.isConfigured {
            return try await extractWithAI(url: url)
        }
        
        // Fallback to basic HTML parsing
        return try await extractBasicHTML(from: url)
    }
    
    // Use AI to extract main content from URL
    private func extractWithAI(url: URL) async throws -> String {
        let prompt = """
        Extract the main article content from the following URL. Return only the main textual content, 
        removing navigation, ads, footers, and other non-essential content. 
        Return the article title as well, formatted as:
        
        TITLE: [article title]
        
        CONTENT:
        [main article text]
        
        URL: \(url.absoluteString)
        """
        
        // Use OpenAI to analyze and extract
        let messages = [
            OpenAIService.ChatMessage(role: "system", content: "You are a web content extractor that specializes in extracting main article content from URLs."),
            OpenAIService.ChatMessage(role: "user", content: prompt)
        ]
        
        let request = OpenAIService.ChatRequest(
            model: OpenAIModels.gpt4o,
            messages: messages,
            temperature: 0.3,
            max_tokens: 4000
        )
        
        return try await sendChatRequest(request)
    }
    
    // Basic HTML parsing fallback
    private func extractBasicHTML(from url: URL) async throws -> String {
        let (data, _) = try await session.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw DocumentError.webScrapingFailed
        }
        
        // Extract title
        let title = extractTitle(from: html) ?? url.host ?? "Web Article"
        
        // Extract main content
        let content = extractMainContent(from: html)
        
        if content.isEmpty {
            throw DocumentError.webScrapingFailed
        }
        
        return "TITLE: \(title)\n\nCONTENT:\n\(content)"
    }
    
    // Extract page title from HTML
    private func extractTitle(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let titleRange = Range(match.range(at: 1), in: html) {
            return String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    // Extract main content from HTML
    private func extractMainContent(from html: String) -> String {
        // Remove script and style tags
        var content = html
        
        let removePatterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<nav[^>]*>[\\s\\S]*?</nav>",
            "<footer[^>]*>[\\s\\S]*?</footer>",
            "<header[^>]*>[\\s\\S]*?</header>"
        ]
        
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                content = regex.stringByReplacingMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content), withTemplate: "")
            }
        }
        
        // Try to find article or main content
        let contentPatterns = [
            "<article[^>]*>([\\s\\S]*?)</article>",
            "<main[^>]*>([\\s\\S]*?)</main>",
            "<div[^>]*class=\"[^\"]*content[^\"]*\"[^>]*>([\\s\\S]*?)</div>",
            "<div[^>]*class=\"[^\"]*article[^\"]*\"[^>]*>([\\s\\S]*?)</div>"
        ]
        
        for pattern in contentPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
               let contentRange = Range(match.range(at: 1), in: content) {
                let articleContent = String(content[contentRange])
                return stripHTMLTags(articleContent)
            }
        }
        
        // Fallback: extract all paragraph text
        return extractParagraphs(from: content)
    }
    
    // Extract paragraph text
    private func extractParagraphs(from html: String) -> String {
        let pattern = "<p[^>]*>([^<]+)</p>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return ""
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        let paragraphs = matches.compactMap { match -> String? in
            guard let textRange = Range(match.range(at: 1), in: html) else { return nil }
            let text = String(html[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        
        return paragraphs.joined(separator: "\n\n")
    }
    
    // Strip HTML tags
    private func stripHTMLTags(_ html: String) -> String {
        var result = html
        
        // Remove all HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        
        // Clean up whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Send chat request
    private func sendChatRequest(_ request: OpenAIService.ChatRequest) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DocumentError.webScrapingFailed
        }
        
        let decoder = JSONDecoder()
        let chatResponse = try decoder.decode(OpenAIService.ChatResponse.self, from: data)
        
        return chatResponse.choices.first?.message.content ?? ""
    }
}
