import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showLogin = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo or App Name
                Text("dormate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primaryColor)
                    .padding(.top, 50)
                
                Spacer()
                
                // Toggle between Login and Sign Up
                Picker("", selection: $showLogin) {
                    Text("Login").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Show either LoginView or SignUpView
                if showLogin {
                    LoginView()
                        .environmentObject(viewModel)
                } else {
                    SignUpView()
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
    AuthView()
        .environmentObject(AuthViewModel())
} 
