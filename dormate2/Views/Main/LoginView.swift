import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var showLogin: Bool
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.primaryColor)
                    
                    Text("dormate")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textColor)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 15) {
                    Text("Welcome Back!")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.textColor)
                        .padding(.bottom, 10)
                        
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .foregroundColor(Theme.textColor.opacity(0.8))
                            .font(.subheadline)
                        TextField("Enter your email address", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .primaryTextFieldStyle()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .foregroundColor(Theme.textColor.opacity(0.8))
                            .font(.subheadline)
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
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
                        Task {
                            // Navigation happens via appState in ContentView —
                            // no local navigation needed here.
                            await viewModel.signIn(withEmail: email, password: password)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.top, 10)
                    
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .foregroundColor(Theme.textColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button {
                        showLogin = false
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(Theme.accentColor)
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        LoginView(showLogin: .constant(true))
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
} 
