//
//  SignUpView.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: signUp) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .cornerRadius(10)
            }
        }
        .padding()
        .withGradientBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else if let userId = result?.user.uid {
                // Create user document in Firestore
                let db = Firestore.firestore()
                db.collection("users").document(userId).setData([
                    "email": email,
                    "isNewUser": true,
                    "createdAt": Date()
                ]) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        // Successfully created user
                        authManager.signIn()
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthManager())
}
