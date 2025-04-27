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
        loadMockUsers()
    }
    
    // MARK: - Mock Data
    private func loadMockUsers() {
        // Get current user's preferences for high matching
        let currentPrefs = currentUser.livingPreferences ?? LivingPreferences(
            cleanliness: 4,
            noiseLevel: 2,
            sleepSchedule: "Early Bird",
            guests: "Occasional",
            smoking: false,
            drinking: false,
            pets: false,
            temperature: 3
        )
        
        // Create interests that overlap with current user's interests
        let currentInterests = Set(currentUser.interests)
        let commonInterests = Array(currentInterests.prefix(3)) // Take first 3 interests from current user
        
        // Mock users from the same college and gender with similar preferences
        let mockUsers = [
            User(
                id: "mock1",
                email: "alex.johnson@example.com",
                firstName: "Alex",
                lastName: "Johnson",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "Computer Science major with a passion for photography and hiking. I'm looking for someone who enjoys outdoor adventures and late-night coding sessions. I keep my space clean and organized, and I'm a morning person who loves starting the day with a good workout. 🏃‍♂️💻",
                interests: commonInterests + ["Photography", "Coding"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: currentPrefs.cleanliness,
                    noiseLevel: currentPrefs.noiseLevel,
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: currentPrefs.temperature
                )
            ),
            User(
                id: "mock2",
                email: "taylor.smith@example.com",
                firstName: "Taylor",
                lastName: "Smith",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "🎵 Music major and coffee enthusiast! I play guitar and piano. Love hosting small jam sessions in my room. Looking for someone who appreciates good music and doesn't mind occasional noise. I keep things tidy but not obsessive about it. Always down for late-night coffee runs! ☕️",
                interests: commonInterests + ["Music", "Guitar"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: max(1, currentPrefs.cleanliness - 1),
                    noiseLevel: min(5, currentPrefs.noiseLevel + 1),
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: currentPrefs.temperature
                )
            ),
            User(
                id: "mock3",
                email: "jordan.williams@example.com",
                firstName: "Jordan",
                lastName: "Williams",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "🏋️‍♂️ Pre-med student and fitness enthusiast! Early riser (5 AM workouts!) and meal prep fanatic. Looking for a roommate who values health and wellness. I keep my space immaculate and prefer a quiet study environment. Let's hit the gym together! 🥗",
                interests: commonInterests + ["Fitness", "Medicine"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: min(5, currentPrefs.cleanliness + 1),
                    noiseLevel: currentPrefs.noiseLevel,
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: currentPrefs.temperature
                )
            ),
            User(
                id: "mock4",
                email: "morgan.chen@example.com",
                firstName: "Morgan",
                lastName: "Chen",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "🎨 Art major specializing in digital design. My ideal day includes sketching at local cafes and attending gallery openings. Looking for a creative and respectful roommate. I'm neat but not a neat freak, and I love decorating our shared space! Sometimes work late on projects 🎨",
                interests: commonInterests + ["Art", "Design"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: currentPrefs.cleanliness,
                    noiseLevel: currentPrefs.noiseLevel,
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: min(5, currentPrefs.temperature + 1)
                )
            ),
            User(
                id: "mock5",
                email: "casey.patel@example.com",
                firstName: "Casey",
                lastName: "Patel",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "🌱 Environmental Science major passionate about sustainability! Love cooking vegetarian meals and maintaining my mini herb garden. Looking for an eco-conscious roommate who's interested in reducing their carbon footprint. Big on recycling and composting! 🌿",
                interests: commonInterests + ["Sustainability", "Gardening"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: currentPrefs.cleanliness,
                    noiseLevel: currentPrefs.noiseLevel,
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: max(1, currentPrefs.temperature - 1)
                )
            ),
            User(
                id: "mock6",
                email: "robin.garcia@example.com",
                firstName: "Robin",
                lastName: "Garcia",
                sex: currentUser.sex,
                college: currentUser.college,
                bio: "🎮 Computer Engineering major and game dev enthusiast! Working on developing my own indie game. I keep regular hours despite being a tech person! Looking for a roommate who doesn't mind the occasional coding session and maybe wants to playtest my games! 🕹️",
                interests: commonInterests + ["Gaming", "Programming"],
                profileImageUrl: nil,
                livingPreferences: LivingPreferences(
                    cleanliness: currentPrefs.cleanliness,
                    noiseLevel: currentPrefs.noiseLevel,
                    sleepSchedule: currentPrefs.sleepSchedule,
                    guests: currentPrefs.guests,
                    smoking: currentPrefs.smoking,
                    drinking: currentPrefs.drinking,
                    pets: currentPrefs.pets,
                    temperature: currentPrefs.temperature
                )
            )
        ]
        
        // Filter users by matching criteria
        potentialMatches = mockUsers.filter {
            $0.id != currentUser.id &&
            $0.sex == currentUser.sex &&
            $0.college == currentUser.college
        }
        
        print("✅ Loaded \(potentialMatches.count) matching users for \(currentUser.firstName) from \(currentUser.college)")
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
