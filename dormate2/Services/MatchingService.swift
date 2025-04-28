import Foundation
import FirebaseFirestore
import FirebaseCore

@MainActor
class MatchingService: ObservableObject {
    @Published var currentUser: User
    private let chatService: ChatService
    @Published var potentialMatches: [User] = []
    @Published var matches: [User] = []
    @Published var matchedByUsers: [User] = []
    private var rejectedUsers: Set<String> = []
    
    init(currentUser: User) {
        self.currentUser = currentUser
        self.chatService = ChatService(currentUserId: currentUser.id)
    }
    
    // MARK: - Matching Functions
    func likeUser(_ user: User) async throws {
        if let index = potentialMatches.firstIndex(where: { $0.id == user.id }) {
            let matchedUser = potentialMatches.remove(at: index)
            matches.append(matchedUser)
            
            // Only update Firestore if not dealing with mock users (mock IDs start with "mock")
            if !currentUser.id.hasPrefix("mock") && !matchedUser.id.hasPrefix("mock") {
                do {
                    let db = Firestore.firestore()
                    
                    // Update current user's matches array with just the ID
                    try await db.collection("users").document(currentUser.id).updateData([
                        "matches": FieldValue.arrayUnion([matchedUser.id])
                    ])
                    
                    // Update matched user's matches array with just the ID
                    try await db.collection("users").document(matchedUser.id).updateData([
                        "matches": FieldValue.arrayUnion([currentUser.id])
                    ])
                    
                    // Create a chat thread for the matched users
                    let chatId = try await chatService.createChat(with: matchedUser)
                    
                    // Send an automatic welcome message
                    try await chatService.sendMessage(
                        "Hi! We matched as potential roommates. Would you like to discuss living preferences?",
                        to: chatId
                    )
                    
                    print("✅ Created chat thread with \(matchedUser.firstName) and sent welcome message")
                } catch {
                    print("❌ Error updating matches and creating chat: \(error.localizedDescription)")
                    throw error // Re-throw to handle in UI
                }
            } else {
                // For mock users, create a local chat
                let mockChat = Chat(
                    id: "mock_chat_\(UUID().uuidString)",
                    participantIds: [currentUser.id, matchedUser.id],
                    lastMessage: "Hi! We matched as potential roommates. Would you like to discuss living preferences?",
                    lastMessageTimestamp: Date(),
                    unreadCount: 1,
                    otherUser: matchedUser
                )
                
                // Add the chat to MessagingService
                MessagingService.shared.chats.append(mockChat)
                
                print("✅ Created mock chat with \(matchedUser.firstName)")
            }
            
            // Notify that the chat list should be refreshed
            NotificationCenter.default.post(name: NSNotification.Name("RefreshChatList"), object: nil)
        }
    }
    
    func rejectUser(_ user: User) {
        if let index = potentialMatches.firstIndex(where: { $0.id == user.id }) {
            potentialMatches.remove(at: index)
            rejectedUsers.insert(user.id)
        }
    }
    
    func getNextPotentialMatch() -> User? {
        return potentialMatches.first { user in
            !rejectedUsers.contains(user.id) &&
            user.id != currentUser.id &&
            user.sex == currentUser.sex &&
            user.college == currentUser.college
        }
    }
    
    // MARK: - Match Calculation
    func calculateMatchPercentage(with user: User) -> Int {
        var totalScore = 0
        var maxScore = 0
        
        // Living preferences comparison (60% weight)
        if let currentPrefs = currentUser.livingPreferences,
           let userPrefs = user.livingPreferences {
            // Cleanliness (0-5)
            let cleanlinessMatch = 5 - abs(currentPrefs.cleanliness - userPrefs.cleanliness)
            totalScore += cleanlinessMatch * 3
            maxScore += 15
            
            // Noise level (0-5)
            let noiseMatch = 5 - abs(currentPrefs.noiseLevel - userPrefs.noiseLevel)
            totalScore += noiseMatch * 3
            maxScore += 15
            
            // Sleep schedule
            if currentPrefs.sleepSchedule == userPrefs.sleepSchedule {
                totalScore += 10
            }
            maxScore += 10
            
            // Guests preference
            if currentPrefs.guests == userPrefs.guests {
                totalScore += 5
            }
            maxScore += 5
            
            // Smoking
            if currentPrefs.smoking == userPrefs.smoking {
                totalScore += 5
            }
            maxScore += 5
            
            // Drinking
            if currentPrefs.drinking == userPrefs.drinking {
                totalScore += 5
            }
            maxScore += 5
            
            // Pets
            if currentPrefs.pets == userPrefs.pets {
                totalScore += 5
            }
            maxScore += 5
            
            // Temperature (0-5)
            let tempMatch = 5 - abs(currentPrefs.temperature - userPrefs.temperature)
            totalScore += tempMatch * 2
            maxScore += 10
        }
        
        // Interests comparison (40% weight)
        let commonInterests = Set(currentUser.interests).intersection(Set(user.interests))
        let totalInterests = Set(currentUser.interests).union(Set(user.interests))
        if !totalInterests.isEmpty {
            let interestScore = Int((Double(commonInterests.count) / Double(totalInterests.count)) * 40)
            totalScore += interestScore
            maxScore += 40
        }
        
        // Calculate final percentage
        guard maxScore > 0 else { return 0 }
        return Int((Double(totalScore) / Double(maxScore)) * 100)
    }
    
    // MARK: - Loading Functions
    func loadMatchedByUsers() async throws {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        
        // Get all users who have the current user in their matches array
        let snapshot = try await usersRef
            .whereField("matches", arrayContains: currentUser.id)
            .getDocuments()
        
        // Convert documents to User objects
        let users = snapshot.documents.compactMap { document -> User? in
            return User(document: document)
        }
        
        // Update the matchedByUsers array on the main thread
        self.matchedByUsers = users
        
        print("✅ Loaded \(users.count) users who matched with \(currentUser.firstName)")
    }

    func updateCurrentUser(_ user: User) {
        self.currentUser = user
    }
} 
