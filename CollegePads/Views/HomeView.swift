//
//  HomeView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    Text("Welcome to CollegePads!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    // Dashboard options (each as a NavigationLink)
                    NavigationLink(destination: ProfileSetupView()) {
                        Text("Setup / Update Profile")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.green))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: AdvancedFilterView()) {
                        Text("Advanced Search")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.orange))
                    .padding(.horizontal)
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("Settings")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.gray))
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
