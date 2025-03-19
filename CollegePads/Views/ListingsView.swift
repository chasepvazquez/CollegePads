//
//  ListingsView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
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
    
    // Filter listings with valid coordinates
    private var validListings: [ListingModel] {
        viewModel.listings.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Map with Markers using annotationItems (simpler for compiler)
                Map(coordinateRegion: $region, annotationItems: validListings) { listing in
                    MapMarker(coordinate: listing.coordinate, tint: .red)
                }
                .frame(height: 300)
                .cornerRadius(15)
                .padding()
                
                // MARK: - Listings List
                List(viewModel.listings) { listing in
                    HStack {
                        // Display image if available
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
        }
    }
}

struct ListingsView_Previews: PreviewProvider {
    static var previews: some View {
        ListingsView()
    }
}
