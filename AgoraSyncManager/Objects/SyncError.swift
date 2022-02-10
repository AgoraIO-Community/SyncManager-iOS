//
//  Error.swift
//  SyncManager
//
//  Created by ZYP on 2021/11/15.
//

import Foundation

public class SyncError: NSObject, LocalizedError {
    public let message: String
    public let code: Int
    let domain: SyncErrorDomain
    public var domainName: String { domain.name }
    
    override public var description: String {
        return "[\(domainName)]: " + "(\(code))" + message
    }
    
    public var errorDescription: String? {
        return description
    }
    
    
    
    convenience init(message: String,
                     code: Int) {
        self.init(message: message,
                  code: code,
                  domain: .rtm)
    }
    
    required init(message: String,
                  code: Int,
                  domain: SyncErrorDomain) {
        self.message = message
        self.code = code
        self.domain = domain
    }
    
    static func ask(message: String,
                    code: Int) -> SyncError {
        SyncError(message: message, code: code, domain: .ask)
    }
}

enum SyncErrorDomain {
    case rtm
    case ask
    
    var name: String {
        switch self {
        case .rtm:
            return "Agora Rtm"
        case .ask:
            return "Agora Ask"
        }
    }
}
