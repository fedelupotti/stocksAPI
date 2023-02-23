//
//  File.swift
//  
//
//  Created by Federico Lupotti on 19/02/23.
//

import Foundation
import StocksAPI

@main
struct StocksAPIExec {
    
    static let stocksAPI = StocksAPI()
    
    static func main() async {
        do {
            let quotes = try await stocksAPI.fetchChartData(symbol: "TSLA", range: .oneDay)
            print(quotes)
        }
        catch {
            print(error.localizedDescription)
            print("Fake commit")
        }
        
//        let (data, _) = try! await URLSession.shared.data(from:  URL(string: "https://query1.finance.yahoo.com/v7/finance/quote")!)
//        let quoteResponse = try! JSONDecoder().decode(QuoteResponse.self, from: data)
//        print(quoteResponse)
        
//        let (dataSticker, _) = try! await URLSession.shared.data(from: URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=TESLA")!)
//        let tickerResponse = try! await JSONDecoder().decode(SearchTickerResponse.self, from: dataSticker)
//        print(tickerResponse)
        
//        let (dataSticker, _) = try! await URLSession.shared.data(from: URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/TSLA?range=1d&interval=1m&includetimestamp=true&indicators=quote")!)
//        let tickerResponse = try! await JSONDecoder().decode(ChartResponse.self, from: dataSticker)
//        print(tickerResponse)
    }
}
