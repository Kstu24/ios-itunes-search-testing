//
//  SearchResultController.swift
//  iTunes Search
//
//  Created by Spencer Curtis on 8/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

protocol NetworkSessionProtocol {
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: NetworkSessionProtocol {
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let dataTask = self.dataTask(with: request, completionHandler: completionHandler)
        dataTask.resume()
    }
}

class MockURLSession: NetworkSessionProtocol {
    let data: Data?
    let error: Error?
    init(data: Data?, error: Error?) {
        self.data = data
        self.error = error
    }
    
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DispatchQueue.global().async {
            completionHandler(self.data, nil, self.error)
        }
    }
}

class SearchResultController {
    
    enum PerformSearchError: Error {
        case requestURLIsNil
        case network(Error)
        case invalidStateNoErrorButNoData
        case invalidJSON(Error)
    }
    
    func performSearch(for searchTerm: String, resultType: ResultType,
                       urlSession: NetworkSessionProtocol,
                       completion: @escaping (Result<[SearchResult], PerformSearchError>) -> Void) {
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let parameters = ["term": searchTerm,
                          "entity": resultType.rawValue]
        let queryItems = parameters.compactMap { URLQueryItem(name: $0.key, value: $0.value) }
        urlComponents?.queryItems = queryItems
        
        guard let requestURL = urlComponents?.url else {
            completion(.failure(.requestURLIsNil))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        urlSession.fetch(with: request) { (possibleData, _, possibleError) in
            
            guard possibleError == nil else {
                completion(.failure(.network(possibleError!)))
                    return
            }
            
            guard let data = possibleData else {
                completion(.failure(.invalidStateNoErrorButNoData))
                return
                
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                let searchResults = try jsonDecoder.decode(SearchResults.self, from: data)
                completion(.success(searchResults.results))
            } catch {
                completion(.failure(.invalidJSON(error)))
            }
        }
    }
//        dataTask.resume()
//    }
    
    let baseURL = URL(string: "https://itunes.apple.com/search")!
}
