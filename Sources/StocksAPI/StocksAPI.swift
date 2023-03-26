import Foundation

public protocol IStocksAPI {
    func fetchChartData(tickerSymbol: String, range: ChartRange) async throws -> ChartData?
    func fetchChartRawData(symbol: String, range: ChartRange) async throws -> (Data, URLResponse)
    func searchTickers(query: String, isEquityTypeOnly: Bool) async throws -> [Ticker]
    func searchTickersRawData(query: String, isEquityTypeOnly: Bool) async throws -> (Data, URLResponse)
    func fetchQuotes(symbols: String) async throws -> [Quote]
    func fetchQuotesRawData(symbols: String) async throws -> (Data, URLResponse)
}

public struct StocksAPI {
    private let session = URLSession.shared
    private let jsondDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    private let baseURL = "https://query1.finance.yahoo.com"
    
    public func fetchChartData(symbol: String, range: ChartRange) async throws -> ChartData? {
        guard var urlComponents = URLComponents(string: "\(baseURL)/v8/finance/chart/\(symbol)") else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            .init(name: "range", value: range.rawValue),
            .init(name: "interval", value: range.interval),
            .init(name: "indicators", value: "quote"),
            .init(name: "includeTimeStamps", value: "true")
        ]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (response, statusCode): (ChartResponse, Int) = try await fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        return response.data?.first
    }
    
    

    public init() {}
    
    public func searchTickers(query: String, isEquityTypeOnly: Bool = true) async throws -> [Ticker] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/v1/finance/search") else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            .init(name: "q", value: query),
            .init(name: "quotesCount", value: "20"),
            .init(name: "lang", value: "en-US")
        ]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (response, statusCode): (SearchTickerResponse, Int) = try await fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        if isEquityTypeOnly {
            return (response.data ?? [])
                .filter { ($0.quoteType ?? "").localizedCaseInsensitiveCompare("equity") == .orderedSame }
        } else {
            return response.data ?? []
        }
    }
    
    public func searchTickersRawData(query: String, isEquityTypeOnly: Bool) async throws -> (Data, URLResponse) {
        guard let url = urlForSearchTickers(query: query) else { throw APIError.invalidURL }
        return try await session.data(from: url)
    }
    
    private func urlForSearchTickers(query: String) -> URL? {
        guard var urlComp = URLComponents(string: "\(baseURL)/v1/finance/search") else { return nil }
        
        urlComp.queryItems = [
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "quotesCount", value: "20"),
            URLQueryItem(name: "q", value: query)
        ]
        return urlComp.url
    }
    
    public func fetchQuotes(symbols: String) async throws -> [Quote] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/v7/finance/quote") else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [.init(name: "symbols", value: symbols)]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (response, statusCode): (QuoteResponse, Int) = try await fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        return response.data ?? []
    }
    
    private func fetch<D: Decodable>(url: URL) async throws -> (D, Int) {
        let (data, response) = try await session.data(from: url)
        let statusCode = try validateHTTPResponse(response)
        return (try jsondDecoder.decode(D.self, from: data), statusCode)
    }
    
    private func validateHTTPResponse(_ response: URLResponse) throws -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponseType
        }
        
        guard 200...299 ~= httpResponse.statusCode || 400... ~= httpResponse.statusCode
        else {
            throw APIError.httpStatusCodeFailed(statusCode: httpResponse.statusCode, error: nil)
        }
        return httpResponse.statusCode
    }
}
