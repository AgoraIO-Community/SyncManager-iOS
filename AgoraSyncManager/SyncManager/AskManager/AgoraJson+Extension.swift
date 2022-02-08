//
//  AgoraJson+Extension.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit

extension AgoraJson {
    func getJsonString() -> String {
        var str: NSString = ""
        getString(&str)
        return str as String
    }
}
