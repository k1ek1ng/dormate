import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    enum AppState {
        case unauthenticated
        case livingSurvey
        case profileSetup
        case authenticated
    }
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var appState: AppState = .unauthenticated
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    init() {
        print("🔍 AuthViewModel initializing...")
        self.userSession = auth.currentUser
        print("👤 Current user session: \(userSession?.uid ?? "none")")
        
        if let userSession {
            print("🔄 Fetching user data...")
            Task {
                await fetchUser(userId: userSession.uid)
                // Restore the right screen for the saved session —
                // previously this never ran and cold launches always
                // landed on the login screen.
                routeForCurrentUser()
            }
        } else {
            print("⚠️ No user session found")
            appState = .unauthenticated
        }
    }
    
    func signIn(withEmail email: String, password: String) async {
        print("🔑 Attempting sign in...")
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("✅ Sign in successful")
            
            await fetchUser(userId: result.user.uid)
            
            // Update app state based on how far the user got through onboarding
            routeForCurrentUser()
            
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func createUser(withEmail email: String, password: String) async {
        print("👤 Creating new user...")
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            self.userSession = result.user
            print("✅ User created successfully")
            
            let user = User(
                id: result.user.uid,
                email: email,
                firstName: "",
                lastName: "",
                sex: "",
                college: "",
                bio: "",
                interests: [],
                livingPreferences: nil
            )
            
            try await saveUserToFirestore(user)
            self.currentUser = user
            self.appState = .livingSurvey
            
        } catch {
            handleAuthError(error)
            print("❌ User creation failed: \(error)")
        }
        
        isLoading = false
    }
    
    func updateUserProfile(user: User) async {
        print("⏳ Updating user profile...")
        isLoading = true
        
        do {
            var userData: [String: Any] = [
                "firstName": user.firstName,
                "lastName": user.lastName,
                "sex": user.sex,
                "college": user.college,
                "bio": user.bio,
                "interests": user.interests,
                "profileImageUrl": user.profileImageUrl as Any
            ]
            
            if let preferences = user.livingPreferences {
                userData["livingPreferences"] = [
                    "cleanliness": preferences.cleanliness,
                    "noiseLevel": preferences.noiseLevel,
                    "sleepSchedule": preferences.sleepSchedule,
                    "guests": preferences.guests,
                    "smoking": preferences.smoking,
                    "drinking": preferences.drinking,
                    "pets": preferences.pets,
                    "temperature": preferences.temperature
                ]
            }
            
            try await Firestore.firestore()
                .collection("users")
                .document(user.id)
                .updateData(userData)
            
            print("✅ Profile updated in Firestore")
            
            self.currentUser = user
            
            // Check if profile is complete
            if !user.firstName.isEmpty && !user.lastName.isEmpty && !user.college.isEmpty {
                appState = .authenticated
                print("✅ Profile complete, transitioning to authenticated state")
            } else {
                appState = .profileSetup
                print("⚠️ Profile incomplete, staying in profile setup")
            }
            
        } catch {
            print("❌ Profile update failed: \(error)")
            errorMessage = "Failed to save profile. Please try again."
        }
        
        isLoading = false
    }
    
    func updateLivingPreferences(_ preferences: LivingPreferences) async {
        guard let currentUser = self.currentUser else { return }
        
        let updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            sex: currentUser.sex,
            college: currentUser.college,
            bio: currentUser.bio,
            interests: currentUser.interests,
            livingPreferences: preferences
        )
        
        do {
            try await saveUserToFirestore(updatedUser)
            self.currentUser = updatedUser
            routeForCurrentUser()
        } catch {
            print("DEBUG: Failed to update living preferences: \(error.localizedDescription)")
            errorMessage = "Failed to save preferences. Please try again."
        }
    }
    
    /// Single source of truth for post-auth routing based on onboarding progress.
    func routeForCurrentUser() {
        guard let user = currentUser else {
            appState = userSession == nil ? .unauthenticated : .livingSurvey
            return
        }
        if user.livingPreferences == nil {
            appState = .livingSurvey
        } else if user.firstName.isEmpty || user.lastName.isEmpty || user.college.isEmpty {
            appState = .profileSetup
        } else {
            appState = .authenticated
        }
    }
    
    @MainActor
    func fetchUser(userId: String) async {
        do {
            print("⏳ Fetching user data from Firestore...")
            let snapshot = try await db.collection("users").document(userId).getDocument()
            guard let data = snapshot.data() else { 
                print("❌ No user data found in Firestore")
                return 
            }
            
            let prefs = await processLivingPreferences(from: data["livingPreferences"] as? [String: Any])
            
            self.currentUser = User(
                id: userId,
                email: data["email"] as? String ?? "",
                firstName: data["firstName"] as? String ?? "",
                lastName: data["lastName"] as? String ?? "",
                sex: data["sex"] as? String ?? "",
                college: data["college"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                interests: data["interests"] as? [String] ?? [],
                profileImageUrl: data["profileImageUrl"] as? String,
                livingPreferences: prefs
            )
            
            print("✅ Successfully fetched user: \(self.currentUser?.firstName ?? "unknown")")
        } catch {
            print("❌ Failed to fetch user: \(error.localizedDescription)")
            errorMessage = "Failed to load profile. Please try again."
        }
    }
    
    private func processLivingPreferences(from data: [String: Any]?) async -> LivingPreferences? {
        guard let prefs = data else { return nil }
        
        return LivingPreferences(
            cleanliness: prefs["cleanliness"] as? Int ?? 3,
            noiseLevel: prefs["noiseLevel"] as? Int ?? 3,
            sleepSchedule: prefs["sleepSchedule"] as? String ?? "Early Bird",
            guests: prefs["guests"] as? String ?? "Occasional",
            smoking: prefs["smoking"] as? Bool ?? false,
            drinking: prefs["drinking"] as? Bool ?? false,
            pets: prefs["pets"] as? Bool ?? false,
            temperature: prefs["temperature"] as? Int ?? 3
        )
    }
    
    private func saveUserToFirestore(_ user: User) async throws {
        var data: [String: Any] = [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "sex": user.sex,
            "college": user.college,
            "bio": user.bio,
            "interests": user.interests
        ]
        
        // Include profile image URL if available
        if let profileImageUrl = user.profileImageUrl {
            data["profileImageUrl"] = profileImageUrl
        }
        
        if let preferences = user.livingPreferences {
            data["livingPreferences"] = [
                "cleanliness": preferences.cleanliness,
                "noiseLevel": preferences.noiseLevel,
                "sleepSchedule": preferences.sleepSchedule,
                "guests": preferences.guests,
                "smoking": preferences.smoking,
                "drinking": preferences.drinking,
                "pets": preferences.pets,
                "temperature": preferences.temperature
            ]
        }
        
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }
    
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .wrongPassword:
                errorMessage = "Invalid password. Please try again."
            case .invalidEmail:
                errorMessage = "Invalid email address."
            case .emailAlreadyInUse:
                errorMessage = "This email is already registered."
            case .userNotFound:
                errorMessage = "No account found with this email."
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "An error occurred. Please try again."
            }
        } else {
            errorMessage = "An unexpected error occurred."
        }
        print("DEBUG: Auth error: \(error.localizedDescription)")
    }
    
    func signOut() {
        do {
            try auth.signOut()
            self.userSession = nil
            self.currentUser = nil
            self.errorMessage = nil
            self.appState = .unauthenticated
        } catch {
            print("DEBUG: Failed to sign out with error: \(error.localizedDescription)")
        }
    }
    
    func updateProfileImage(uiImage: UIImage) async throws -> String? {
        guard let imageData = uiImage.jpegData(compressionQuality: 0.3) else { return nil }
        guard let userId = currentUser?.id else { return nil }
        
        let filename = "profile_images/\(userId).jpg"
        let ref = storage.child(filename)
        
        // Upload image
        _ = try await ref.putDataAsync(imageData)
        
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
} 
