//
//  File.swift
//  
//
//  Created by Federico Lupotti on 19/02/23.
//

import Foundation

public struct ErrorResponse: Codable {
    
    public let code: String
    public let description: String
    
    public init(code: String, description: String) {
        self.code = code
        self.description = description
    }
}
