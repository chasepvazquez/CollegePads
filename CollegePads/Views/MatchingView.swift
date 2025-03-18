//
//  MatchingView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MatchingView: View {
    var body: some View {
        SwipeDeckView()
            .navigationTitle("Swipe to Match")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Optional refresh action
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
    }
}

struct MatchingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MatchingView()
        }
    }
}
