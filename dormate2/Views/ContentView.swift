import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.appState {
                case .unauthenticated:
                    AuthView()
                        .environmentObject(viewModel)
                    
                case .profileSetup:
                    ProfileSetupView()
                        .environmentObject(viewModel)
                    
                case .authenticated:
                    MainTabViewContainer()
                        .environmentObject(viewModel)
                }
            }
            .onChange(of: viewModel.appState) { oldState, newState in
                print("🔄 App state changed from: \(oldState) to: \(newState)")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MockAuthViewModel())
} 