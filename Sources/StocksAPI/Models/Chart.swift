//
//  File.swift
//  
//
//  Created by Federico Lupotti on 20/02/23.
//

import Foundation

public struct ChartResponse: Decodable {
    
    public let data: [ChartData]?
    public let error: ErrorResponse?
    
    enum CodingKeys: CodingKey {
        case chart
    }
    
    enum ChartKeys: CodingKey {
        case result
        case error
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let chartContainer = try? container.nestedContainer(keyedBy: ChartKeys.self, forKey: .chart) {
            
            data = try? chartContainer.decodeIfPresent([ChartData].self, forKey: .result)
            error = try? chartContainer.decodeIfPresent(ErrorResponse.self, forKey: .error)
        } else {
            data = nil
            error = nil
        }
    }
    
    init(data: [ChartData]?, error: ErrorResponse?) {
        self.data = data
        self.error = error
    }
    
}

public struct ChartData: Decodable {
    
    public let meta: ChartMeta
    public let indicators: [Indicator]
    
    enum CodingKeys: CodingKey {
        case meta
        case indicators
        case timestamp
    }
    
    enum IndicartorKeys: CodingKey {
        case quote
    }
    
    enum QuoteKeys: CodingKey {
        case close
        case high
        case low
        case open
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        meta = try container.decode(ChartMeta.self, forKey: .meta)
        
        let timestamps = try container.decodeIfPresent([Date].self, forKey: .timestamp) ?? []
        
        if let indicatorContainer = try? container.nestedContainer(keyedBy: IndicartorKeys.self, forKey: .indicators),
           var quotes = try? indicatorContainer.nestedUnkeyedContainer(forKey: .quote),
           let quotecontainer = try? quotes.nestedContainer(keyedBy: QuoteKeys.self) {
                
            let highs = try quotecontainer.decodeIfPresent([Double?].self, forKey: .high) ?? []
            let closes = try quotecontainer.decodeIfPresent([Double?].self, forKey: .close) ?? []
            let lows = try quotecontainer.decodeIfPresent([Double?].self, forKey: .low) ?? []
            let opens = try quotecontainer.decodeIfPresent([Double?].self, forKey: .open) ?? []
            
            self.indicators = timestamps.enumerated().compactMap({ (offset, timestamp) in
                
                guard
                    let open = opens[offset],
                    let close = closes[offset],
                    let low = lows[offset],
                    let high = highs[offset]
                else { return nil }
                return .init(timestamp: timestamp, low: low , high: high, open: open, close: close)
            })
            
            
        } else {
            self.indicators = []
        }
    }
    
    init(meta: ChartMeta, indicators: [Indicator]) {
        self.meta = meta
        self.indicators = indicators
    }
}


public struct ChartMeta: Decodable {
    
    public let currency: String
    public let symbol: String
    public let regularMarketPrice: Double?
    public let previousClose: Double?
    public let gmtoffset: Int
    public let regularTradingPeriodStartDate: Date
    public let regularTradingPeriodEndDate: Date
    
    enum CodingKeys: CodingKey {
        case currency
        case symbol
        case regularMarketPrice
        case previousClose
        case gmtoffset
        case currentTradingPeriod
    }
    
    enum CurrentTradingKeys: CodingKey {
        case pre
        case regular
        case post
    }
    
    enum TradingPeriodKeys: CodingKey {
        case start
        case end
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? ""
        self.symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? ""
        self.regularMarketPrice = try container.decodeIfPresent(Double.self, forKey: .regularMarketPrice) ?? 0
        self.previousClose = try container.decodeIfPresent(Double.self, forKey: .previousClose) ?? 0
        self.gmtoffset = try container.decodeIfPresent(Int.self, forKey: .gmtoffset) ?? 0
        
        let currentTradingPeriodContainer = try? container.nestedContainer(keyedBy: CurrentTradingKeys.self, forKey: .currentTradingPeriod)
        
        let regularTradingPeriodContainer = try? currentTradingPeriodContainer?.nestedContainer(keyedBy: TradingPeriodKeys.self, forKey: .regular)
        
        self.regularTradingPeriodStartDate = try regularTradingPeriodContainer?.decodeIfPresent(Date.self, forKey: .start) ?? Date()
        self.regularTradingPeriodEndDate = try regularTradingPeriodContainer?.decodeIfPresent(Date.self, forKey: .end) ?? Date()
        
        
    }
    
}


public struct Indicator: Codable {
    
    public let timestamp: Date
    public let low: Double
    public let high: Double
    public let open: Double
    public let close: Double
    
    init(timestamp: Date, low: Double, high: Double, open: Double, close: Double) {
        self.timestamp = timestamp
        self.low = low
        self.high = high
        self.open = open
        self.close = close
    }

}
