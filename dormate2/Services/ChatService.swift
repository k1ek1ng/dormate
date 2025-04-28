import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ChatService: ObservableObject {
    private let db = Firestore.firestore()
    private let messagingService: MessagingService
    @Published var chats: [Chat] = []
    var currentUserId: String
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        self.messagingService = MessagingService.shared
        listenToChats()
    }
    
    func createChat(with user: User) async throws -> String {
        let chatData: [String: Any] = [
            "participantIds": [currentUserId, user.id],
            "lastMessage": "",
            "lastMessageTimestamp": Date(),
            "unreadCount": 0
        ]
        
        let chatRef = try await db.collection("chats").addDocument(data: chatData)
        return chatRef.documentID
    }
    
    private func listenToChats() {
        db.collection("chats")
            .whereField("participantIds", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.chats = documents.compactMap { document in
                    Chat(document: document)
                }
            }
    }
    
    func sendMessage(_ content: String, to chatId: String) async throws {
        let messageData: [String: Any] = [
            "content": content,
            "senderId": currentUserId,
            "chatId": chatId,
            "timestamp": Date(),
            "isRead": false
        ]
        
        // Add message to messages subcollection
        try await db.collection("chats").document(chatId)
            .collection("messages").addDocument(data: messageData)
        
        // Update chat's last message
        try await db.collection("chats").document(chatId)
            .updateData([
                "lastMessage": content,
                "lastMessageTimestamp": Date(),
                "unreadCount": FieldValue.increment(Int64(1))
            ])
    }
    
    func loadMessages(for chatId: String) async throws -> [Message] {
        let snapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Message(document: document)
        }
    }
    
    public func loadChats() async throws -> [Chat] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let snapshot = try await db.collection("chats")
            .whereField("participantIds", arrayContains: currentUserId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            guard let chat = Chat(document: document) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse chat document"])
            }
            return chat
        }
    }
} 