import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var showLogin: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textColor)
                    .padding(.top, 50)
                
                Text("Please fill in your information")
                    .font(.subheadline)
                    .foregroundColor(Theme.textColor.opacity(0.8))
                    .padding(.bottom, 10)
                
                VStack(spacing: 15) {
                    CustomTextField(text: $email, title: "Email", placeholder: "Enter your email address")
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .foregroundColor(Theme.textColor.opacity(0.8))
                            .font(.subheadline)
                        SecureField("Create a strong password", text: $password)
                            .textContentType(.newPassword)
                            .primaryTextFieldStyle()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .foregroundColor(Theme.textColor.opacity(0.8))
                            .font(.subheadline)
                        SecureField("Re-enter your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .primaryTextFieldStyle()
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        guard password == confirmPassword else {
                            viewModel.errorMessage = "Passwords do not match"
                            return
                        }
                        guard password.count >= 6 else {
                            viewModel.errorMessage = "Password must be at least 6 characters"
                            return
                        }
                        Task {
                            // On success, createUser sets appState = .livingSurvey
                            // and ContentView navigates. On failure, the error
                            // message shows and we stay here.
                            await viewModel.createUser(withEmail: email, password: password)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    .padding(.top, 10)
                    
                    Button {
                        showLogin = true
                    } label: {
                        Text("Already have an account? Sign In")
                            .foregroundColor(Theme.accentColor)
                    }
                }
                .padding(.horizontal, Theme.padding)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        SignUpView(showLogin: .constant(false))
            .environmentObject(AuthViewModel())
    }
} 

