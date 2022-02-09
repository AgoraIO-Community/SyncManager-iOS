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
        let ret = getString(&str)
        if ret != 0 {
            Log.errorText(text: "getString error \(ret) \(str)", tag: "AgoraJson.getJsonString")
        }
        return str as String
    }
}
