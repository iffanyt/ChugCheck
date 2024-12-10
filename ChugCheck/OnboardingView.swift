//
//  OnboardingView.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var weight: String = ""
    @State private var waterIntake: Int?
    @State private var showingResult = false
    @State private var isUpdating: Bool = false
    
    init(isUpdating: Bool = false) {
        self.isUpdating = isUpdating
    }
    
    private func calculateWaterIntake() {
        guard let weightValue = Double(weight) else { return }
        let waterOz = ceil(weightValue / 2)
        waterIntake = Int(waterOz)
        showingResult = true
        
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).setData([
                "weight": weightValue,
                "waterGoal": waterOz,
                "isNewUser": false,
                "lastUpdated": Date()
            ]) { error in
                if let error = error {
                    print("Error saving user data: \(error.localizedDescription)")
                } else {
                    print("Successfully saved water goal")
                    UserDefaults.standard.set(waterOz, forKey: "dailyWaterGoal")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(isUpdating ? "Update Your Daily Water Goal" : "Let's Calculate Your Daily Water Goal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Enter your weight to determine your recommended daily water intake")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    Text("lbs")
                        .foregroundColor(.white)
                }
                
                Button(action: calculateWaterIntake) {
                    Text("Calculate")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .cornerRadius(10)
                }
                
                if showingResult, let intake = waterIntake {
                    VStack(spacing: 10) {
                        Text("Your daily water intake goal:")
                            .font(.headline)
                        
                        Text("\(intake) oz")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            if isUpdating {
                                dismiss()
                            } else {
                                if let userId = Auth.auth().currentUser?.uid {
                                    let db = Firestore.firestore()
                                    db.collection("users").document(userId).updateData([
                                        "isNewUser": false
                                    ])
                                }
                            }
                        }) {
                            Text(isUpdating ? "Save Changes" : "Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    .transition(.scale)
                }
                
                Spacer()
            }
            .padding()
            .withGradientBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isUpdating) {
                OnboardingView(isUpdating: false)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onChange(of: isUpdating) { newValue in
            print("Navigation state changed to: \(newValue)")
        }
    }
}

#Preview {
    OnboardingView()
}
