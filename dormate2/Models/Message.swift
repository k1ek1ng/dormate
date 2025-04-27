import Foundation
import FirebaseFirestore

public struct Message: Identifiable {
    public let id: String
    public let chatId: String
    public let senderId: String
    public let content: String
    public let timestamp: Date
    public let isRead: Bool
    
    public init(id: String = UUID().uuidString,
         chatId: String,
         senderId: String,
         content: String,
         timestamp: Date = Date(),
         isRead: Bool = false) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    public init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let chatId = data["chatId"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let isRead = data["isRead"] as? Bool else {
            return nil
        }
        
        self.id = document.documentID
        self.chatId = chatId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp.dateValue()
        self.isRead = isRead
    }
    
    public var dictionary: [String: Any] {
        return [
            "chatId": chatId,
            "senderId": senderId,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
    }
} 