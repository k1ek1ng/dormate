import SwiftUI

struct ChatRow: View {
    let chat: Chat
    let otherUser: User?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let user = otherUser,
               let imageUrl = user.profileImageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                if let user = otherUser {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.headline)
                } else {
                    ProgressView()
                        .frame(height: 20)
                }
                
                Text(chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Timestamp
            Text(formatDate(chat.lastMessageTimestamp))
                .font(.caption)
                .foregroundColor(.gray)
            
            // Unread Count
            if chat.unreadCount > 0 {
                Text("\(chat.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Theme.primaryColor)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MM/dd/yy"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    ChatRow(
        chat: Chat(
            id: "1",
            participantIds: ["1", "2"],
            lastMessage: "Hey, how are you?",
            lastMessageTimestamp: Date(),
            unreadCount: 2
        ),
        otherUser: User(
            id: "2",
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            sex: "Male",
            college: "Stanford",
            bio: "Test bio",
            interests: ["Hiking", "Reading"]
        )
    )
    .padding()
} 