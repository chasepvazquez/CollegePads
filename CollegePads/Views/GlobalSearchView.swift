import SwiftUI

struct GlobalSearchView: View {
    @StateObject private var viewModel = GlobalSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.secondaryColor)
                    TextField("Search...", text: $viewModel.query, onCommit: {
                        viewModel.performSearch()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(AppTheme.bodyFont)
                    .accessibilityLabel("Global search field")
                }
                .padding()
                
                // Segmented Control for Search Type
                Picker("Search Type", selection: $viewModel.searchType) {
                    ForEach(SearchType.allCases) { type in
                        Text(type.rawValue)
                            .font(AppTheme.bodyFont)
                            .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Loading Indicator or Error Message
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .font(AppTheme.bodyFont)
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.accentColor)
                        .padding()
                } else {
                    // List of Search Results
                    List {
                        if viewModel.searchType == .users {
                            ForEach(viewModel.userResults) { user in
                                VStack(alignment: .leading) {
                                    Text(user.email)
                                        .font(AppTheme.titleFont)
                                    // Additional user details can be added here.
                                }
                            }
                        } else {
                            ForEach(viewModel.listingResults) { listing in
                                VStack(alignment: .leading) {
                                    Text(listing.title)
                                        .font(AppTheme.titleFont)
                                    Text(listing.address)
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
                
                Spacer()
            }
            .font(AppTheme.bodyFont)
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Global Search")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        viewModel.performSearch()
                    }
                    .font(AppTheme.bodyFont)
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
