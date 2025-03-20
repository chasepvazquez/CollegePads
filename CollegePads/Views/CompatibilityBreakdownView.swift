//
//  CompatibilityBreakdownView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct CompatibilityBreakdownView: View {
    let candidate: UserModel
    @State private var breakdown: [String: Double] = [:]
    @State private var overallScore: Double = 0.0
    
    // Retrieve current user's profile from the shared ProfileViewModel.
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Compatibility Breakdown")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                if currentUser != nil {
                    Text("Overall Compatibility: \(Int(overallScore))%")
                        .font(.title)
                        .foregroundColor(overallScore > 70 ? .green : .orange)
                    
                    ForEach(breakdown.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .fontWeight(.semibold)
                                .frame(width: 100, alignment: .leading)
                            ProgressView(value: breakdown[key] ?? 0, total: 10)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            Text("\(Int(breakdown[key] ?? 0)) pts")
                                .frame(width: 50, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("Your profile is not loaded.")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compatibility")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Implement dismissal action if needed.
                    }
                }
            }
            .onAppear {
                computeCompatibility()
            }
        }
    }
    
    private func computeCompatibility() {
        guard let current = currentUser else { return }
        // Call the compatibility calculator using exactly the two parameters.
        let result = CompatibilityCalculator.calculateCompatibilityBreakdown(between: current, and: candidate)
        overallScore = result.overall
        breakdown = result.breakdown
    }
}
