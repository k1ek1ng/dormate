import SwiftUI

public struct MessageBubble: View {
    public let message: Message
    public let isFromCurrentUser: Bool
    
    public init(message: Message, isFromCurrentUser: Bool) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    public var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        MessageBubble(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: "Hello! How are you?",
                timestamp: Date(),
                isRead: true
            ),
            isFromCurrentUser: true
        )
        
        MessageBubble(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: "I'm good, thanks! How about you?",
                timestamp: Date(),
                isRead: true
            ),
            isFromCurrentUser: false
        )
    }
    .padding()
} 