//
//  SettingsView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding(.top)
            
            Text("Here you can update your app preferences, account settings, and more.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Example settings options (expand as needed)
            NavigationLink(destination: ProfileSetupView()) {
                Text("Edit Profile")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            NavigationLink(destination: AdvancedFilterView()) {
                Text("Advanced Search Options")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Settings")
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
