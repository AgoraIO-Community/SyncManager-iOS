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
//        let config = AgoraSyncManager.RtmConfig(appId: Config.appId,
//                                           channelName: channelName)
        let config = AgoraSyncManager.RethinkConfig(appId: Config.appId, channelName: channelName)
        
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
        let scene = Scene(id: sceneId, userId: "userid", isOwner: true, property: ["sss": "aaaa", "bbbb": "bbbbb"])
        syncManager.createScene(scene: scene, success: { [weak self] in
            self?.syncManager.joinScene(sceneId: self?.sceneId ?? "") { syncRef in
                self?.syncRef = syncRef
                self?.show("success")
            } fail: { error in
                self?.show(error.localizedDescription)
            }

        }, fail: { [weak self] error in
            self?.show(error.localizedDescription)
        })
    }
    
    func deleteScene() {
        syncRef.delete(success: nil, fail: nil)
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
}

extension MainVC { /** 房间信息 key == nil **/
    func updteRoomInfo1() {
        syncRef.update(key: "", data: ["color" : "red \(Int.random(in: 0...100))"]) { [weak self] objs in
            let string = "update success: " + "\(objs.first?.toJson() ?? "nil")"
            self?.show(string)
        } fail: { [weak self] error in
            self?.show("fail: " + error.description)
        }
    }
    
    func getRoomInfo1() {
        syncRef.get(key: "") { [weak self] obj in
            self?.show("success")
            if let str = obj?.toJson() { print(str) }
            else { print("no value for key (getRoomInfo1)") }
        } fail: { [weak self] error in
            self?.show("fail: " + error.description)
        }
    }
    
    func subscribeRoom1() {
        syncRef.subscribe(key: "") { obj in
            print("subscribeRoom1-onCreated \(obj.toJson() ?? "")")
        } onUpdated: { obj in
            print("subscribeRoom1-onUpdated \(obj.toJson() ?? "")")
        } onDeleted: { obj in
            print("subscribeRoom1-onDeleted \(obj.toJson() ?? "")")
        } onSubscribed: {
            print("subscribeRoom1-onSubscribed")
        } fail: { error in
            print("subscribeRoom1 " + error.description)
        }
    }
    
    func unsubscribeRoom1() {
        syncRef.unsubscribe(key: "")
    }
}

extension MainVC { /** 房间信息 key == member **/
    func updteRoomInfo2() {
        syncRef.update(key: "member",
                       data: ["memberName" : "zhang \(Int.random(in: 0...100))"],
                       success: { [weak self](objs) in
            let string = "update success: " + "\(objs.first?.toJson() ?? "nil")"
            self?.show(string)
        }, fail: { [weak self] error in
            self?.show("fail: " + error.description)
        })
    }
    
    func getRoomInfo2() {
        syncRef.get(key: "member") { [weak self] obj in
            self?.show("success")
            if let str = obj?.toJson() { print(str) }
            else { print("no value for key (getRoomInfo2)") }
        } fail: { [weak self] error in
            self?.show("fail: " + error.description)
        }
    }
    
    func subscribeRoom2() {
        syncRef.subscribe(key: "member",
                          onCreated: { obj in
            print("subscribeRoom2 onCreated \(obj.toJson() ?? "")")
        },onUpdated: { obj in
            print("subscribeRoom2 onUpdated \(obj.toJson() ?? "")")
        },onDeleted: { obj in
            print("subscribeRoom2 onDeleted \(obj.toJson() ?? "")")
        },fail: { error in
            print(error.description)
        })
    }
    
    func unsubscribeRoom2() {
        syncRef.unsubscribe(key: "member")
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
        guard let id = memberObjId else {
            show("请先进行 add member 操作")
            return
        }
        syncRef.collection(className: "member")
            .update(id: id,
                    data: ["userName" : "UserName update \(Int.random(in: 0...100))"],
                    success: { [weak self] in
                self?.show("success")
            }, fail: { [weak self](error) in
                self?.show("fail: " + error.description)
            })
    }
    
    func deleteMember() {
        guard let id = memberObjId else {
            show("请先进行 add member 操作")
            return
        }
        syncRef.collection(className: "member")
            .delete(id: id,
                    success: { [weak self] _ in
                self?.show("success")
            }, fail: { [weak self](error) in
                self?.show("fail: " + error.description)
            })
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
        syncRef.collection(className: "member").document().subscribe(key: "",
                                                                     onCreated: { obj in
            print("onCreated \(obj.toJson() ?? "")")
        }, onUpdated: { obj in
            print("onUpdated \(obj.toJson() ?? "")")
        }, onDeleted: { obj in
            print("onDeleted \(obj.toJson() ?? "")")
        }, onSubscribed: {
            print("onSubscribed")
        }, fail: { error in
            
        })
    }
    
    func unsubscribeMember() {
        syncRef.collection(className: "member").document().unsubscribe(key: "")
    }
    
    func deleteAllMemners() {
        syncRef.collection(className: "member").delete { [weak self](objs) in
            self?.show("success")
        } fail: { [weak self](error) in
            self?.show("fail: " + error.description)
        }

    }
}
