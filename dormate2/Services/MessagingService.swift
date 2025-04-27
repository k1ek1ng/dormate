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
    private var mockMessages: [String: [Message]] = [:] // Dictionary to store mock messages by chat ID
    
    private init() {
        // Initialize with default values
    }
    
    deinit {
        messageListener?.remove()
    }
    
    public func createChat(with user: User, currentUserId: String) async throws -> Chat {
        if user.id.hasPrefix("mock_") || currentUserId.hasPrefix("mock_") {
            // Create a mock chat
            let chatId = "mock_chat_\(UUID().uuidString)"
            let chat = Chat(
                id: chatId,
                participantIds: [currentUserId, user.id],
                lastMessage: "",
                lastMessageTimestamp: Date(),
                unreadCount: 0,
                createdAt: Date()
            )
            mockMessages[chatId] = []
            // Add the chat to the chats array
            chats.append(chat)
            return chat
        } else {
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
    }
    
    public func sendMessage(to chatId: String, content: String, currentUserId: String) async throws {
        let message = Message(
            chatId: chatId,
            senderId: currentUserId,
            content: content,
            timestamp: Date(),
            isRead: false
        )
        
        if chatId.hasPrefix("mock_chat_") {
            // For mock chats, store in local arrays
            if mockMessages[chatId] == nil {
                mockMessages[chatId] = []
            }
            mockMessages[chatId]?.append(message)
            messages.append(message)
            
            // Find and update the mock chat
            if let index = chats.firstIndex(where: { $0.id == chatId }) {
                var updatedChat = chats[index]
                updatedChat.lastMessage = content
                updatedChat.lastMessageTimestamp = Date()
                updatedChat.unreadCount += 1
                chats[index] = updatedChat
            }
            return
        }
        
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
        
        // Keep existing mock chats
        let existingMockChats = self.chats.filter { $0.id.hasPrefix("mock_chat_") }
        
        // If current user is a mock user or we're dealing with mock chats, just use those
        if currentUserId.hasPrefix("mock_") {
            self.chats = existingMockChats
            return
        }
        
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
            
            // Combine Firestore chats with mock chats
            self.chats = firestoreChats + existingMockChats
            
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
                
                // Combine Firestore chats with mock chats
                self.chats = firestoreChats + existingMockChats
            } else {
                throw error
            }
        }
    }
    
    public func setupMessageListener(for chatId: String) {
        // Only set up listeners for real chats
        if chatId.hasPrefix("mock_chat_") {
            return
        }
        
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
        if chatId.hasPrefix("mock_chat_") {
            messages = mockMessages[chatId] ?? []
            return
        }
        
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
    
    public func createMockMessages(for chatId: String, currentUserId: String, otherUserId: String) async throws {
        let mockMessages = [
            Message(
                chatId: chatId,
                senderId: currentUserId,
                content: "Hey! I saw we matched. I'm looking for a roommate in the same college.",
                timestamp: Date().addingTimeInterval(-3600 * 24), // 24 hours ago
                isRead: true
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                content: "Hi! Yes, I'm also looking for a roommate. I noticed we have similar living preferences!",
                timestamp: Date().addingTimeInterval(-3600 * 23), // 23 hours ago
                isRead: true
            ),
            Message(
                chatId: chatId,
                senderId: currentUserId,
                content: "That's great! I'm particularly interested in your thoughts about cleanliness and quiet hours for studying.",
                timestamp: Date().addingTimeInterval(-3600 * 22), // 22 hours ago
                isRead: true
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                content: "I'm very organized and prefer a quiet environment for studying. I usually study in the library or my room.",
                timestamp: Date().addingTimeInterval(-3600 * 21), // 21 hours ago
                isRead: false
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                content: "Would you like to meet up on campus to discuss more about potentially being roommates?",
                timestamp: Date().addingTimeInterval(-3600 * 20), // 20 hours ago
                isRead: false
            )
        ]
        
        // Add messages to Firestore
        for message in mockMessages {
            try await db.collection("chats")
                .document(chatId)
                .collection("messages")
                .addDocument(data: message.dictionary)
        }
        
        // Update chat's last message
        if let lastMessage = mockMessages.last {
            try await db.collection("chats")
                .document(chatId)
                .updateData([
                    "lastMessage": lastMessage.content,
                    "lastMessageTimestamp": Timestamp(date: lastMessage.timestamp),
                    "unreadCount": 2 // Last two messages are unread
                ])
        }
    }
} 