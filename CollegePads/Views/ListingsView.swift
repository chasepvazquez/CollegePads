//
//  ListingsView.swift
//  CollegePads
//
//  Updated to include interactive map annotations with callouts for listing details
//

import SwiftUI
import MapKit

struct ListingsView: View {
    @StateObject private var viewModel = ListingsViewModel()
    
    // Initial map region (San Francisco as an example)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Filter listings with a valid location
    private var validListings: [ListingModel] {
        viewModel.listings.filter { $0.location != nil }
    }
    
    // State for the selected listing to display details
    @State private var selectedListing: ListingModel? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Interactive Map with Custom Annotations
                Map(coordinateRegion: $region, annotationItems: validListings) { listing in
                    MapAnnotation(coordinate: listing.coordinate) {
                        Button(action: {
                            selectedListing = listing
                        }) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.red)
                                Text(listing.title)
                                    .font(.caption)
                                    .fixedSize()
                            }
                        }
                        .accessibilityLabel("Listing: \(listing.title)")
                    }
                }
                .frame(height: 300)
                .cornerRadius(15)
                .padding()
                
                // MARK: - Listings List
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
                                        .cornerRadius(8)
                                case .failure(_), .empty:
                                    Color.gray
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                @unknown default:
                                    Color.gray
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Color.gray
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(listing.title)
                                .font(.headline)
                            Text(listing.address)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Rent: \(listing.rent)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Listings")
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
                Alert(
                    title: Text("Error"),
                    message: Text(alertError.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Sheet to show detailed listing view when a marker is tapped.
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
                        Color.gray
                    }
                }
                .frame(height: 200)
            }
            Text(listing.title)
                .font(.largeTitle)
            Text(listing.address)
                .font(.title3)
            Text("Rent: \(listing.rent)")
                .font(.headline)
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
