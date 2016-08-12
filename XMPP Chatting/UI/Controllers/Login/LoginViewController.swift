//
//  LoginViewController.swift
//  XMPP Chatting
//
//  Created by Victor Belenko on 2/22/16.
//  Copyright © 2016 tutacode. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController {

    let handler = LoginHandler.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.flatPowderBlueColor()
        let loginButton = FBSDKLoginButton()
        loginButton.delegate = self
        loginButton.center = self.view.center
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        self.view.addSubview(loginButton)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}

extension LoginViewController: FBSDKLoginButtonDelegate {
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if let _ = error {
            // authentication failed
            showErrorNotification(description: "Login by Facebook failed.")
        } else if result.isCancelled {
            // user cancel authorization process
            showErrorNotification(description: "Please allow permissions to login")
        } else {
            // login success
            showHudOnView(self.view, title: "Signing in...")
            handler.startLoggingInWithFacebook(completion: { (success, error) -> Void in
                removeAllHudOnView(self.view)
                if success {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.didLoginSuccessfullyNotification, object: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    // call restful api failed, display error
                    
                }
            })
        }
    }
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
    }
}