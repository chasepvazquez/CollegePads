//
//  HomeView.swift
//  CollegePads
//
//  Updated to use global background gradient, theme colors, and proper navigation using NavigationLink.
//
import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome to CollegePads!")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                
                // Navigate to Profile Setup
                NavigationLink(destination: ProfileSetupView()) {
                    Text("Setup / Update Profile")
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                
                // Navigate to Advanced Search (placeholder view)
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
        }
        .navigationTitle("Home")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
        }
    }
}
