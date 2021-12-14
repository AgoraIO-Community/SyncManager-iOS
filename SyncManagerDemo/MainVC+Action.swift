//
//  MainVC+Action.swift
//  SyncManagerDemo
//
//  Created by ZYP on 2021/12/10.
//

import Foundation
import AgoraSyncManager

extension MainVC { /** 基础 **/
    func initManager() {
        let config = AgoraSyncManager.RtmConfig(appId: Config.appId,
                                           channelName: channelName)
        syncManager = AgoraSyncManager(config: config,
                                  complete: { code in
            if code == 0 {
                self.show("success")
                print("SyncManager init success")
            }
            else {
                self.show("fail (\(code)")
                print("SyncManager init error")
            }
        })
    }
    
    func joinScene() {
        let scene = Scene(id: "roomid", userId: "userid", property: nil)
        syncRef = syncManager.joinScene(scene: scene) { [weak self](obj) in
            self?.show("success")
            if let str = obj.first?.toJson() { print(str) }
        }
    }
}

extension MainVC { /** 房间列表 **/
    func getScenes() {
        syncManager.getScenes { [weak self](objs) in
            self?.show("success")
            let strs = objs.compactMap({ $0.toJson() })
            print(strs)
        } fail: { [weak self](error) in
            self?.show("fail: " + error.description)
        }
    }
    
    func deleteScenes() {
        syncManager.deleteScenes(sceneIds: ["roomid"]) { [weak self] in
            self?.show("success")
        } fail: { [weak self](error) in
            self?.show("fail: " + error.description)
        }
    }
}

extension MainVC { /** 房间信息 **/
    func updteRoomInfo() {
        syncRef.update(data: ["color" : "red \(Int.random(in: 0...100))"],
                       success: nil,
                       fail: { [weak self] error in
            self?.show("fail: " + error.description)
        })
    }
    
    func getRoomInfo() {
        syncRef.get() { [weak self] obj in
            self?.show("success")
            if let str = obj?.toJson() { print(str) }
            else { print("no value for key (getRoomInfo)") }
        } fail: { [weak self] error in
            self?.show("fail: " + error.description)
        }
    }
    
    func subscribeRoom() {
        syncRef.subscribe(onUpdated: { obj in
            print("\(obj.toJson() ?? "")")
        },onDeleted: { obj in
            print("\(obj.toJson() ?? "")")
        },fail: { error in
            print(error.description)
        })
    }
    
    func unsubscribeRoom() {
        syncRef.unsubscribe()
    }
}

extension MainVC { /** 成员信息 **/
    func addMember() {
        syncRef.collection(className: "member")
            .add(data: ["userName" : "UserName"]) { [weak self](obj) in
                self?.show("success")
                if let str = obj.toJson() { print(str) }
                self?.memberObjId = obj.getId()
            } fail: { [weak self](error) in
                self?.show("fail: " + error.description)
            }
    }
    
    func updateMember() {
        
    }
    
    func deleteMember() {
        guard let id = memberObjId else {
            show("请先进行 add member 操作")
            return
        }
        syncRef.collection(className: "member")
            .document(id: id)
            .delete { [weak self](_) in
                self?.show("success")
            } fail: { [weak self](error) in
                self?.show("fail: " + error.description)
            }
    }
    
    func getMember() {
        syncRef.collection(className: "member")
            .get { [weak self](objs) in
                self?.show("success")
                var strings = [String]()
                for obj in objs {
                    if let str = obj.toJson() {
                        strings.append(str)
                    }
                }
                print(strings)
            } fail: { [weak self](error) in
                self?.show("fail: " + error.description)
            }
    }
    
    func subscribeMember() {
        
    }
    
    func unsubscribeMember() {
        
    }
    
    func deleteAllMemners() {
        syncRef.collection(className: "member").delete { [weak self](objs) in
            self?.show("success")
        } fail: { [weak self](error) in
            self?.show("fail: " + error.description)
        }

    }
}
