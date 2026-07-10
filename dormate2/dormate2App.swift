//
//  dormate2App.swift
//  dormate2
//
//  Created by Kiela King on 4/26/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct dormate2App: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
