import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showLogin = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo or App Name
                // Removed the top 'dormate' text
                
                Spacer()
                
                // Toggle between Login and Sign Up
                Picker("", selection: $showLogin) {
                    Text("Login").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: showLogin) { _, _ in
                    // Don't carry stale errors between login and signup
                    viewModel.errorMessage = nil
                }
                
                // Show either LoginView or SignUpView
                if showLogin {
                    LoginView(showLogin: $showLogin)
                        .environmentObject(viewModel)
                } else {
                    SignUpView(showLogin: $showLogin)
                        .environmentObject(viewModel)
                }
                
                Spacer()
            }
            .background(Theme.backgroundColor)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AuthView().environmentObject(AuthViewModel())
} 
