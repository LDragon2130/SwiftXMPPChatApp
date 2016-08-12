//
//  LoginHandler.swift
//  XMPP Chatting
//
//  LoginHandler.swift
//  XMPP Chatting
//
//  Created by Victor Belenko on 2/23/16.
//  Copyright © 2016 tutacode. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import SDWebImage
import XMPPFramework

class LoginHandler {
    
    struct Constants {
        static let facebookNameKey = "xmpp.chatting.facebookName"
        
        static let userIdKey = "xmpp.chatting.userId"
        static let passwordKey = "xmpp.chatting.password"
        
        static let updatedUserInfoKey = "xmpp.updatedUserInfo"
        
    
    }
    
    static let sharedInstance: LoginHandler = {
        return LoginHandler()
    }()
    
    var username: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setObject(self.username, forKey: Constants.facebookNameKey)
        }
        
    }
    
    var userId: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setObject(userId, forKey: Constants.userIdKey)
        }
    }
    var password: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setObject(password, forKey: Constants.passwordKey)
        }
    }
    
    func isLoggedIn()-> Bool {
        if userId != nil && password != nil {
            return true
        }
        return false
    }
    
    init() {
        userId = NSUserDefaults.standardUserDefaults().objectForKey(Constants.userIdKey) as? String
        password = NSUserDefaults.standardUserDefaults().objectForKey(Constants.passwordKey) as? String
        
    }
    
    func startLoggingInWithFacebook(completion completion: (success: Bool, error: NSError?)->Void) {
        
        // fetch facebook user info
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email,id,name"])
        request.startWithCompletionHandler { (connection, result, error) -> Void in
            if let userData = result as? [String: AnyObject]{
                
                let name = userData["name"] as! String
                
                if let facebookID = userData["id"] as? String {
                    self.username = name
                    self.userId = facebookID + "@xmpp.pb.pathoz.com"
                    self.password = facebookID
                    completion(success: true, error: nil)
                    
                }
                
            } else {
                completion(success: false, error: error)
            }
        }
        
    }
    
    func updateUserInforIfNeeded() {
        if NSUserDefaults.standardUserDefaults().boolForKey(Constants.updatedUserInfoKey) == false {
            // not yet updated
            if let fbId = NSUserDefaults.standardUserDefaults().objectForKey(Constants.passwordKey) as? String {
                let profilePic = "https://graph.facebook.com/" + fbId + "/picture?type=large&return_ssl_resources=1"
                if let name = NSUserDefaults.standardUserDefaults().objectForKey(Constants.facebookNameKey) as? String {
                    // update 
                    let pictureUrl = NSURL(string: profilePic)
                    SDWebImageDownloader.sharedDownloader().downloadImageWithURL(pictureUrl!, options: [], progress: nil, completed: { (image, data, error, finished) -> Void in
                        if data != nil {
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Constants.updatedUserInfoKey)
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                if let module = OneChat.sharedInstance.xmppvCardTempModule {
                                    
                                    if let myVcardTemp = module.myvCardTemp {
                                        myVcardTemp.nickname = name
                                        myVcardTemp.setName(name)
                                        myVcardTemp.photo = data
                                        module.updateMyvCardTemp(myVcardTemp)
                                    } else {
                                        let vCardXML = DDXMLElement(name: "vCard", xmlns: "vcard-temp")
                                        let newCardTemp = XMPPvCardTemp(fromElement: vCardXML)
                                        newCardTemp.nickname = name
                                        newCardTemp.setName(name)
                                        newCardTemp.photo = data
                                        module.updateMyvCardTemp(newCardTemp)
                                    }
                                    
                                }
                                
                            })
                            
                        } else {
                            print("download fb image failed")
                        }
                    })
                }
            }
        }
        
        
    }
    /*
    func updateUserInforByFacebookAccount() {
        
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email,id,name"])
        request.startWithCompletionHandler { (connection, result, error) -> Void in
            if let userData = result as? [String: AnyObject]{
                
                let name = userData["name"] as! String
                
                if let facebookID = userData["id"] {
                    let url = "https://graph.facebook.com/" + String(facebookID) + "/picture?type=normal&return_ssl_resources=1"
                    let pictureUrl = NSURL(string: url)
                    SDWebImageDownloader.sharedDownloader().downloadImageWithURL(pictureUrl!, options: [], progress: nil, completed: { (image, data, error, finished) -> Void in
                        if data != nil {
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                if let module = OneChat.sharedInstance.xmppvCardTempModule {
                                    let myVcardTemp = module.myvCardTemp
                                    myVcardTemp.nickname = name
                                    myVcardTemp.photo = data
                                    module.updateMyvCardTemp(myVcardTemp)
                                }
                                
                            })
                            
                        } else {
                            print("download fb image failed")
                        }
                    })
                }
                
            }
        }
    }
*/
    
    func logout() {
        self.userId = nil
        self.password = nil
    }
}
