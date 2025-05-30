//
//  APIClient.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

struct APIClient: RequestExecutor {
    
    enum APIError: Error {
        case requestFailed(String)
        case invalidResponse
        case decodingError(Error)
        case streamProcessingError
        case apiError(String)
        case userCancelledStream
    }
    
    private let session: URLSession
    var timeout: TimeInterval?
    var requestHeader: [String: String]? = ["Connection": "Keep-Alive"]

    init(session: URLSession = .shared, timeout: TimeInterval? = nil, requestHeader: [String: String]? = ["Connection": "Keep-Alive"]) {
        self.session = session
        self.timeout = timeout
        self.requestHeader = requestHeader
    }

    func execute<T: Responable>(_ request: Requestable) async throws -> T {
        let urlRequest = self.createURLRequest(from: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                throw APIError.requestFailed("Invalid response status: \(httpResponse.statusCode)")
            }
            
            // when session delete success, it's response "null"
            if let text = String(data: data, encoding: .utf8), text == "null" {
                let textData = Data("true".utf8)
                return try T.decode(textData)
            }
//            print("data: \(String(describing: String(data: data, encoding: .utf8)))")

            return try T.decode(data)
            
        } catch let decodingError as DecodingError {
            print("ApiClient decodingError: \(decodingError.localizedDescription)")
            throw APIError.decodingError(decodingError)
        } catch {
            print("ApiClient error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func executeStream<T: Responable>(_ request: Requestable) async throws -> AsyncThrowingStream<T, Error> {
        let urlRequest = createURLRequest(from: request)
        
        return AsyncThrowingStream { continuation in
            let networkTask = Task {
                
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    if !(200..<300).contains(httpResponse.statusCode) {
                        var errorDataString = "No error data."
                        var errorBody: Data?
                        
                        for try await byte in bytes {
                            if Task.isCancelled {
                                print("Tasl streaming cancelled.")
                                throw APIError.userCancelledStream
                            }
                            if errorBody == nil {
                                errorBody = Data()
                            }
                            errorBody?.append(byte)
                        }
                        
                        if let data = errorBody {
                            errorDataString = String(data: data, encoding: .utf8) ?? "Could not decode error body."
                        }
                        
                        continuation.finish(throwing: APIError.requestFailed("Invalid response status: \( (response as? HTTPURLResponse)?.statusCode ?? 0 ). Body: \(errorDataString)"))
                        
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            print("Tasl streaming cancelled.")
                            throw APIError.userCancelledStream
                        }
                        
                        if line.hasPrefix("data: ") {
                            let dataString = String(line.dropFirst(6)) // Remove "data: "
                            
                            if dataString == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            guard let jsonData = dataString.data(using: .utf8) else {
                                print("Warning: Could not convert string to data: \(dataString)")
                                continue
                            }
      
                            do {
                                let streamResponse = try T.decode(jsonData)
                                continuation.yield(streamResponse)
                            } catch {
                                print("Warning: Decoding stream chunk failed: \(error). Chunk: \(dataString)")
                            }
                        }
                    }
                    
                    continuation.finish()
                    
                } catch is CancellationError {
                    print("Catch: Streaming cancelled.")
                    continuation.finish(throwing: APIError.userCancelledStream)
                }
                catch APIError.userCancelledStream  {
                    print("Catch: APIError.userCancelledStream.")
                    continuation.finish(throwing: APIError.userCancelledStream)
                }
                catch {
                    continuation.finish(throwing: APIError.streamProcessingError)
                }
            }
            
            continuation.onTermination = { termination in
                switch termination {
                case .cancelled:
                    print("Stream was cancelled by the user")
                    networkTask.cancel()
                case .finished:
                    print("Stream finished normally")
                @unknown default:
                    print("Unknown termination")
                }
            }
        }
    }
    
    private func createURLRequest(from requestable: Requestable) -> URLRequest {
        var url = requestable.requestURL
        if let path = requestable.path {
            url = url.appendingPathComponent(path)
        }
        
        var urlRequest = URLRequest(url: url)
        if let timeout = (requestable.timeout ?? self.timeout) {
            urlRequest.timeoutInterval = timeout
        }
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.httpMethod = requestable.httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = requestHeader
        requestable.header.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let paramater = requestable.paramater {
            switch paramater {
            case .body(let data):
                urlRequest.httpBody = data
            case.query(let queries):
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = queries.map { URLQueryItem(name: $0.key, value: $0.value) }
                components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
                urlRequest.url = components.url
            }
        }
        
        print("urlRequest:\(urlRequest)")
        return urlRequest
    }
}
