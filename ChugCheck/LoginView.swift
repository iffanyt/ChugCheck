//
//  LoginView.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    init() { }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text("Welcome to ChugCheck")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: signIn) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .cornerRadius(10)
                }
                
                Button(action: { showingSignUp = true }) {
                    Text("Create Account")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .withGradientBackground()
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                authManager.signIn()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}
