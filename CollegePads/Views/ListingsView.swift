//
//  ListingsView.swift
//  CollegePads
//
//  Updated to use the global background gradient and theme typography for map and list views.
//  Hardcoded color references have been replaced with theme-based colors.
//
import SwiftUI
import MapKit

struct ListingsView: View {
    @StateObject private var viewModel = ListingsViewModel()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Listings with valid location.
    private var validListings: [ListingModel] {
        viewModel.listings.filter { $0.location != nil }
    }
    
    @State private var selectedListing: ListingModel? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // Interactive Map with custom annotations.
                Map(coordinateRegion: $region, annotationItems: validListings) { listing in
                    MapAnnotation(coordinate: listing.coordinate) {
                        Button(action: {
                            selectedListing = listing
                        }) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(AppTheme.primaryColor)
                                Text(listing.title)
                                    .font(AppTheme.bodyFont)
                                    .fixedSize()
                            }
                        }
                        .accessibilityLabel("Listing: \(listing.title)")
                    }
                }
                .frame(height: 300)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .padding()
                
                // Listings List
                List(viewModel.listings) { listing in
                    HStack {
                        if let urlStr = listing.imageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(AppTheme.defaultCornerRadius)
                                case .failure(_), .empty:
                                    AppTheme.cardBackground
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(AppTheme.defaultCornerRadius)
                                @unknown default:
                                    AppTheme.cardBackground
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(AppTheme.defaultCornerRadius)
                                }
                            }
                        } else {
                            AppTheme.cardBackground
                                .frame(width: 80, height: 80)
                                .cornerRadius(AppTheme.defaultCornerRadius)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(listing.title)
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.primary)
                            Text(listing.address)
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.secondaryColor)
                            Text("Rent: \(listing.rent)")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Listings")
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .onAppear {
                viewModel.fetchListings()
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
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
            .sheet(item: $selectedListing) { listing in
                ListingDetailView(listing: listing)
            }
        }
    }
}

struct ListingDetailView: View {
    let listing: ListingModel
    
    var body: some View {
        VStack(spacing: 20) {
            if let urlStr = listing.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        AppTheme.cardBackground
                    }
                }
                .frame(height: 200)
            }
            Text(listing.title)
                .font(AppTheme.titleFont)
            Text(listing.address)
                .font(AppTheme.bodyFont)
            Text("Rent: \(listing.rent)")
                .font(AppTheme.bodyFont)
            Spacer()
        }
        .padding()
    }
}

struct ListingsView_Previews: PreviewProvider {
    static var previews: some View {
        ListingsView()
    }
}
