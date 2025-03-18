//
//  DashboardView.swift
//  CollegePads
//
//  Created by Chase Vazquez on 3/18/25.
//


//
//  DashboardView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This view provides an overview dashboard that aggregates key user statistics:
//  • Profile Completion (calculated using ProfileCompletionCalculator)
//  • Total Matches count (using MatchingViewModel as a placeholder)
//  • Swipe activity (placeholder values; integrate with your SwipeAnalyticsViewModel if available)
//  • Average Compatibility Score (static placeholder; replace with dynamic calculation if available)
//  This dashboard helps users quickly assess the quality of their profile and matching activity.

import SwiftUI

struct DashboardView: View {
    // Shared profile view model
    @ObservedObject var profileVM = ProfileViewModel.shared
    // Matching view model for potential matches (for demo purposes, we use its count)
    @StateObject var matchingVM = MatchingViewModel()
    
    // In a complete implementation, you might have a dedicated swipe analytics view model.
    // For now, we use static values as placeholders.
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Completion Section
                    if let profile = profileVM.userProfile {
                        let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Completion: \(Int(completion))%")
                                .font(.headline)
                            ProgressView(value: completion, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Matches Count Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Matches")
                            .font(.headline)
                        // For demonstration, we use the count of potential matches.
                        // Replace with actual match count if available.
                        Text("\(matchingVM.potentialMatches.count) matches")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Swipe Analytics Section (Placeholders)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Activity")
                            .font(.headline)
                        HStack(spacing: 20) {
                            VStack {
                                Text("Right Swipes")
                                    .font(.subheadline)
                                Text("120")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            VStack {
                                Text("Left Swipes")
                                    .font(.subheadline)
                                Text("80")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Average Compatibility Score Section (Static Placeholder)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Compatibility")
                            .font(.headline)
                        Text("85%")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear {
                // Fetch potential matches to update the match count.
                matchingVM.fetchPotentialMatches()
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
