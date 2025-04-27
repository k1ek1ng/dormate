import Foundation
import FirebaseFirestore

@MainActor
public class UserService: ObservableObject {
    private let db = Firestore.firestore()
    
    public init() {}
    
    public func fetchUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        return User(document: document)
    }
} 