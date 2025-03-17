//
//  OnboardingView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
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
                
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Text("Back")
                                .padding()
                        }
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .padding()
                        }
                    } else {
                        Button(action: {
                            // Mark onboarding as completed.
                            UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Get Started")
                                .bold()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
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
