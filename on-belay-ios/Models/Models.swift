import Foundation

struct Phrase: Codable, Identifiable, Hashable {
    var id: String { phraseId }
    let phraseId: String
    let name: String
    let prompt: String
    var selected: Bool
    let soundFileName: String
    let utterances: [String]

    enum CodingKeys: String, CodingKey {
        case phraseId, name, prompt, selected, soundFileName, utterances
    }
}

struct User: Codable, Identifiable, Hashable {
    var id: String { uid }
    let uid: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case uid = "userId", name
    }
}

struct Group: Codable, Identifiable, Hashable {
    var id: String { groupId }
    let groupId: String
    var name: String
    var code: String?
    var startDate: TimeInterval?
    var endDate: TimeInterval?
    var phrases: [Phrase]?
    let createdByUid: String?
    let createdByName: String
    var joinedUsers: [User]?

    var startAsDate: Date { Date(timeIntervalSince1970: (startDate ?? 0) / 1000) }
    var endAsDate: Date { Date(timeIntervalSince1970: (endDate ?? 0) / 1000) }

    // For search results which only have groupId, name, createdByName
    init(groupId: String, name: String, createdByName: String, code: String?, startDate: TimeInterval?, endDate: TimeInterval?, phrases: [Phrase]?, createdByUid: String?, joinedUsers: [User]?) {
        self.groupId = groupId
        self.name = name
        self.createdByName = createdByName
        self.code = code
        self.startDate = startDate
        self.endDate = endDate
        self.phrases = phrases
        self.createdByUid = createdByUid
        self.joinedUsers = joinedUsers
    }

    // For search results which only have groupId, name, createdByName
    init(groupId: String, name: String, createdByName: String) {
        self.groupId = groupId
        self.name = name
        self.createdByName = createdByName
        self.code = nil
        self.startDate = nil
        self.endDate = nil
        self.phrases = nil
        self.createdByUid = nil
        self.joinedUsers = nil
    }
}

struct UserSettings: Codable {
    var name: String
    var selectedGroupId: String?
    var isActive: Bool
    var wakeupPhrase: String
    var volume: Double?
    var tokenId: String?
}
