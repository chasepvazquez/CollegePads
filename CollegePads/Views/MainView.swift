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
            VStack(spacing: 20) {
                Text("Welcome to CollegePads!")
                    .font(.largeTitle)
                    .padding()

                // "Find Roommates" button (swipe-based matching)
                NavigationLink(destination: MatchingView()) {
                    Text("Find Roommates")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // "Setup/Update Profile" button
                NavigationLink(destination: ProfileSetupView()) {
                    Text("Setup/Update Profile")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // "Advanced Search" button
                NavigationLink(destination: AdvancedFilterView()) {
                    Text("Advanced Search")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // "My Chats" button
                NavigationLink(destination: ChatsListView()) {
                    Text("My Chats")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // "Matches Dashboard" button (new)
                NavigationLink(destination: MatchesDashboardView()) {
                    Text("My Matches")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // "Settings" button (dummy for now)
                NavigationLink(destination: SettingsView()) {
                    Text("Settings")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Sign-out button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
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
