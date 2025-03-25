import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome to CollegePads!")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                
                // Profile Icon: Displays the current user's profile picture.
                NavigationLink(destination: MyProfileView()) {
                                    if let profileImageUrl = ProfileViewModel.shared.userProfile?.profileImageUrl,
                                       let url = URL(string: profileImageUrl) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 70, height: 70)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 2))
                                            } else {
                                                Image(systemName: "person.crop.circle")
                                                    .resizable()
                                                    .frame(width: 70, height: 70)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 70, height: 70)
                    }
                }
                .padding()
                
                // Navigation to Advanced Search
                NavigationLink(destination: AdvancedFilterView()) {
                    Text("Advanced Search")
                        .font(AppTheme.bodyFont)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                // Navigation to Settings
                NavigationLink(destination: SettingsView().environmentObject(AuthViewModel())) {
                    Text("Settings")
                        .font(AppTheme.bodyFont)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.secondaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                Spacer()
            }
            .padding()
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
