import SwiftUI

enum Theme {
    static let primaryColor = Color(red: 0.4, green: 0.2, blue: 0.8) // Dark purple
    static let secondaryColor = Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.2) // Light purple with opacity
    static let backgroundColor = Color.white // White background
    static let textColor = Color(red: 0.4, green: 0.2, blue: 0.8) // Dark purple text
    static let accentColor = Color(red: 0.6, green: 0.4, blue: 1.0) // Bright purple accent
    
    static let buttonHeight: CGFloat = 50
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    
    struct ButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(Theme.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(Theme.cornerRadius)
        }
    }
    
    struct TextFieldStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Theme.secondaryColor)
                .cornerRadius(Theme.cornerRadius)
                .foregroundColor(Theme.textColor)
        }
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        modifier(Theme.ButtonStyle())
    }
    
    func primaryTextFieldStyle() -> some View {
        modifier(Theme.TextFieldStyle())
    }
    
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(color)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(color)]
        return self
    }
} 