import Foundation
import FirebaseFirestore

@MainActor
public class MessagingService: ObservableObject {
    public static let shared = MessagingService()
    
    @Published public var chats: [Chat] = []
    @Published public var currentChat: Chat?
    @Published public var messages: [Message] = []
    @Published public var errorMessage: String?
    @Published public var isLoading = false
    
    private let db = Firestore.firestore()
    private var messageListener: ListenerRegistration?
    
    private init() {
        // Initialize with default values
    }
    
    deinit {
        messageListener?.remove()
    }
    
    public func createChat(with user: User, currentUserId: String) async throws -> Chat {
        let chat = Chat(
            participantIds: [currentUserId, user.id],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            unreadCount: 0,
            createdAt: Date()
        )
        let docRef = try await db.collection("chats").addDocument(data: chat.dictionary)
        let newChat = Chat(
            id: docRef.documentID,
            participantIds: chat.participantIds,
            lastMessage: chat.lastMessage,
            lastMessageTimestamp: chat.lastMessageTimestamp,
            unreadCount: chat.unreadCount,
            createdAt: chat.createdAt
        )
        chats.append(newChat)
        return newChat
    }
    
    public func sendMessage(to chatId: String, content: String, currentUserId: String) async throws {
        let message = Message(
            chatId: chatId,
            senderId: currentUserId,
            content: content,
            timestamp: Date(),
            isRead: false
        )
        
        // For real chats, update Firestore
        let messageRef = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: message.dictionary)
        
        try await db.collection("chats")
            .document(chatId)
            .updateData([
                "lastMessage": content,
                "lastMessageTimestamp": Timestamp(date: Date()),
                "unreadCount": FieldValue.increment(Int64(1))
            ])
    }
    
    public func loadChats(currentUserId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get user's matches first
            let userService = UserService()
            let currentUser = try await userService.fetchUser(userId: currentUserId)
            let matchedUserIds = currentUser?.matches ?? []
            
            // Only get chats with matched users from Firestore
            let snapshot = try await db.collection("chats")
                .whereField("participantIds", arrayContains: currentUserId)
                .order(by: "lastMessageTimestamp", descending: true)
                .getDocuments()
            
            // Filter chats to only include those with matched users
            let firestoreChats = snapshot.documents.compactMap { document -> Chat? in
                guard let chat = Chat(document: document) else { return nil }
                let otherUserId = chat.participantIds.first { $0 != currentUserId }
                guard let otherId = otherUserId, matchedUserIds.contains(otherId) else { return nil }
                return chat
            }
            
            self.chats = firestoreChats
            
        } catch let error as NSError {
            if error.domain == FirestoreErrorDomain && error.code == 9 {
                errorMessage = "Loading chats in default order while index is being created..."
                
                let snapshot = try await db.collection("chats")
                    .whereField("participantIds", arrayContains: currentUserId)
                    .getDocuments()
                
                let userService = UserService()
                let currentUser = try await userService.fetchUser(userId: currentUserId)
                let matchedUserIds = currentUser?.matches ?? []
                
                // Filter and sort chats in memory
                let firestoreChats = snapshot.documents
                    .compactMap { document -> Chat? in
                        guard let chat = Chat(document: document) else { return nil }
                        let otherUserId = chat.participantIds.first { $0 != currentUserId }
                        guard let otherId = otherUserId, matchedUserIds.contains(otherId) else { return nil }
                        return chat
                    }
                    .sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
                
                self.chats = firestoreChats
            } else {
                throw error
            }
        }
    }
    
    public func setupMessageListener(for chatId: String) {
        messageListener?.remove()
        messageListener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "❌ Error loading messages: \(error.localizedDescription)"
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.errorMessage = "❌ No messages found"
                    return
                }
                
                self.messages = snapshot.documents.compactMap { Message(document: $0) }
            }
    }
    
    public func loadMessages(for chatId: String) async throws {
        // For real chats, load from Firestore
        let querySnapshot = try await db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        messages = querySnapshot.documents.compactMap { Message(document: $0) }
    }
    
    public func markMessagesAsRead(for chatId: String, currentUserId: String) async throws {
        let snapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        for doc in snapshot.documents {
            try await doc.reference.updateData(["isRead": true])
        }
        
        try await db.collection("chats").document(chatId).updateData([
            "unreadCount": 0
        ])
    }
} 