//
//  UIAlertControllerExtension.swift
//  NotificationSampleiOS10
//
//  Created by qitmac000260 on 16/9/22.
//  Copyright © 2016年 jinfeng.du. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func showConfirmAlert(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        viewController.present(alert, animated: true)
    }
    
    static func showConfirmAlertFromTopViewController(message: String) {
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            showConfirmAlert(message: message, in: vc)
        }
    }
}
