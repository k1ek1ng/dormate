import SwiftUI

public struct ChatThreadView: View {
    public let chat: Chat
    @StateObject private var chatService: ChatService
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var messageText = ""
    @State private var showError = false
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public init(chat: Chat) {
        self.chat = chat
        // Initialize with a placeholder ID, will be updated when authViewModel.currentUser is available
        _chatService = StateObject(wrappedValue: ChatService(currentUserId: ""))
    }
    
    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageBubble(
                        message: message,
                        isFromCurrentUser: message.senderId == authViewModel.currentUser?.id
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var messageInput: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            messagesList
            messageInput
        }
        .navigationTitle(getOtherUserName())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .task {
            if let currentUserId = authViewModel.currentUser?.id {
                chatService.currentUserId = currentUserId
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        do {
            messages = try await chatService.loadMessages(for: chat.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            isLoading = true
            do {
                try await chatService.sendMessage(messageText, to: chat.id)
                messageText = ""
                // Reload messages after sending
                await loadMessages()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func getOtherUserName() -> String {
        if let otherUser = chat.otherUser {
            return "\(otherUser.firstName) \(otherUser.lastName)"
        }
        return "Chat"
    }
} 