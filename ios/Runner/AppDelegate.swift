import UIKit
import Flutter
import AVFoundation
import CarPlay


@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

    private(set) var radioEngine: FlutterEngine!
    private var carPlayChannel: FlutterMethodChannel?
    private var carPlayReady = false
    private var pendingCarPlayStart: ((Bool) -> Void)?

    private let homeActionsChannelName = "uk.co.abergavennyradio/home_actions"
    private var homeActionsChannel: FlutterMethodChannel?
    private var pendingHomeAction: String?

    private func startRadioEngine() {
        guard radioEngine == nil else { return }
        radioEngine = FlutterEngine(name: "AberRadio", project: nil, allowHeadlessExecution: true)
        radioEngine.run()
        GeneratedPluginRegistrant.register(with: radioEngine)
        let registrar = radioEngine.registrar(forPlugin: "AberRadioHomeActions")!
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
        let carChannel = FlutterMethodChannel(name: "uk.co.abergavennyradio/carplay",
                                               binaryMessenger: radioEngine.binaryMessenger)
        carChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(nil); return }
            if call.method == "ready" {
                self.carPlayReady = true
                result(nil)
                if let pending = self.pendingCarPlayStart {
                    self.pendingCarPlayStart = nil
                    self.startCarPlayLive(completion: pending)
                }
            } else { result(FlutterMethodNotImplemented) }
        }
        carPlayChannel = carChannel
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
        startRadioEngine()
        return launchOptions?[.shortcutItem] == nil && launched
    }

    func startCarPlayLive(completion: @escaping (Bool) -> Void) {
        guard carPlayReady, let channel = carPlayChannel else {
            pendingCarPlayStart = completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let pending = self?.pendingCarPlayStart else { return }
                self?.pendingCarPlayStart = nil
                pending(false)
            }
            return
        }
        channel.invokeMethod("listenLive", arguments: nil) { result in
            completion(result as? Bool ?? false)
        }
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

/// Apple's templates own the car UI; audio_service owns transport controls and metadata.
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    private var controller: CPInterfaceController?
    private var starting = false

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        controller = interfaceController
        let live = CPListItem(text: "Listen Live", detailText: "Aber Radio")
        live.handler = { [weak self] _, completion in
            guard let self = self, !self.starting else { completion(); return }
            self.starting = true
            (UIApplication.shared.delegate as? AppDelegate)?.startCarPlayLive { [weak self] success in
                guard let self = self else { completion(); return }
                self.starting = false
                completion()
                guard let controller = self.controller else { return }
                if success {
                    controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                } else {
                    let retry = CPAlertAction(title: "OK", style: .default) { _ in
                        controller.dismissTemplate(animated: true, completion: nil)
                    }
                    controller.presentTemplate(CPAlertTemplate(titleVariants: ["Unable to connect. Please try again."], actions: [retry]),
                                               animated: true, completion: nil)
                }
            }
        }
        let nowPlaying = CPListItem(text: "Now Playing", detailText: "Playback controls")
        nowPlaying.handler = { [weak self] _, completion in
            self?.controller?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            completion()
        }
        let root = CPListTemplate(title: "Aber Radio", sections: [CPListSection(items: [live, nowPlaying])])
        interfaceController.setRootTemplate(root, animated: false, completion: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        controller = nil
        // Disconnecting the display must not stop the phone's audio player.
    }
}
