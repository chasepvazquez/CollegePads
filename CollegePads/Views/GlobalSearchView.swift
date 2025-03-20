//
//  GlobalSearchView.swift
//  CollegePads
//
//  This view presents the Global Search interface.
//  Users can enter a search query, choose between "Users" or "Listings", and view matching results.
//  Tapping the "Search" button or pressing return in the text field triggers the search.
//

import SwiftUI

struct GlobalSearchView: View {
    @StateObject private var viewModel = GlobalSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search...", text: $viewModel.query, onCommit: {
                        viewModel.performSearch()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("Global search field")
                }
                .padding()
                
                // Segmented Control for Search Type
                Picker("Search Type", selection: $viewModel.searchType) {
                    ForEach(SearchType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Loading Indicator or Error Message
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // List of Search Results
                    List {
                        if viewModel.searchType == .users {
                            ForEach(viewModel.userResults) { user in
                                VStack(alignment: .leading) {
                                    Text(user.email)
                                        .font(.headline)
                                    // Additional user details can be displayed here.
                                }
                            }
                        } else {
                            ForEach(viewModel.listingResults) { listing in
                                VStack(alignment: .leading) {
                                    Text(listing.title)
                                        .font(.headline)
                                    Text(listing.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Global Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        viewModel.performSearch()
                    }
                    .accessibilityLabel("Perform search")
                }
            }
        }
    }
}

struct GlobalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSearchView()
    }
}
