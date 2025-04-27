import Foundation
import FirebaseFirestore

public struct Chat: Identifiable {
    public let id: String
    public let participantIds: [String]
    public var lastMessage: String
    public var lastMessageTimestamp: Date
    public var unreadCount: Int
    public let createdAt: Date
    public var otherUser: User?
    
    public init(id: String = UUID().uuidString,
         participantIds: [String],
         lastMessage: String,
         lastMessageTimestamp: Date = Date(),
         unreadCount: Int = 0,
         createdAt: Date = Date(),
         otherUser: User? = nil) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.createdAt = createdAt
        self.otherUser = otherUser
    }
    
    public init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let participantIds = data["participantIds"] as? [String],
              let lastMessage = data["lastMessage"] as? String,
              let timestamp = data["lastMessageTimestamp"] as? Timestamp,
              let unreadCount = data["unreadCount"] as? Int else {
            return nil
        }
        
        self.id = document.documentID
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = timestamp.dateValue()
        self.unreadCount = unreadCount
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.otherUser = nil
    }
    
    public var dictionary: [String: Any] {
        return [
            "participantIds": participantIds,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": Timestamp(date: lastMessageTimestamp),
            "unreadCount": unreadCount,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
} 