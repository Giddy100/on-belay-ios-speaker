import Foundation
import FirebaseMessaging
import FirebaseFunctions
import FirebaseAuth
import FirebaseCore
import Combine
import GoogleSignIn

class FirebaseService: NSObject, ObservableObject {
    static let shared = FirebaseService()

    private lazy var functions = Functions.functions()

    @Published var currentUser: FirebaseAuth.User?
    @Published var userSettings: UserSettings?
    @Published var userGroups: [Group] = []
    @Published var fcmToken: String?

    private override init() {
        super.init()
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if user != nil {
                self?.refreshUserData()
            }
        }
        Messaging.messaging().delegate = self
    }

    func refreshUserData() {
        Task {
            await fetchUserSettings()
            await fetchUserGroups()
            if let token = fcmToken {
                await updateTokenOnServer(token)
            }
        }
    }

    // Auth
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            userSettings = nil
            userGroups = []
        } catch {
            print("Error signing out: \(error)")
        }
    }

    // Functions
    @MainActor
    func fetchUserSettings() async {
        do {
            let result = try await functions.httpsCallable("getUserSettings").call()
            if let data = result.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                self.userSettings = try JSONDecoder().decode(UserSettings.self, from: jsonData)
            }
        } catch {
            print("Error fetching user settings: \(error)")
        }
    }

    @MainActor
    func fetchUserGroups() async {
        do {
            let result = try await functions.httpsCallable("getUserGroups").call()
            if let data = result.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                self.userGroups = try JSONDecoder().decode([Group].self, from: jsonData)
            }
        } catch {
            print("Error fetching user groups: \(error)")
        }
    }

    func setUserSettings(_ settings: [String: Any]) async {
        do {
            _ = try await functions.httpsCallable("setUserSettings").call(settings)
            await fetchUserSettings()
        } catch {
            print("Error setting user settings: \(error)")
        }
    }

    func updateTokenOnServer(_ token: String) async {
        await setUserSettings(["tokenId": token])
    }
}

extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        self.fcmToken = fcmToken
        if currentUser != nil, let token = fcmToken {
            Task {
                await updateTokenOnServer(token)
            }
        }
    }
}
