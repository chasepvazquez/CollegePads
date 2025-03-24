import SwiftUI

struct DashboardView: View {
    @ObservedObject var profileVM = ProfileViewModel.shared
    @StateObject var matchingVM = MatchingViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Completion Section
                    if let profile = profileVM.userProfile {
                        let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Completion: \(Int(completion))%")
                                .font(AppTheme.titleFont)
                            ProgressView(value: completion, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Matches Count Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Matches")
                            .font(AppTheme.titleFont)
                        Text("\(matchingVM.potentialMatches.count) matches")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Swipe Analytics Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Activity")
                            .font(AppTheme.titleFont)
                        HStack(spacing: 20) {
                            VStack {
                                Text("Right Swipes")
                                    .font(AppTheme.bodyFont)
                                Text("120")
                                    .font(AppTheme.titleFont)
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            VStack {
                                Text("Left Swipes")
                                    .font(AppTheme.bodyFont)
                                Text("80")
                                    .font(AppTheme.titleFont)
                                    .foregroundColor(AppTheme.secondaryColor)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Average Compatibility Score Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Compatibility")
                            .font(AppTheme.titleFont)
                        Text("85%")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dashboard")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
            .onAppear {
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
