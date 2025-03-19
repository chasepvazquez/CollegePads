//
//  MainView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ZStack {
                // Global gradient background from theme
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(UIColor.systemGray5)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Welcome to CollegePads!")
                        .font(.largeTitle)
                        .padding()
                    
                    NavigationLink(destination: MatchingView()) {
                        Text("Find Roommates")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .brandPrimary))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: ProfileSetupView()) {
                        Text("Setup/Update Profile")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .green))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: AdvancedFilterView()) {
                        Text("Advanced Search")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .orange))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: ChatsListView()) {
                        Text("My Chats")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .purple))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: MatchesDashboardView()) {
                        Text("My Matches")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .teal))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("Settings")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .gray))
                    .padding(.horizontal)
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .red))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Roommate Matches")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(AuthViewModel())
    }
}
