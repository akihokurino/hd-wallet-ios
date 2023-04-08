import ComposableArchitecture
import SwiftUI

@main
struct HDWalletApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    let store: Store<RootApp.State, RootApp.Action> = Store(
        initialState: RootApp.State(),
        reducer: RootApp.reducer,
        environment: RootApp.Environment(
            mainQueue: .main,
            backgroundQueue: .init(DispatchQueue.global(qos: .background))
        )
    )

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
}
