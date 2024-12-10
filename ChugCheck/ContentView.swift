//
//  ContentView.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    var body: some View {
        TabView {
            MainWaterView()
                .tabItem {
                    Label("Today", systemImage: "drop.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
}

struct MainWaterView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("dailyWaterGoal") private var dailyGoal: Int = 0
    @State private var currentIntake: Int = 0
    @State private var showingCustomInput = false
    @State private var customAmount: String = ""
    @State private var showingCelebration = false
    @State private var hasShownCelebrationToday = false
    @State private var showingUpdateGoal = false
    
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.2, blue: 0.45), // Dark blue
            Color(red: 0.1, green: 0.2, blue: 0.35)  // Slightly lighter blue
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private func saveWaterIntake(amount: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let today = Calendar.current.startOfDay(for: Date())
        
        db.collection("users")
            .document(userId)
            .collection("waterIntake")
            .document(today.ISO8601Format())
            .setData([
                "date": Timestamp(date: today),
                "amount": amount
            ]) { error in
                if let error = error {
                    print("Error saving water intake: \(error.localizedDescription)")
                }
            }
    }
    
    private func checkAndCelebrate(newIntake: Int) {
        if newIntake >= dailyGoal && !hasShownCelebrationToday {
            showingCelebration = true
            hasShownCelebrationToday = true
            // Save the celebration date
            UserDefaults.standard.set(Date(), forKey: "lastCelebrationDate")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 20)  // Lighter stroke
                            .frame(width: 250, height: 250)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(Double(currentIntake) / Double(dailyGoal)))
                            .stroke(Color.blue.opacity(0.9), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(currentIntake)")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            Text("of \(dailyGoal) oz")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Quick Add Buttons
                    HStack(spacing: 20) {
                        ForEach([8, 16, 32], id: \.self) { amount in
                            Button(action: {
                                currentIntake += amount
                                saveWaterIntake(amount: currentIntake)
                                checkAndCelebrate(newIntake: currentIntake)
                            }) {
                                VStack {
                                    Text("+\(amount)")
                                        .font(.headline)
                                    Text("oz")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.blue.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .clipShape(Circle())
                            }
                        }
                    }
                    
                    // Custom Amount Button
                    Button(action: {
                        showingCustomInput = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Amount")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .cornerRadius(10)
                    }
                    
                    // Reset Button
                    Button(action: {
                        currentIntake = 0
                        saveWaterIntake(amount: 0)
                    }) {
                        Text("Reset Daily Progress")
                            .foregroundColor(.red.opacity(0.9))
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("ChugCheck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ChugCheck")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(action: {
                            showingUpdateGoal = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingUpdateGoal) {
                NavigationStack {
                    OnboardingView(isUpdating: true)
                        .navigationBarItems(leading: Button("Cancel") {
                            showingUpdateGoal = false
                        })
                }
            }
            .alert("Add Custom Amount", isPresented: $showingCustomInput) {
                TextField("Amount in oz", text: $customAmount)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    customAmount = ""
                }
                Button("Add") {
                    if let amount = Int(customAmount) {
                        currentIntake += amount
                        saveWaterIntake(amount: currentIntake)
                        checkAndCelebrate(newIntake: currentIntake)
                    }
                    customAmount = ""
                }
            } message: {
                Text("Enter the amount of water in ounces")
            }
            .alert("Goal Achieved! 🎉", isPresented: $showingCelebration) {
                Button("Awesome!", role: .cancel) { }
            } message: {
                Text("Congratulations! You've reached your daily water intake goal!")
            }
            .onAppear {
                loadTodayIntake()
                if !Calendar.current.isDateInToday(UserDefaults.standard.object(forKey: "lastCelebrationDate") as? Date ?? Date.distantPast) {
                    hasShownCelebrationToday = false
                }
            }
        }
    }
    
    private func loadTodayIntake() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let today = Calendar.current.startOfDay(for: Date())
        
        db.collection("users")
            .document(userId)
            .collection("waterIntake")
            .document(today.ISO8601Format())
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let amount = document.data()?["amount"] as? Int {
                        currentIntake = amount
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}

