import UIKit
import Flutter
import AVFoundation


@UIApplicationMain
class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private let homeActionsChannelName = "uk.co.abergavennyradio/home_actions"
    private var homeActionsChannel: FlutterMethodChannel?
    private var pendingHomeAction: String?

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        guard let registrar = engineBridge.pluginRegistry.registrar(
            forPlugin: "AberRadioHomeActions"
        ) else { return }
        let channel = FlutterMethodChannel(
            name: homeActionsChannelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getInitialAction":
                result(self?.pendingHomeAction)
            case "clearPendingAction":
                if let handledAction = call.arguments as? String,
                   self?.pendingHomeAction == handledAction {
                    self?.pendingHomeAction = nil
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        homeActionsChannel = channel
    }
    
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            _ = handleShortcut(shortcut)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

       //set audio session to be on background always
        application.beginReceivingRemoteControlEvents()
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers,.allowBluetooth,.allowAirPlay,.allowBluetoothA2DP])
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers,.allowBluetooth])
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        return launchOptions?[.shortcutItem] == nil && launched
    }

    override func application(_ application: UIApplication,
                              performActionFor shortcutItem: UIApplicationShortcutItem,
                              completionHandler: @escaping (Bool) -> Void) {
        guard let action = action(for: shortcutItem.type) else {
            completionHandler(false)
            return
        }
        deliver(action)
        completionHandler(true)
    }

    @discardableResult
    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = action(for: shortcutItem.type) else { return false }
        deliver(action)
        return true
    }

    func handleWidgetURL(_ url: URL) {
        guard url.scheme == "aberradio", let host = url.host else { return }
        let actions = [
            "listen-live": "listenLive",
            "schedule": "schedule",
            "favourites": "favourites"
        ]
        if let action = actions[host] { deliver(action) }
    }

    private func action(for shortcutType: String) -> String? {
        switch shortcutType {
        case "uk.co.abergavennyradio.app.listenLive": return "listenLive"
        case "uk.co.abergavennyradio.app.schedule": return "schedule"
        case "uk.co.abergavennyradio.app.favourites": return "favourites"
        default: return nil
        }
    }

    private func deliver(_ action: String) {
        pendingHomeAction = action
        if let channel = homeActionsChannel {
            channel.invokeMethod("homeAction", arguments: action)
        }
    }
}
