import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome to CollegePads!")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                
                // Navigate to Profile Setup
                NavigationLink(destination: ProfileSetupView()) {
                    Text("Setup / Update Profile")
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                
                // Navigate to Advanced Search
                NavigationLink(destination: AdvancedFilterView()) {
                    Text("Advanced Search")
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                
                // Navigate to Settings
                NavigationLink(destination: SettingsView().environmentObject(AuthViewModel())) {
                    Text("Settings")
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.secondaryColor))
            }
            .padding()
            .font(AppTheme.bodyFont)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
        }
    }
}
