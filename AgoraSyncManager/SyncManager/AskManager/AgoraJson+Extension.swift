//
//  AgoraJson+Extension.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit

extension AgoraJson {
    func getJsonString(field: String) -> String {
        var str: NSString = ""
        var json = AgoraJson()
        var ret = getField(field, agoraJson: &json)
        if ret != 0 {
            Log.errorText(text: "getString error \(ret) \(str)", tag: "AgoraJson.getJsonString")
        }
        ret = json.getString(&str)
        if ret != 0 {
            Log.errorText(text: "getString error \(ret) \(str)", tag: "AgoraJson.getJsonString")
        }
        return str as String
    }
}
