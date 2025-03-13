//
//  SwipeCardView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SwipeCardView: View {
    let user: UserModel
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            
            VStack {
                Text(user.email)
                    .font(.headline)
                    .padding(.bottom, 5)
                if let dorm = user.dormType {
                    Text("Dorm: \(dorm)")
                }
                if let budget = user.budgetRange {
                    Text("Budget: \(budget)")
                }
                if let schedule = user.sleepSchedule {
                    Text("Sleep: \(schedule)")
                }
                // Add additional fields as desired.
            }
            .padding()
        }
        .frame(height: 400)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(Angle(degrees: rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    if offset.width > 100 {
                        onSwipe(user, .right)
                    } else if offset.width < -100 {
                        onSwipe(user, .left)
                    }
                    withAnimation {
                        offset = .zero
                        rotation = 0
                    }
                }
        )
        .animation(.easeInOut, value: offset)
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardView(user: UserModel(email: "test@edu", isEmailVerified: true, dormType: "On-Campus", budgetRange: "$500-$1000", sleepSchedule: "Flexible"), onSwipe: { _, _ in })
            .padding()
    }
}
