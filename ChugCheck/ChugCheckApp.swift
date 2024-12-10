//
//  ChugCheckApp.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct ChugCheckApp: App {
    @StateObject private var authManager = AuthManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isNewUser: Bool = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !authManager.isAuthenticated {
                    LoginView()
                } else {
                    // Check Firestore for user status
                    FirestoreCheckView()
                }
            }
            .environmentObject(authManager)
        }
    }
}

struct FirestoreCheckView: View {
    @State private var isNewUser = true
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if isNewUser {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .onAppear {
            checkUserStatus()
        }
    }
    
    func checkUserStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                isNewUser = document.data()?["isNewUser"] as? Bool ?? true
            }
            isLoading = false
        }
    }
}

