//
//  GradientBackground.swift
//  ChugCheck
//
//  Created by IOSAPP on 12/10/24.
//

import SwiftUI

struct GradientBackground: ViewModifier {
    let gradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.1, blue: 0.3),  // Navy blue (darker)
            Color(red: 0.1, green: 0.2, blue: 0.45)   // Royal blue (lighter)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    func body(content: Content) -> some View {
        ZStack {
            gradient
                .ignoresSafeArea()
            
            content
        }
        .toolbarColorScheme(.dark)
    }
}

extension View {
    func withGradientBackground() -> some View {
        modifier(GradientBackground())
    }
}
