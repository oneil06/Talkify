import Foundation

// MARK: - OpenAI API Configuration
struct OpenAIConfig {
    // API key - Add your own from https://platform.openai.com/api-keys
    // Or leave empty to use free Apple Intelligence instead
    private static let hardcodedAPIKey = ""
    
    static var apiKey: String {
        // Return hardcoded key if available, otherwise check UserDefaults
        return hardcodedAPIKey.isEmpty ? (UserDefaults.standard.string(forKey: "openai_api_key") ?? "") : hardcodedAPIKey
    }
    
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

// MARK: - OpenAI Models
struct OpenAIModels {
    // Text-to-Speech models
    static let tts1 = "tts-1"
    static let tts1HD = "tts-1-hd"
    
    // Chat models
    static let gpt4o = "gpt-4o"
    static let gpt4Turbo = "gpt-4-turbo"
    static let gpt35Turbo = "gpt-3.5-turbo"
    
    // Voices available
    static let voices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
}

// MARK: - OpenAI TTS Request
struct OpenAITTSRequest: Codable {
    let model: String
    let voice: String
    let input: String
    let response_format: String
    let speed: Double
}

// MARK: - OpenAI API Error
enum OpenAIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI API key not configured. Please add your API key in Profile > Settings."
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "OpenAI error: \(message)"
        }
    }
}

// MARK: - OpenAI Service
class OpenAIService {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }
    
    // Generate speech from text using OpenAI TTS
    func generateSpeech(
        text: String,
        voice: String = "alloy",
        model: String = OpenAIModels.tts1,
        speed: Double = 1.0
    ) async throws -> Data {
        guard OpenAIConfig.isConfigured else {
            throw OpenAIError.notConfigured
        }
        
        // For very long texts, we need to chunk them
        // OpenAI TTS has a limit of ~4096 characters
        let maxChars = 4000
        let chunks = text.chunked(into: maxChars)
        
        var audioDataArray: [Data] = []
        
        for chunk in chunks {
            let data = try await generateSpeechChunk(
                text: chunk,
                voice: voice,
                model: model,
                speed: speed
            )
            audioDataArray.append(data)
        }
        
        // If multiple chunks, we'd need to concatenate audio
        // For simplicity, return first chunk or combined data
        if audioDataArray.count == 1 {
            return audioDataArray[0]
        } else {
            // Return first chunk for now (full implementation would concatenate)
            return audioDataArray[0]
        }
    }
    
    private func generateSpeechChunk(
        text: String,
        voice: String,
        model: String,
        speed: Double
    ) async throws -> Data {
        let url = URL(string: "\(baseURL)/audio/speech")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let ttsRequest = OpenAITTSRequest(
            model: model,
            voice: voice,
            input: text,
            response_format: "mp3",
            speed: speed
        )
        
        request.httpBody = try JSONEncoder().encode(ttsRequest)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return data
            } else {
                // Try to parse error message
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorDict["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                }
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
    
    // Convert voice option to OpenAI voice
    func mapVoiceOption(_ voice: VoiceOption) -> String {
        switch voice {
        case .calmNarrator:
            return "onyx"
        case .documentaryVoice:
            return "echo"
        case .storyteller:
            return "fable"
        case .podcastHost:
            return "nova"
        case .maleVoice1:
            return "alloy"
        case .femaleVoice1:
            return "shimmer"
        case .teacherVoice:
            return "onyx"
        }
    }
    
    // MARK: - GPT Chat Completion for Script Generation
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
        }
    }
    
    /// Generate an intelligent script for the given mode using GPT
    func generateScript(from text: String, mode: ListeningMode) async throws -> String {
        guard OpenAIConfig.isConfigured else {
            throw OpenAIError.notConfigured
        }
        
        let prompt = buildScriptPrompt(for: mode, text: text)
        
        let messages = [
            ChatMessage(role: "system", content: "You are an expert content creator specializing in converting written content into engaging audio experiences. Your task is to transform text into compelling scripts for different listening formats."),
            ChatMessage(role: "user", content: prompt)
        ]
        
        let request = ChatRequest(
            model: OpenAIModels.gpt4o,
            messages: messages,
            temperature: 0.7,
            max_tokens: 4000
        )
        
        return try await sendChatRequest(request)
    }
    
    private func buildScriptPrompt(for mode: ListeningMode, text: String) -> String {
        let truncatedText = String(text.prefix(10000)) // Limit input size
        
        switch mode {
        case .narration:
            return """
            Convert the following text into a polished, professional narration script suitable for an audiobook. 
            Maintain the original meaning and tone. Clean up any formatting issues and make it flow naturally when read aloud.
            
            Text:
            """
            + truncatedText
            + """
            
            Provide the narration script:
            """
            
        case .podcast:
            return """
            Convert the following content into an engaging podcast discussion between two hosts.
            
            Host 1: "Alex" - curious learner, asks questions, relates to listeners
            Host 2: "Sam" - expert teacher, provides insights, explains complex concepts
            
            Make it conversational, natural, and easy to understand. Include natural pauses, transitions, and occasional humor where appropriate.
            
            Content to convert:
            """
            + truncatedText
            + """
            
            Provide the podcast script with speaker labels:
            """
            
        case .summary:
            return """
            Create a concise 5-minute audio summary of the following content. 
            Focus on the key insights, main points, and actionable takeaways.
            Structure it as:
            - Brief intro (what this content is about)
            - Key point 1
            - Key point 2
            - Key point 3
            - Key takeaways / conclusions
            
            Content:
            """
            + truncatedText
            + """
            
            Provide the summary script:
            """
            
        case .lecture:
            return """
            Transform the following content into an educational lecture script.
            Imagine you are a teacher explaining this to students. 
            
            Structure:
            - Introduction: What we'll learn
            - Main concepts (explain each clearly)
            - Examples and analogies
            - Key takeaways
            - Summary
            
            Use a warm, engaging teaching style. Break down complex ideas into digestible parts.
            
            Content:
            """
            + truncatedText
            + """
            
            Provide the lecture script:
            """
            
        case .story:
            return """
            Transform the following content into an engaging story-style narration.
            
            Use a cinematic, narrative voice. Make it feel like someone is telling a fascinating story.
            Include descriptive language, build suspense where appropriate, and create an emotional connection.
            
            Content:
            """
            + truncatedText
            + """
            
            Provide the story narration script:
            """
        }
    }
    
    private func sendChatRequest(_ request: ChatRequest) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                return chatResponse.choices.first?.message.content ?? ""
            } else {
                // Try to parse error message
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorDict["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                }
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
    
    /// Generate a simple explanation for selected text
    func explainText(_ text: String, detailLevel: ExplanationDetailLevel = .simple) async throws -> String {
        guard OpenAIConfig.isConfigured else {
            throw OpenAIError.notConfigured
        }
        
        let detailPrompt: String
        switch detailLevel {
        case .simple:
            detailPrompt = "Provide a brief, easy-to-understand explanation."
        case .detailed:
            detailPrompt = "Provide a detailed explanation with examples."
        case .example:
            detailPrompt = "Provide an explanation with practical examples."
        }
        
        let prompt = "\(detailPrompt)\n\nText to explain: \(text)\n\nExplanation:"
        
        let messages = [
            ChatMessage(role: "system", content: "You are a helpful tutor that explains concepts clearly."),
            ChatMessage(role: "user", content: prompt)
        ]
        
        let request = ChatRequest(
            model: OpenAIModels.gpt4o,
            messages: messages,
            temperature: 0.5,
            max_tokens: 1000
        )
        
        return try await sendChatRequest(request)
    }
}

// MARK: - Explanation Detail Level
enum ExplanationDetailLevel: String, CaseIterable {
    case simple = "Simple"
    case detailed = "Detailed"
    case example = "With Examples"
}

// MARK: - String Chunking Extension
extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let endIndex = self.index(currentIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            let chunk = String(self[currentIndex..<endIndex])
            chunks.append(chunk)
            currentIndex = endIndex
        }
        
        return chunks
    }
}

// MARK: - Audio File Manager
class AudioFileManager {
    static let shared = AudioFileManager()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    var audioDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioPath = documentsPath.appendingPathComponent("GeneratedAudio", isDirectory: true)
        
        if !fileManager.fileExists(atPath: audioPath.path) {
            try? fileManager.createDirectory(at: audioPath, withIntermediateDirectories: true)
        }
        
        return audioPath
    }
    
    func saveAudio(_ data: Data, filename: String) throws -> URL {
        let fileURL = audioDirectory.appendingPathComponent("\(filename).mp3")
        try data.write(to: fileURL)
        return fileURL
    }
    
    func getAudioURL(filename: String) -> URL {
        let fileURL = audioDirectory.appendingPathComponent("\(filename).mp3")
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return fileURL
    }
    
    func deleteAudio(filename: String) {
        let fileURL = audioDirectory.appendingPathComponent("\(filename).mp3")
        try? fileManager.removeItem(at: fileURL)
    }
    
    func getAllGeneratedAudio() -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(
            at: audioDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        return contents?.filter { $0.pathExtension == "mp3" } ?? []
    }
}
