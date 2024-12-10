//
//  HistoryView.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WaterIntakeRecord {
    let date: Date
    let amount: Int
}

struct HistoryView: View {
    @State private var intakeHistory: [Date: Int] = [:]
    @State private var selectedDate: Date = Date()
    @State private var selectedMonthIntake: [WaterIntakeRecord] = []
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Month selector
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 150)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            DayCell(date: date, intake: intakeHistory[date] ?? 0)
                        } else {
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .withGradientBackground()
            .onAppear {
                loadMonthData()
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
            loadMonthData()
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let leadingSpaces = firstWeekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: leadingSpaces)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func loadMonthData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        db.collection("users")
            .document(userId)
            .collection("waterIntake")
            .whereField("date", isGreaterThanOrEqualTo: startOfMonth)
            .whereField("date", isLessThanOrEqualTo: endOfMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading history: \(error.localizedDescription)")
                    return
                }
                
                intakeHistory.removeAll()
                
                snapshot?.documents.forEach { doc in
                    if let date = (doc.get("date") as? Timestamp)?.dateValue(),
                       let amount = doc.get("amount") as? Int {
                        intakeHistory[date] = amount
                    }
                }
            }
    }
}

struct DayCell: View {
    let date: Date
    let intake: Int
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .foregroundColor(.white)
            if intake > 0 {
                Text("\(intake)oz")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.9))
            }
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(intake > 0 ? Color.blue.opacity(0.3) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
}
