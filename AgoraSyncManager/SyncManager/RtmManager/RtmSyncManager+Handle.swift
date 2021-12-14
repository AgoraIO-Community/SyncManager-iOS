//
//  RtmSyncManager+Handle.swift
//  SyncManager
//
//  Created by ZYP on 2021/11/15.
//

import Foundation
import AgoraRtmKit

extension RtmSyncManager {
    func notifyObserver(channel: AgoraRtmChannel, attributes: [AgoraRtmChannelAttribute]) {
        let onCreateBlock = onCreateBlocks[channel]
        let onUpdateBlock = onUpdatedBlocks[channel]
        let onDeleteBlock = onDeletedBlocks[channel]
        
        if let cache = self.cachedAttrs[channel] {
            var onlyA = [IObject]()
            var onlyB = [IObject]()
            var both = [IObject]()
            var temp = [String : AgoraRtmChannelAttribute]()
            
            for i in cache {
                temp[i.key] = i
            }
            
            for b in attributes {
                if let i = temp[b.key] {
                    if b.value != i.value {
                        both.append(b.toAttribute())
                    }
                    temp.removeValue(forKey: b.key)
                }
                else{
                    onlyB.append(b.toAttribute())
                }
            }
            
            for i in temp.values {
                onlyA.append(i.toAttribute())
            }
            
            for i in both {
                onUpdateBlock?(i)
            }
            for i in onlyB {
                onCreateBlock?(i)
            }
            for i in onlyA {
                onDeleteBlock?(i)
            }
            cachedAttrs[channel] = attributes
        }
    }
}
