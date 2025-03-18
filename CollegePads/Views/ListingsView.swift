//
//  ListingsView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import MapKit

struct ListingsView: View {
    @StateObject private var viewModel = ListingsViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Computed property to filter out listings with valid coordinates
    var validListings: [ListingModel] {
        viewModel.listings.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Map using new Map initializers with Marker
                Map(coordinateRegion: $region) {
                    ForEach(validListings) { listing in
                        Marker(
                            coordinate: CLLocationCoordinate2D(
                                latitude: listing.latitude ?? 0,
                                longitude: listing.longitude ?? 0
                            )
                        )
                    }
                }
                .frame(height: 300)
                .cornerRadius(15)
                .padding()
                
                // Listings List
                List(viewModel.listings) { listing in
                    HStack {
                        if let urlStr = listing.imageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                } else {
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
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct ListingsView_Previews: PreviewProvider {
    static var previews: some View {
        ListingsView()
    }
}
