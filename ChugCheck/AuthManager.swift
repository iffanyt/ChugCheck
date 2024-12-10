//
//  AuthManager.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import Foundation
import FirebaseAuth // <-- Import Firebase Auth

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    func signOut() {
        isAuthenticated = false
        // Add any other cleanup needed for sign out
    }
    
    func signIn() {
        isAuthenticated = true
    }
}
