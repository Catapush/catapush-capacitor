import Foundation
import CoreServices
import Capacitor
import catapush_ios_sdk_pod

@objc(CatapushPlugin)
public class CatapushPlugin: CAPPlugin, MessageDispatchSendResult, MessageDispatchReceivedResult, StateDispatchSendResult {
    var catapushDelegate: CatapushDelegateClass?
    var messagesDispatcherDelegate: MessagesDispatchDelegateClass?
    var messageDelegateCall: CAPPluginCall?
    var stateDelegateCall: CAPPluginCall?
    
    @objc
    public func enableLog(_ call: CAPPluginCall) {
        guard let enabled = call.getBool("enabled") else {
            return
        }
        Catapush.enableLog(enabled)
    }
    
    @objc(`init`:)
    public func `init`(_ call: CAPPluginCall) {
        guard let appKey = call.getString("appId") else {
            return
        }
        UserDefaults.init(suiteName: (Bundle.main.object(forInfoDictionaryKey: "Catapush") as! (Dictionary<String,String>))["AppGroup"])?.setValue("capacitor", forKey: "KCatapushLibraryPlugin");
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        Catapush.setAppKey(appKey)
        catapushDelegate = CatapushDelegateClass(channel: self)
        messagesDispatcherDelegate = MessagesDispatchDelegateClass(channel: self)
        Catapush.setupCatapushStateDelegate(catapushDelegate, andMessagesDispatcherDelegate: messagesDispatcherDelegate)
        DispatchQueue.main.async {
            Catapush.registerUserNotification(UIApplication.shared.delegate as! UIResponder)
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    @objc public func applicationDidBecomeActive(_ application: UIApplication) {
        Catapush.applicationDidBecomeActive(application)
    }
    
    @objc public func applicationWillTerminate(_ application: UIApplication) {
        Catapush.applicationWillTerminate(application)
    }
    
    @objc public func applicationDidEnterBackground(_ application: UIApplication) {
        Catapush.applicationDidEnterBackground(application)
    }
    
    @objc public func applicationWillEnterForeground(_ application: UIApplication) {
        var error: NSError?
        Catapush.applicationWillEnterForeground(application, withError: &error)
        if let error = error {
            // Handle error...
            print("Error: \(error.localizedDescription)")
        }
    }
    
    @objc(setUser:)
    func setUser(_ call: CAPPluginCall) {
        guard let identifier = call.getString("identifier"),
            let password = call.getString("password") else {
            return
        }
        Catapush.setIdentifier(identifier, andPassword: password)
    }
    
    func messageDispatchSendResult(result: PluginCallResultData) {
        notifyListeners("Catapush#catapushMessageSent", data: result)
    }
    
    func messageDispatchReceivedResult(result: PluginCallResultData) {
        notifyListeners("Catapush#catapushMessageReceived", data: result)
    }
    
    func stateDispatchSendResult(result: PluginCallResultData) {
        notifyListeners("Catapush#catapushMessageReceived", data: result)
    }
    
    public static func formatMessageID(message: MessageIP) -> Dictionary<String, Any?>{
        let formatter = ISO8601DateFormatter()
        
        return [
            "messageId": message.messageId,
            "body": message.body,
            "sender": message.sender,
            "channel": message.channel,
            "optionalData": message.optionalData(),
            "replyToId": message.originalMessageId,
            "state": getStateForMessage(message: message),
            "sentTime": formatter.string(from: message.sentTime),
            "hasAttachment": message.hasMedia()
        ];
    }
    
    public static func getStateForMessage(message: MessageIP) -> String{
        if message.type.intValue == MESSAGEIP_TYPE.MessageIP_TYPE_INCOMING.rawValue {
            if message.status.intValue == MESSAGEIP_STATUS.MessageIP_READ.rawValue{
                return "RECEIVED_CONFIRMED"
            }
            return "RECEIVED"
        }else{
            return "SENT"
        }
    }
    
    @objc(start:)
    func start(_ call: CAPPluginCall) {
        var error: NSError?
        Catapush.start(&error)
        if let error = error {
            call.reject(error.description, nil, error)
        } else {
            call.resolve()
        }
    }
    
    @objc(allMessages:)
    func allMessages(_ call: CAPPluginCall) {
        let result = (Catapush.allMessages() as! [MessageIP]).map {
            return CatapushPlugin.formatMessageID(message: $0)
        }
        call.resolve(["messages" : result])
    }
    
    @objc(sendMessage:)
    func sendMessage(_ call: CAPPluginCall) {
        let text = call.getString("body")
        let channel = call.getString("channel")
        let replyTo = call.getString("replyTo")
        let file = call.getObject("file")
        let message: MessageIP?
        if let file = file, let url = file["url"] as? String, let mimeType = file["mimeType"] as? String, FileManager.default.fileExists(atPath: url){
            let data = FileManager.default.contents(atPath: url)
            if let channel = channel {
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType)
                }
            }else{
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType)
                }
            }
        }else{
            if let channel = channel {
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andChannel: channel, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andChannel: channel)
                }
            }else{
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text)
                }
            }
        }
        guard let message = message else {
            call.reject("invalid argument")
            return
        }
        let result = [
            "message": CatapushPlugin.formatMessageID(message: message)
        ] as [String : Any]
        messageDispatchSendResult(result: result)
        call.resolve(CatapushPlugin.formatMessageID(message: message) as PluginCallResultData)
    }
    
    @objc(sendMessageReadNotificationWithId:)
    func sendMessageReadNotificationWithId(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Bad argument")
            return
        }
        MessageIP.sendMessageReadNotification(withId: id)
        call.resolve()
    }
    
    @objc(getAttachmentUrlForMessage:)
    func getAttachmentUrlForMessage(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Bad argument")
            return
        }
        
        let predicate = NSPredicate(format: "messageId = %@", id)
        let matches = Catapush.messages(with: predicate)
        if matches.count > 0 {
            let messageIP = matches.first! as! MessageIP
            if messageIP.hasMedia() {
                if messageIP.mm != nil {
                    guard let mime = messageIP.mmType,
                          let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                          let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                              return
                          }
                    let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                    let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId).\(ext.takeRetainedValue())")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: filePath.path) {
                        call.resolve(["url": filePath.path, "mimeType": messageIP.mmType ?? ""])
                    }
                    do {
                        try messageIP.mm!.write(to: filePath)
                        call.resolve(["url": filePath.path, "mimeType": messageIP.mmType ?? ""])
                    } catch {
                        call.reject(error.localizedDescription)
                    }
                }else{
                    messageIP.downloadMedia { (error, data) in
                        if(error != nil){
                            call.reject(error!.localizedDescription)
                        }else{
                            let predicate = NSPredicate(format: "messageId = %@", id)
                            let matches = Catapush.messages(with: predicate)
                            if matches.count > 0 {
                                let messageIP = matches.first! as! MessageIP
                                if messageIP.hasMedia() {
                                    if messageIP.mm != nil {
                                        guard let mime = messageIP.mmType,
                                              let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                                              let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                                                  return
                                              }
                                        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                                        let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId).\(ext.takeRetainedValue())")
                                        let fileManager = FileManager.default
                                        if fileManager.fileExists(atPath: filePath.path) {
                                            call.resolve(["url": filePath.path])
                                        }
                                        do {
                                            try messageIP.mm!.write(to: filePath)
                                            call.resolve(["url": filePath.path, "mimeType": messageIP.mmType ?? ""])
                                        } catch {
                                            call.reject(error.localizedDescription)
                                        }
                                    }else{
                                        call.resolve(["url": ""])
                                    }
                                    return
                                }else{
                                    call.resolve(["url": ""])
                                }
                            }else{
                                call.resolve(["url": ""])
                            }
                        }
                    }
                }
                return
            }else{
                call.resolve(["url": ""])
            }
        }else{
            call.resolve(["url": ""])
        }
    }
    
    @objc(pauseNotifications:)
    func pauseNotifications(_ call: CAPPluginCall) { }
    
    class CatapushDelegateClass : NSObject, CatapushDelegate {
        let channel: StateDispatchSendResult
        
        init(channel: StateDispatchSendResult) {
            self.channel = channel
        }
        
        let LONG_DELAY =  300
        let SHORT_DELAY = 30
        
        func catapushDidConnectSuccessfully(_ catapush: Catapush) {
            
        }
        
        func catapush(_ catapush: Catapush!, didFailOperation operationName: String!, withError error: Error!) {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            if domain == CATAPUSH_ERROR_DOMAIN {
                switch code {
                case CatapushErrorCode.INVALID_APP_KEY.rawValue:
                    /*
                     Check the app id and retry.
                     [Catapush setAppKey:@"YOUR_APP_KEY"];
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "INVALID_APP_KEY",
                        "code": CatapushErrorCode.INVALID_APP_KEY.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.USER_NOT_FOUND.rawValue:
                    /*
                     Please check if you have provided a valid username and password to Catapush via this method:
                     [Catapush setIdentifier:username andPassword:password];
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "USER_NOT_FOUND",
                        "code": CatapushErrorCode.USER_NOT_FOUND.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.WRONG_AUTHENTICATION.rawValue:
                    /*
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "WRONG_AUTHENTICATION",
                        "code": CatapushErrorCode.WRONG_AUTHENTICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.GENERIC.rawValue:
                    /*
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue:
                    /*
                     The same user identifier has been logged on another device, the messaging service will be stopped on this device
                     Please check that you are using a unique identifier for each device, even on devices owned by the same user.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "XMPP_MULTIPLE_LOGIN",
                        "code": CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.API_UNAUTHORIZED.rawValue:
                    /*
                     The credentials has been rejected    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "API_UNAUTHORIZED",
                        "code": CatapushErrorCode.API_UNAUTHORIZED.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.API_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service
                     
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Wrong auth    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_FORBIDDEN_WRONG_AUTH",
                        "code": CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_NOT_FOUND_APPLICATION",
                        "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     The user has been probably deleted from the Catapush app (via API or from the dashboard).
                     You should not keep retrying.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_NOT_FOUND_USER",
                        "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.REGISTRATION_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_CLIENT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_GRANT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue:
                    /*
                     Application error
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_USER",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service when updating the push token.
                     
                     Nothing, it's handled automatically by the sdk.
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.NETWORK_ERROR.rawValue:
                    /*
                     The SDK couldn’t establish a connection to the Catapush remote messaging service.
                     
                     The device is not connected to the internet or it might be blocked by a firewall or the remote messaging service might be temporarily disrupted.    Please check your internet connection and try to reconnect again.
                     */
                    self.retry(delayInSeconds: SHORT_DELAY);
                    break;
                case CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue:
                    /*
                     Push token is not available.
                     
                     Nothing, it's handled automatically by the sdk.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "PUSH_TOKEN_UNAVAILABLE",
                        "code": CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: result)
                    break;
                default:
                    break;
                }
            }
        }
        
        func retry(delayInSeconds:Int) {
            let deadlineTime = DispatchTime.now() + .seconds(delayInSeconds)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                var error: NSError?
                Catapush.start(&error)
                if error != nil {
                    // API KEY, USERNAME or PASSWORD not set
                }
            }
        }
    }
    
    class MessagesDispatchDelegateClass: NSObject, MessagesDispatchDelegate{
        let channel: MessageDispatchReceivedResult
        
        init(channel: MessageDispatchReceivedResult) {
            self.channel = channel
        }
        
        func libraryDidReceive(_ messageIP: MessageIP!) {
            let result = [
                "message": CatapushPlugin.formatMessageID(message: messageIP)
            ] as [String : Any]
            channel.messageDispatchReceivedResult(result: result)
        }
    }
}

protocol MessageDispatchSendResult {
    func messageDispatchSendResult(result: PluginCallResultData)
}

protocol MessageDispatchReceivedResult {
    func messageDispatchReceivedResult(result: PluginCallResultData)
}

protocol StateDispatchSendResult {
    func stateDispatchSendResult(result: PluginCallResultData)
}

extension CatapushPlugin: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let ud = UserDefaults.init(suiteName: (Bundle.main.object(forInfoDictionaryKey: "Catapush") as! (Dictionary<String,String>))["AppGroup"])
        let pendingMessages : Dictionary<String, String>? = ud!.object(forKey: "pendingMessages") as? Dictionary<String, String>;
        if (pendingMessages != nil && pendingMessages![response.notification.request.identifier] != nil) {
            let id: String = String(pendingMessages![response.notification.request.identifier]!.split(separator: "_").first ?? "")
            let predicate = NSPredicate(format: "messageId == %@", id)
            let matches = Catapush.messages(with: predicate)
            if matches.count > 0, let messageIP = matches.first as? MessageIP {
                let result = [
                    "message": CatapushPlugin.formatMessageID(message: messageIP)
                ] as [String : Any]
                notifyListeners("Catapush#catapushNotificationTapped", data: result)
                var newPendingMessages: Dictionary<String, String>?
                if (pendingMessages == nil) {
                    newPendingMessages = Dictionary()
                }else{
                    newPendingMessages = pendingMessages!
                }
                newPendingMessages![response.notification.request.identifier] = nil;
                ud!.setValue(newPendingMessages, forKey: "pendingMessages")
            }
        }
        completionHandler();
    }
}
