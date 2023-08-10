//
//  RethinkSyncManager.swift
//  AgoraSyncManager
//
//  Created by zhaoyongqiang on 2022/7/5.
//

import SocketRocket

private let showSyncQueueID = "showSyncQueueID"

extension RethinkSyncManager {
    struct Config {
        let appId: String
        let channelName: String
        
        init(appId: String,
             channelName: String)
        {
            self.appId = appId
            self.channelName = channelName
        }
    }
}

enum SocketType: String {
    case getRoomList
    case send
    case subscribe
    case unsubscribe
    case query
    case deleteProp
    case ping
    case syncRoom
    case deleteRoom
}

public enum SocketConnectState: Int {
    case connecting = 0
    case open = 1
    case fail = 2
    case closed = 3
}

public class RethinkSyncManager: NSObject {
//    private let SOCKET_URL: String = "wss://rethinkdb-msg.bj2.agoralab.co/v2"
//        private let SOCKET_URL: String = "wss://test-rethinkdb-msg.bj2.agoralab.co/v2"
    //    private let SOCKET_URL: String = "wss://rethinkdb-msg.bj2.agoralab.co"
    private let SOCKET_URL: String = "wss://rethinkdb-msg-overseas-prod.sg3.agoralab.co"
    private lazy var serialQueue = DispatchQueue(label: showSyncQueueID)
    private var timer: Timer?
    private var state: SRReadyState = .CLOSED
    private var socket: SRWebSocket?
    private var connectBlock: SuccessBlockInt?
    private var lastKey: String?
    var queryRoomCompletion: SuccessBlockObjOptional?
    var onSuccessBlock = [String: SuccessBlock]()
    var onUpdateBlock = [String: SuccessBlock]()
    var onSuccessBlockVoid = [String: SuccessBlockVoid]()
    var onDeleteBlockObjOptional = [String: SuccessBlockObjOptional?]()
    var onSuccessBlockObjOptional = [String: SuccessBlockObjOptional]()
    var onSuccessBlockObj = [String: SuccessBlockObj]()
    var onFailBlock = [String: FailBlock]()
    var onCreateBlocks = [String: OnSubscribeBlock]()
    var onUpdatedBlocks = [String: OnSubscribeBlock]()
    var onDeletedBlocks = [String: OnSubscribeBlock]()
    var connectStateBlock: ConnectBlockState?
    var createRoomSuccess: SuccessBlockVoid?
    var createRoomFail: FailBlock?
    var rooms = [String]()
    var appId: String = ""
    var sceneName: String = ""
    var isOwner: Bool = false
    var ownerRoomId: String = ""
    
    /// init
    /// - Parameters:
    ///   - config: config
    ///   - complete: white `code = 0` is success, else error
    init(config: Config,
         complete: SuccessBlockInt?)
    {
        super.init()
        lastKey = config.channelName
        connectBlock = complete
        sceneName = config.channelName
        appId = config.appId
        reConnect(isRemove: true)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    public func reConnect(isRemove: Bool = false) {
        guard let url = URL(string: SOCKET_URL) else { return }
        if let socket = socket, socket.readyState == .CONNECTING {
            return
        }
        disConnect(isRemove: isRemove)
        socket = SRWebSocket(url: url)
        socket?.delegate = self
        socket?.delegateDispatchQueue = serialQueue
        socket?.open()
        timer = Timer.scheduledTimer(withTimeInterval: 10,
                                     repeats: true,
                                     block: { [weak self] _ in
            self?.rooms.forEach({
                let params = ["action": SocketType.ping.rawValue,
                              "appId": self?.appId ?? "",
                              "channelName": $0,
                              "requestId": UUID().uuid16string()]
                let data = Utils.toJsonString(dict: params)?.data(using: .utf8)
                try? self?.socket?.send(dataNoCopy: data)
            })
            
            if self?.isOwner == true {
                self?.syncRoom()
            }
            
            //TODO: retry if need
            self?.enterForegroundNotification()
        })
        timer?.fire()
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func syncRoom() {
        guard !sceneName.isEmpty && !rooms.isEmpty, !ownerRoomId.isEmpty else { return }
        let params = ["action": SocketType.syncRoom.rawValue,
                      "appId": appId,
                      "sceneName": sceneName,
                      "roomId": ownerRoomId,
                      "requestId": UUID().uuid16string()]
        let data = Utils.toJsonString(dict: params)?.data(using: .utf8)
        try? socket?.send(dataNoCopy: data)
    }
    
    public func disConnect(isRemove: Bool) {
        timer?.invalidate()
        timer = nil
        socket?.close()
        guard isRemove else { return }
        onSuccessBlock.removeAll()
        onUpdateBlock.removeAll()
        onSuccessBlockVoid.removeAll()
        onDeleteBlockObjOptional.removeAll()
        onSuccessBlockObjOptional.removeAll()
        onSuccessBlockObj.removeAll()
        onFailBlock.removeAll()
        onCreateBlocks.removeAll()
        onUpdatedBlocks.removeAll()
        onDeletedBlocks.removeAll()
        rooms.removeAll()
    }
    
    public func write(channelName: String,
                      data: [String: Any?],
                      roomId: String,
                      objectId: String? = nil,
                      objType: String,
                      isAdd: Bool = false,
                      isUpdate: Bool = false) {
        writeData(channelName: channelName,
                  params: data,
                  roomId: roomId,
                  objectId: objectId,
                  type: .send,
                  objType: objType,
                  isAdd: isAdd,
                  isUpdate: isUpdate)
    }
    
    public func subscribe(channelName: String,
                          roomId: String,
                          objType: String) {
        writeData(channelName: channelName,
                  params: [:],
                  roomId: roomId,
                  type: .subscribe,
                  objType: objType)
    }
    
    public func unsubscribe(channelName: String, roomId: String, objType: String) {
        writeData(channelName: channelName,
                  params: [:],
                  roomId: roomId,
                  type: .unsubscribe,
                  objType: objType)
    }
    
    private func writeData(channelName: String,
                           params: Any,
                           roomId: String,
                           objectId: String? = nil,
                           type: SocketType,
                           objType: String,
                           isAdd: Bool = false,
                           isUpdate: Bool = false)
    {
        guard !roomId.isEmpty else { return }
        lastKey = objType
        serialQueue.async { [weak self] in
            guard let self = self else {return}
            if self.rooms.isEmpty {
                Log.error(error: "请先createScene再joinScene后调用其它方法", tag: "SyncManager")
                return
            }
            
            var newParams = params
            var propsId: String = objectId ?? UUID().uuid16string()
            if objectId == nil && params is [String: Any] {
                var params = params as? [String: Any]
                if !(params?.keys.contains("objectId") ?? false) {
                    params?["objectId"] = channelName
                    propsId = channelName
                }
                newParams = params ?? [:]
            }
            let value = Utils.toJsonString(dict: newParams as? [String: Any])
            var p = ["appId": self.appId,
                     "sceneName": self.sceneName,
                     "action": type.rawValue,
                     "roomId": roomId,
                     "objVal": "",
                     "objType": objType,
                     "requestId": UUID().uuid16string(),
                     "props": [propsId: value ?? ""]] as [String: Any]
            if type == .subscribe || type == .unsubscribe || type == .query {
                p.removeValue(forKey: "props")
            }
            Log.debug(text: "props ======== \(p)", tag: "syncManager")
            let attr = Attribute(key: propsId,
                                 value: value ?? "")
            if isAdd {
                if let successBlockObj = self.onSuccessBlockObj[objType] {
                    DispatchQueue.main.async {
                        successBlockObj(attr)
                    }
                }
                if let onCreateBlock = self.onCreateBlocks[objType] {
                    DispatchQueue.main.async {
                        onCreateBlock(attr)
                    }
                }
            }
            if isUpdate {
                if let success = self.onSuccessBlockVoid[objType] {
                    DispatchQueue.main.async {
                        success()
                    }
                }
                if let success = self.onUpdateBlock[objType] {
                    DispatchQueue.main.async {
                        success([attr])
                    }
                }
            }
            Log.debug(text: "send params == \(p)", tag: type.rawValue)
            let data = try? JSONSerialization.data(withJSONObject: p, options: [])
            do {
                try self.socket?.send(dataNoCopy: data)
            } catch {
                Log.errorText(text: error.localizedDescription, tag: "error")
            }
        }
    }
    
    public func queryRoom(channelName: String,
                          roomId: String,
                          objType: String,
                          completion: SuccessBlockObjOptional?) {
        queryRoomCompletion = completion
        writeData(channelName: channelName,
                  params: [:],
                  roomId: roomId,
                  type: .query,
                  objType: objType)
    }
    
    public func query(channelName: String,
                      roomId: String,
                      objType: String) {
        writeData(channelName: channelName,
                  params: [:],
                  roomId: roomId,
                  type: .query,
                  objType: objType)
    }
    
    public func getRoomList(channelName: String) {
        lastKey = channelName
        if socket?.readyState != .OPEN, let successBlock = onSuccessBlock[channelName] {
            DispatchQueue.main.async {
                successBlock([])
            }
            return
        }
        let params = ["action": SocketType.getRoomList.rawValue,
                      "appId": appId,
                      "sceneName": channelName,
                      "requestId": UUID().uuid16string()]
        let data = try? JSONSerialization.data(withJSONObject: params, options: [])
        try? socket?.send(dataNoCopy: data)
    }
    
    public func deleteRoom(roomId: String) {
        lastKey = roomId
        if socket?.readyState != .OPEN, let onDeleteBlock = onDeleteBlockObjOptional[roomId] {
            DispatchQueue.main.async {
                onDeleteBlock?(Attribute(key: "", value: "not networking"))
            }
            return
        }
        let params = ["action": SocketType.deleteRoom.rawValue,
                      "appId": appId,
                      "sceneName": sceneName,
                      "roomId": roomId,
                      "requestId": UUID().uuid16string()]
        let data = try? JSONSerialization.data(withJSONObject: params, options: [])
        try? socket?.send(dataNoCopy: data)
        if let index = rooms.firstIndex(where: { $0 == roomId }) {
            rooms.remove(at: index)
        }
        if isOwner {
            ownerRoomId = ""
        }
    }
    
    public func delete(channelName: String, roomId: String, data: Any) {
        lastKey = channelName
        if socket?.readyState != .OPEN, let onUpdateBlock = onDeletedBlocks[channelName] {
            DispatchQueue.main.async {
                onUpdateBlock(Attribute(key: "", value: "not networking"))
            }
            return
        }
        var objectIds: [Any] = []
        if let params = data as? [[String: Any]] {
            objectIds = params.compactMap({ $0["objectId"] })
        } else if let params = data as? [String: Any], let objectId = params["objectId"] {
            objectIds = [objectId]
        }
        let p = ["appId": appId,
                 "sceneName": sceneName,
                 "roomId": roomId,
                 "objVal": "",
                 "objType": channelName,
                 "action": SocketType.deleteProp.rawValue,
                 "requestId": UUID().uuid16string(),
                 "props": objectIds] as [String: Any]
        Log.debug(text: "delete params == \(p)", tag: "delete")
        let data = try? JSONSerialization.data(withJSONObject: p, options: [])
        try? socket?.send(dataNoCopy: data)
    }
    
    @objc
    private func enterForegroundNotification() {
        guard socket?.readyState != .OPEN, socket?.readyState != .CONNECTING else { return }
        reConnect()
    }
    
    private func roomListHandler(data: [[String: Any]]?) -> [Attribute]? {
        let params = data?.compactMap({ item -> Attribute? in
            let props = item["props"] as? [String: Any]
            return attrsHandler(params: props)?.first
        })
        return params
    }
    
    private func attrsHandler(params: [String: Any]?) -> [Attribute]? {
        let objects = params?.keys
        let attrs = objects?.compactMap { item -> Attribute? in
            guard !item.isEmpty else { return nil }
            let value = params?[item] as? String
            let json = Utils.toDictionary(jsonString: value ?? "")
            if json.isEmpty { // 过滤掉不是json的数据
                return nil
            }
            return Attribute(key: item, value: value ?? "")
        }
        return attrs
    }
    
    private func notNetworkingHandler() {
        guard let lastKey = lastKey else { return }
        connectBlock?(SocketConnectState.closed.rawValue)
        if let successBlockObj = onSuccessBlockObj[lastKey] {
            DispatchQueue.main.async {
                successBlockObj(Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)"))
            }
        }
        if let failBlockObj = onFailBlock[lastKey] {
            DispatchQueue.main.async {
                failBlockObj(SyncError(message: "not networking", code: SocketConnectState.closed.rawValue))
            }
        }
        if let onCreateBlock = onCreateBlocks[lastKey] {
            DispatchQueue.main.async {
                onCreateBlock(Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)"))
            }
        }
        if let success = onUpdateBlock[lastKey] {
            DispatchQueue.main.async {
                success([Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)")])
            }
        }
        if let successBlock = onSuccessBlock[lastKey] {
            DispatchQueue.main.async {
                successBlock([Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)")])
            }
        }
        if let onDeleteBlock = onDeleteBlockObjOptional[lastKey] {
            DispatchQueue.main.async {
                onDeleteBlock?(Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)"))
            }
        }
        if let onDeleteBlock = onDeletedBlocks[lastKey] {
            DispatchQueue.main.async {
                onDeleteBlock(Attribute(key: "", value: "\(SocketConnectState.closed.rawValue)"))
            }
        }
        self.lastKey = nil
    }
}

extension RethinkSyncManager: SRWebSocketDelegate {
    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        Log.info(text: "连接状态 status == \(webSocket.readyState.rawValue)", tag: "connect")
        if state != webSocket.readyState {
            connectStateBlock?(SocketConnectState(rawValue: webSocket.readyState.rawValue) ?? .closed)
        }
        state = webSocket.readyState
        if let complete = connectBlock {
            complete(state == .OPEN ? 0 : -1)
            connectBlock = nil
        }
        
        guard socket?.readyState == .OPEN, !onUpdatedBlocks.isEmpty else { return }
        // 重连成功后重新订阅
        onUpdatedBlocks.keys.forEach({ item in
            rooms.forEach({
                subscribe(channelName: item, roomId: $0, objType: item)
            })
        })
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        
        guard let data = message as? Data else { return }
        let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        Log.info(text: "dict == \(dict ?? [:])", tag: "收到消息")
        let action = SocketType(rawValue: dict?["action"] as? String ?? "") ?? .send
        Log.info(text: "action == \(action.rawValue)", tag: "action")
        if action == .ping || action == .syncRoom { return }
        if let msg = dict?["msg"] as? String, msg == "success" {
            Log.info(text: "消息发送成功", tag: "socket")
        }
        let params = dict?["data"] as? [String: Any]
        let objType = dict?["objType"] as? String ?? ""
        let sceneName = dict?["sceneName"] as? String ?? ""
        let channelName = objType.isEmpty ? sceneName : objType
        let realAction = SocketType(rawValue: params?["action"] as? String ?? "") ?? .send
        Log.info(text: "realAction == \(realAction.rawValue)", tag: "realAction")
        
        if action == .getRoomList, let successBlock = onSuccessBlock[channelName] {
            let params = dict?["data"] as? [[String: Any]]
            let attrs = roomListHandler(data: params)
            DispatchQueue.main.async {
                successBlock(attrs ?? [])
            }
            return
        }
        
        if let code = dict?["code"] as? String, code != "0", let msg = dict?["msg"] as? String {
            let error = SyncError(message: "\(channelName) \(msg)", code: Int(code) ?? 0)
            Log.errorText(text: "code == \(code)  action == \(realAction) channelName == \(channelName) msg == \(msg)",
                          tag: "error")
            DispatchQueue.main.async {[weak self] in
                if objType == "room" {
                    self?.createRoomFail?(error)
                    self?.createRoomFail = nil
                } else {
                    self?.onFailBlock[channelName]?(error)
                }
            }
            return
        } else {
            if objType == "room" {
                createRoomSuccess?()
                createRoomSuccess = nil
            }
        }
        
        let props = params?["props"] as? [String: Any]
        let roomId = (params?["roomId"] as? String) ?? ""
        let propsDel = params?["propsDel"] as? [String]
        let propsUpdate = params?["propsUpdate"] as? String
        let objects = props?.keys
        let attrs = attrsHandler(params: props)
        
        // 返回查询房间结果
        if action == .query {
            DispatchQueue.main.async {[weak self] in
                self?.queryRoomCompletion?(attrs?.first)
            }
        }
        
        let isDelete = (params?["isDeleted"] as? Bool) ?? false
        if isDelete, let onDeleteBlock = onDeletedBlocks[channelName] {
            DispatchQueue.main.async {
                onDeleteBlock(Attribute(key: roomId, value: ""))
            }
            return
        }
        if action == .subscribe {
            if let onUpdateBlock = onUpdatedBlocks[channelName], let propsUpdate = propsUpdate {
                let params = Utils.toDictionary(jsonString: propsUpdate)
                let attrs = params.map({ Attribute(key: $0.key, value: ($0.value as? String) ?? "") })
                DispatchQueue.main.async {
                    attrs.forEach({ onUpdateBlock($0) })
                }
            }
            if let onDeleteBlock = onDeletedBlocks[channelName], realAction == .deleteProp  {
                if objects?.isEmpty ?? false {
                    DispatchQueue.main.async {
                        onDeleteBlock(Attribute(key: propsDel?.first ?? "", value: ""))
                    }
                    return
                }
                propsDel?.forEach({
                    let attr = Attribute(key: $0, value: "")
                    DispatchQueue.main.async {
                        onDeleteBlock(attr)
                    }
                })
            }
        } else {
            if let successBlock = onSuccessBlock[channelName], action == .query || action == .getRoomList {
                DispatchQueue.main.async {
                    successBlock(attrs ?? [])
                }
            }
            if let successBlockVoid = onSuccessBlockVoid[channelName], action == .query, realAction != .deleteProp {
                DispatchQueue.main.async {
                    successBlockVoid()
                }
            }
            if let successBlockObjVoid = onSuccessBlockObjOptional[channelName], action == .query {
                DispatchQueue.main.async {
                    successBlockObjVoid(attrs?.first)
                }
            }
            if let deleteBlock = onDeleteBlockObjOptional[channelName], action == .deleteProp {
                DispatchQueue.main.async {
                    deleteBlock?(attrs?.first)
                }
            }
        }
        
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        Log.errorText(text: error.localizedDescription, tag: "error")
        notNetworkingHandler()
        if state != webSocket.readyState {
            DispatchQueue.main.async { [weak self] in
                self?.connectStateBlock?(.fail)
            }
        }
        state = webSocket.readyState
    }
    
    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        Log.warning(text: "socket closed == \(reason ?? "")", tag: "closed")
        notNetworkingHandler()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.state != webSocket.readyState {
                self.connectStateBlock?(.closed)
            }
            self.reConnect()
        }
        state = webSocket.readyState
    }
}
