//
//  APIClient.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

struct APIClient: RequestExecutor {
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
                throw NSError(domain: "APIClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                throw NSError(domain: "APIClientError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code \(httpResponse.statusCode)"])
            }
            
            // when delete success, it's response "null"
            if let text = String(data: data, encoding: .utf8), text == "null" {
                let textData = Data("true".utf8)
                return try T.decode(textData)
            }

//            print("data: \(String(describing: String(data: data, encoding: .utf8)))")

            return try T.decode(data)
            
        } catch let decodingError as DecodingError {
            print("ApiClient decodingError: \(decodingError.localizedDescription)")
            throw decodingError
        } catch {
            print("ApiClient error: \(error.localizedDescription)")
            throw error
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
