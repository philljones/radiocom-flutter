import UIKit
import Flutter

class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene,
                        willConnectTo session: UISceneSession,
                        options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            (UIApplication.shared.delegate as? AppDelegate)?.handleWidgetURL(url)
        }
        if let shortcut = connectionOptions.shortcutItem {
            (UIApplication.shared.delegate as? AppDelegate)?.handleShortcut(shortcut)
        }
        if let windowScene = scene as? UIWindowScene,
           let app = UIApplication.shared.delegate as? AppDelegate {
            let radioWindow = UIWindow(windowScene: windowScene)
            radioWindow.rootViewController = FlutterViewController(engine: app.radioEngine, nibName: nil, bundle: nil)
            window = radioWindow
            radioWindow.makeKeyAndVisible()
        }
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    override func scene(_ scene: UIScene,
                        openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            (UIApplication.shared.delegate as? AppDelegate)?.handleWidgetURL(url)
        }
        super.scene(scene, openURLContexts: URLContexts)
    }

    override func windowScene(_ windowScene: UIWindowScene,
                              performActionFor shortcutItem: UIApplicationShortcutItem,
                              completionHandler: @escaping (Bool) -> Void) {
        let handled = (UIApplication.shared.delegate as? AppDelegate)?
            .handleShortcut(shortcutItem) ?? false
        completionHandler(handled)
    }
}
