import SwiftUI

class MockAuthViewModel: AuthViewModel {
    override init() {
        super.init()
        // Initialize all required properties
        self.userSession = nil
        self.currentUser = nil
        self.errorMessage = nil
        self.isLoading = false
        self.appState = .unauthenticated
    }
} 