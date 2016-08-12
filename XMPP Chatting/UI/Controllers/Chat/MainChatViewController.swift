//
//  MainChatViewController.swift
//  XMPP Chatting
//
//  Created by Victor Belenko on 2/27/16.
//  Copyright © 2016 tutacode. All rights reserved.
//

import UIKit
import Chatto
import ChattoAdditions
import XMPPFramework

class MainChatViewController: ChatViewController {

    var recipient: XMPPUserCoreDataStorageObject?
    var userDetails = UIView?()
    
    var messageSender: FakeMessageSender!
    var dataSource: FakeDataSource! {
        didSet {
            self.chatDataSource = self.dataSource
        }
    }
    
    lazy private var baseMessageHandler: BaseMessageHandler = {
        return BaseMessageHandler(messageSender: self.messageSender)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.chatItemsDecorator = ChatItemsDemoDecorator()
        OneMessage.sharedInstance.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let recipient = recipient {
            self.navigationItem.rightBarButtonItems = []
            
            navigationItem.title = recipient.displayName
            
            // Mark: Adding LastActivity functionality to NavigationBar
            OneLastActivity.sendLastActivityQueryToJID((recipient.jidStr), sender: OneChat.sharedInstance.xmppLastActivity) { (response, forJID, error) -> Void in
                let lastActivityResponse = OneLastActivity.sharedInstance.getLastActivityFrom((response?.lastActivitySeconds())!)
                
                self.userDetails = OneLastActivity.sharedInstance.addLastActivityLabelToNavigationBar(lastActivityResponse, displayName: recipient.displayName)
                self.navigationItem.titleView = self.userDetails

            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                OneMessage.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr)
                
            })
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        userDetails?.removeFromSuperview()
    }
    
    var chatInputPresenter: ChatInputBarPresenter!
    override func createChatInputView() -> UIView {
        let chatInputView = ChatInputBar.loadNib()
        self.configureChatInputBar(chatInputView)
        self.chatInputPresenter = ChatInputBarPresenter(chatInputView: chatInputView, chatInputItems: self.createChatInputItems())
        return chatInputView
    }
    
    func configureChatInputBar(chatInputBar: ChatInputBar) {
        var appearance = ChatInputBarAppearance()
        appearance.sendButtonTitle = NSLocalizedString("Send", comment: "")
        appearance.textPlaceholder = NSLocalizedString("Type a message", comment: "")
        chatInputBar.setAppearance(appearance)
    }
    
    override func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        return [
            TextMessageModel.chatItemType: [
                TextMessagePresenterBuilder(
                    viewModelBuilder: TextMessageViewModelDefaultBuilder(),
                    interactionHandler: TextMessageHandler(baseHandler: self.baseMessageHandler)
                )
            ],
            SubPhotoMessageModel.chatItemType: [
                PhotoMessagePresenterBuilder(
                    viewModelBuilder: FakePhotoMessageViewModelBuilder(),
                    interactionHandler: PhotoMessageHandler(baseHandler: self.baseMessageHandler)
                )
            ],
            SendingStatusModel.chatItemType: [SendingStatusPresenterBuilder()]
        ]
    }
    
    func createChatInputItems() -> [ChatInputItemProtocol] {
        var items = [ChatInputItemProtocol]()
        items.append(self.createTextInputItem())
        items.append(self.createPhotoInputItem())
        return items
    }
    
    private func createTextInputItem() -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { [weak self] text in
            self?.dataSource.addTextMessage(text)
        }
        return item
    }
    
    private func createPhotoInputItem() -> PhotosChatInputItem {
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { [weak self] image in
            self?.dataSource.addPhotoMessage(image)
        }
        return item
    }

}

extension MainChatViewController: OneMessageDelegate {
    func oneStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        if let msg: String = message.body() {
            
            if let from: String = message.attributeForName("from")?.stringValue() {
                if message.isChatMessageWithBody() {
                    //let displayName = user.displayName
                    
                    self.dataSource.receiveTextMessage(msg, from: from)
                } else {
                    let width = message.attributeFloatValueForName("width", withDefaultValue: 300)
                    let height = message.attributeFloatValueForName("height", withDefaultValue: 300)
                    self.dataSource.receiveImageMessage(msg, from: from, width: CGFloat(width), height: CGFloat(height))
                }
            }
        }
        
    }
    func oneStream(sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        
    }
}