//
//  Macros.swift
//  UserAudioApp_0608
//
//  Created by Sibtain Ali on 15-06-2023.
//

import Foundation
import SwiftUI

var rootVC: UIViewController? {
    UIApplication.shared.keyWindowCustom?.rootViewController
}


func customAlertApple(title: String,
                      message: String,
                      yesButtonTitle: String = "Yes",
                      noButtonTitle: String = "No",
                      showDestructive: Bool = false,
                      completion: ((_ success: Bool) -> Void)? = nil) {

    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

    let yesAction = UIAlertAction(title: yesButtonTitle, style: .default, handler: { (alert) in
        completion?(true)
    })

    let cancelOption = UIAlertAction(title: noButtonTitle, style: .destructive, handler: { (alert) in
        completion?(false)
    })

    alertController.addAction(yesAction)
    if showDestructive { alertController.addAction(cancelOption) }
    alertController.modalPresentationStyle = .overFullScreen

    var vc = rootVC
    if let tempVC = vc?.presentedViewController { vc = tempVC }
    vc?.present(alertController, animated: true, completion: nil)

}


extension UIApplication {
    
    var keyWindowCustom: UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil}
        guard let window = windowScene.windows.first else { return nil}
        return window
    }
    
}
