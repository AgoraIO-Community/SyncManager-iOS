//
//  MainVC.swift
//  SyncManagerDemo
//
//  Created by ZYP on 2021/12/8.
//

import UIKit
import AgoraSyncManager
import AgoraRtmKit

class MainVC: UIViewController, AgoraRtmChannelDelegate {
    let sectionTitles = ["基础", "房间列表", "房间信息", "成员信息"]
    let list = [["初始化", "加入房间"],
                ["读取房间列表", "删除房间"],
                ["更新房间信息", "获取房间信息", "订阅房间信息更新事件", "取消订阅房间信息更新事件"],
                ["新增member", "更新member（无）", "删除member", "获取member列表", "订阅member更新事件(无)", "取消订阅memner更新事件(无)", "删除所有member"]]
    let tableView = UITableView(frame: .zero, style: .grouped)
    var syncManager: AgoraSyncManager!
    var syncRef: SceneReference!
    let channelName = "testDefaultScene"
    var memberObjId: String?
    var rtm: AgoraRtmKit!
    var channel: AgoraRtmChannel!
    var channel2: AgoraRtmChannel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        commonInit()
    }
    
    func setup() {
        if Config.appId.count == 0 { fatalError("must set an appId in Config.swift") }
        title = "SyncManager"
        view.addSubview(tableView)
        tableView.frame = view.bounds
    }
    
    func commonInit() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func handleTap(indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 { /** 初始化 **/
                initManager()
                return
            }
            
            if indexPath.row == 1 { /** 加入房间 **/
                joinScene()
                return
            }
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** 获取房间列表 **/
                getScenes()
                return
            }
            
            if indexPath.row == 1 { /** 删除房间 **/
                deleteScenes()
                return
            }
        }
        
        if indexPath.section == 2 {
            if indexPath.row == 0 { /** 更新房间信息 **/
                updteRoomInfo()
                return
            }
            
            if indexPath.row == 1 { /** 获取本房间信息 **/
                getRoomInfo()
                return
            }
            
            if indexPath.row == 2 { /** 订阅本房间信息更新事件 **/
                subscribeRoom()
                return
            }
            
            if indexPath.row == 3 { /** 取消订阅本房间信息更新事件 **/
                unsubscribeRoom()
                return
            }
        }
        
        if indexPath.section == 3 {
            if indexPath.row == 0 { /** 新增member **/
                addMember()
                return
            }
            
            if indexPath.row == 1 { /** 更新member **/
                return
            }
            
            if indexPath.row == 2 { /** 删除member **/
                deleteMember()
                return
            }
            
            if indexPath.row == 3 { /** 获取member列表 **/
                getMember()
                return
            }
            
            if indexPath.row == 4 { /** 订阅member更新事件 **/
                subscribeMember()
                return
            }
            
            if indexPath.row == 5 { /** 取消订阅memner更新事件 **/
                unsubscribeMember()
                return
            }
            
            if indexPath.row == 6 { /** 删除所有member **/
                deleteAllMemners()
                return
            }
        }
    }
}

extension MainVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = list[indexPath.section][indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleTap(indexPath: indexPath)
    }
}

