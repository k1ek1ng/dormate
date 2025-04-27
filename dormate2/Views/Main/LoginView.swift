import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showMainView = false
    
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
                            await viewModel.signIn(withEmail: email, password: password)
                            if viewModel.userSession != nil {
                                showMainView = true
                            }
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
                    
                    NavigationLink(destination: SignUpView()
                        .environmentObject(viewModel)) {
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
        .fullScreenCover(isPresented: $showMainView) {
            if viewModel.appState == .authenticated {
                MainTabViewContainer()
                    .environmentObject(viewModel)
            } else if viewModel.appState == .profileSetup {
                ProfileSetupView()
                    .environmentObject(viewModel)
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
} 
