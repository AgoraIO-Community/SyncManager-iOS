//
//  MainVC+Show.swift
//  SyncManagerDemo
//
//  Created by ZYP on 2021/12/10.
//
import UIKit

extension UIViewController {
    func show(_ text: String) {
        if Thread.current.isMainThread {
//            self.view.makeToast(text, position: .center)
            return
        }
        DispatchQueue.main.sync { [unowned self] in
//            self.view.makeToast(text, position: .center)
        }
    }
}
