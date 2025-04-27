import SwiftUI
import FirebaseFirestore

public struct ChatView: View {
    @StateObject private var messagingService = MessagingService.shared
    @StateObject private var userService = UserService()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedChat: Chat?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var chatsWithUsers: [Chat] = []
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading chats...")
                } else if chatsWithUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                        Text("When you match with someone, you'll be able to chat with them here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(chatsWithUsers) { chat in
                            NavigationLink(destination: ChatThreadView(chat: chat)) {
                                ChatRow(chat: chat, otherUser: chat.otherUser)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                loadChats()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshChatList"))) { _ in
                loadChats()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func loadChats() {
        Task {
            isLoading = true
            do {
                guard let currentUserId = authViewModel.currentUser?.id else {
                    print("⚠️ No current user ID available")
                    return
                }
                
                // Debug: Print current user's matches
                if let currentUser = try await userService.fetchUser(userId: currentUserId) {
                    print("👤 Current user matches: \(currentUser.matches)")
                }
                
                try await messagingService.loadChats(currentUserId: currentUserId)
                print("📱 Loaded chats count: \(messagingService.chats.count)")
                
                // Create new array with updated chats
                var updatedChats: [Chat] = []
                for var chat in messagingService.chats {
                    if let otherUserId = chat.participantIds.first(where: { $0 != currentUserId }) {
                        print("🔄 Fetching user info for: \(otherUserId)")
                        if let user = try await userService.fetchUser(userId: otherUserId) {
                            chat.otherUser = user
                            print("✅ Found user: \(user.firstName) \(user.lastName)")
                        } else {
                            print("⚠️ Could not fetch user for ID: \(otherUserId)")
                        }
                    }
                    updatedChats.append(chat)
                }
                chatsWithUsers = updatedChats
                print("📱 Final chats with users count: \(chatsWithUsers.count)")
            } catch {
                print("❌ Error loading chats: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(AuthViewModel())
} 