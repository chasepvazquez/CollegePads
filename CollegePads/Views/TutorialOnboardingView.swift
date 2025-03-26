import SwiftUI

/// Data model for tutorial pages.
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

/// TutorialOnboardingView – displays pages 0–2.
/// This view is shown when no user is signed in.
struct TutorialOnboardingView: View {
    // For this part, only the tutorial content is needed.
    private let tutorialPages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to CollegePads",
                       description: "Find your perfect roommate easily!",
                       imageName: "person.3.fill"),
        OnboardingPage(title: "Swipe to Match",
                       description: "Swipe right to like, left to pass, just like Tinder!",
                       imageName: "hand.point.right.fill"),
        OnboardingPage(title: "Chat & Connect",
                       description: "Start chatting once you match with someone!",
                       imageName: "message.fill")
    ]
    
    // Tracks current page.
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 30) {
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: tutorialPages[index].imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(AppTheme.primaryColor)
                                .accessibilityHidden(true)
                            
                            Text(tutorialPages[index].title)
                                .font(AppTheme.titleFont)
                                .bold()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(tutorialPages[index].description)
                                .font(AppTheme.bodyFont)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(maxHeight: 400)
                
                // "Get Started" button on last tutorial page dismisses onboarding.
                if currentPage == tutorialPages.count - 1 {
                    Button(action: {
                        // Dismiss the onboarding view.
                        // (User will then see the AuthenticationView.)
                        // You might want to set a flag here if needed.
                        // For now, simply dismiss.
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.rootViewController?.dismiss(animated: true)
                        }
                    }) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                }
                Spacer()
            }
            // Center content vertically.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()
        }
    }
}

struct TutorialOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialOnboardingView()
    }
}
