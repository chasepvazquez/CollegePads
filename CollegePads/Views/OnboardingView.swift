//
//  OnboardingView.swift
//  CollegePads
//
//  Updated to include a page indicator for improved user orientation
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage: Int = 0
    
    let pages = [
        OnboardingPage(title: "Welcome to CollegePads", description: "Find your perfect roommate easily!", imageName: "person.3.fill"),
        OnboardingPage(title: "Swipe to Match", description: "Swipe right to like, left to pass, just like Tinder!", imageName: "hand.point.right.fill"),
        OnboardingPage(title: "Chat & Connect", description: "Start chatting once you match with someone!", imageName: "message.fill")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                Image(systemName: pages[currentPage].imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                
                Text(pages[currentPage].title)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(pages[currentPage].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Page Indicator Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
                
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation { currentPage -= 1 }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding()
                    } else {
                        Button("Get Started") {
                            UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                            presentationMode.wrappedValue.dismiss()
                        }
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Onboarding")
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
