//
//  CandidateProfileView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct CandidateProfileView: View {
    let candidateID: String
    
    @StateObject private var viewModel = CandidateProfileViewModel()
    @State private var showCompatibilityBreakdown = false
    @State private var showQuiz = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.white, Color(UIColor.systemGray6)]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            Group {
                if let candidate = viewModel.candidate {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile image (same as before)
                            if let imageUrl = candidate.profileImageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                                    } else {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 150, height: 150)
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 150, height: 150)
                            }
                            
                            // Candidate details in card-style container
                            VStack(alignment: .leading, spacing: 10) {
                                Text(candidate.email)
                                    .font(.headline)
                                if let grade = candidate.gradeLevel {
                                    Text("Grade: \(grade)")
                                }
                                if let major = candidate.major {
                                    Text("Major: \(major)")
                                }
                                if let college = candidate.collegeName {
                                    Text("College: \(college)")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if let dorm = candidate.dormType {
                                    Text("Dorm Type: \(dorm)")
                                }
                                if let budget = candidate.budgetRange {
                                    Text("Budget Range: \(budget)")
                                }
                                if let cleanliness = candidate.cleanliness {
                                    Text("Cleanliness: \(cleanliness)/5")
                                }
                                if let sleep = candidate.sleepSchedule {
                                    Text("Sleep Schedule: \(sleep)")
                                }
                                if let style = candidate.livingStyle {
                                    Text("Living Style: \(style)")
                                }
                                if let smoker = candidate.smoker {
                                    Text("Smoker: \(smoker ? "Yes" : "No")")
                                }
                                if let petFriendly = candidate.petFriendly {
                                    Text("Pet Friendly: \(petFriendly ? "Yes" : "No")")
                                }
                            }
                            .padding()
                            
                            Divider()
                            
                            // Buttons for compatibility breakdown and quiz
                            HStack(spacing: 16) {
                                Button(action: {
                                    showCompatibilityBreakdown = true
                                }) {
                                    Text("View Compatibility Breakdown")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.indigo)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showQuiz = true
                                }) {
                                    Text("Take Compatibility Quiz")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.pink)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading Profile...")
                        .onAppear {
                            viewModel.loadCandidate(with: candidateID)
                        }
                }
            }
        }
        .navigationTitle("Candidate Profile")
        .sheet(isPresented: $showCompatibilityBreakdown) {
            if let candidate = viewModel.candidate {
                CompatibilityBreakdownView(candidate: candidate)
            }
        }
        .sheet(isPresented: $showQuiz) {
            QuizView()  // Present the quiz modally
        }
        .alert(item: Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return GenericAlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct CandidateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CandidateProfileView(candidateID: "dummyCandidateID")
        }
    }
}
