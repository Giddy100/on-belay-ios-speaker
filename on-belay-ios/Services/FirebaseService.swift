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

    func createGroup(_ group: Group) async -> Bool {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(group)
            guard let groupDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return false
            }

            _ = try await functions.httpsCallable("setGroup").call(groupDict)
            await fetchUserGroups()
            return true
        } catch {
            print("Error creating group: \(error)")
            return false
        }
    }

    func updateGroup(_ group: Group) async -> Bool {
        return await createGroup(group) // setGroup handles both
    }

    func deleteGroup(groupId: String) async -> Bool {
        do {
            _ = try await functions.httpsCallable("deleteGroup").call(["groupId": groupId])
            await fetchUserGroups()
            return true
        } catch {
            print("Error deleting group: \(error)")
            return false
        }
    }

    func leaveGroup(groupId: String) async -> Bool {
        do {
            _ = try await functions.httpsCallable("leaveGroup").call(["groupId": groupId])
            await fetchUserGroups()
            return true
        } catch {
            print("Error leaving group: \(error)")
            return false
        }
    }

    func searchGroups(query: String) async -> [Group] {
        do {
            let result = try await functions.httpsCallable("searchGroups").call(["query": query])
            if let data = result.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                return try JSONDecoder().decode([Group].self, from: jsonData)
            }
        } catch {
            print("Error searching groups: \(error)")
        }
        return []
    }

    func joinGroup(groupId: String, code: String) async -> Bool {
        do {
            let result = try await functions.httpsCallable("joinGroup").call(["groupId": groupId, "code": code])
            if let data = result.data as? [String: Any], let success = data["success"] as? Bool {
                if success {
                    await fetchUserGroups()
                    await fetchUserSettings()
                }
                return success
            }
        } catch {
            print("Error joining group: \(error)")
        }
        return false
    }

    func getGroupMembers(groupId: String) async -> [GroupMember] {
        do {
            let result = try await functions.httpsCallable("getGroupMembers").call(["groupId": groupId])
            if let data = result.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                return try JSONDecoder().decode([GroupMember].self, from: jsonData)
            }
        } catch {
            print("Error getting group members: \(error)")
        }
        return []
    }

    func removeGroupMember(groupId: String, userId: String) async -> Bool {
        do {
            _ = try await functions.httpsCallable("removeGroupMember").call(["groupId": groupId, "userId": userId])
            return true
        } catch {
            print("Error removing group member: \(error)")
            return false
        }
    }

    func getGroupToJoin(groupId: String) async -> GroupToJoin? {
        do {
            let result = try await functions.httpsCallable("getGroupToJoin").call(["groupId": groupId])
            if let data = result.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                return try JSONDecoder().decode(GroupToJoin.self, from: jsonData)
            }
        } catch {
            print("Error getting group to join: \(error)")
        }
        return nil
    }

    func getDefaultPhrases() async -> [Phrase] {
        do {
            let result = try await functions.httpsCallable("getDefaultPhrases").call()
            if let data = result.data as? [String: Any], let phrasesData = data["phrases"] as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: phrasesData)
                return try JSONDecoder().decode([Phrase].self, from: jsonData)
            }
        } catch {
            print("Error getting default phrases: \(error)")
        }
        return []
    }

    func notifyGroupMembers(groupId: String, phraseId: String) async {
        do {
            _ = try await functions.httpsCallable("notifyGroupMembers").call(["groupId": groupId, "phraseId": phraseId])
        } catch {
            print("Error notifying group members: \(error)")
        }
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
