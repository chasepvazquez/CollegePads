// AddressLocationService.swift
// Combines address autocomplete and fuzzy geocoding into one service.

import Foundation
import MapKit
import CoreLocation
import Combine

/// Provides address autocomplete suggestions via MKLocalSearchCompleter
/// and also can geocode a selected address into a “fuzzy” coordinate.
class AddressLocationService: NSObject, ObservableObject {
    // MARK: - Autocomplete
    
    /// Autocomplete suggestions for the current query fragment.
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    /// The text fragment to autocomplete (e.g. what the user has typed).
    var queryFragment: String {
        get { completer.queryFragment }
        set { completer.queryFragment = newValue }
    }
    
    // MARK: - Geocoding
    
    private let geocoder = CLGeocoder()
    
    /// The approximate (fuzzy) coordinate obtained from geocoding a selected address.
    @Published var approximateCoordinate: CLLocationCoordinate2D?
    
    /// Any error encountered during geocoding or autocomplete.
    @Published var error: Error?
    
    override init() {
        super.init()
        completer.delegate = self
    }
    
    /// Call this when the user selects one of the autocomplete suggestions.
    /// It geocodes the full address string and publishes a fuzzy coordinate.
    func geocode(address: String) {
        self.error = nil
        self.approximateCoordinate = nil
        
        geocoder.geocodeAddressString(address) { [weak self] placemarks, geocodeError in
            guard let self = self else { return }
            if let geocodeError = geocodeError {
                DispatchQueue.main.async {
                    self.error = geocodeError
                }
                return
            }
            if let location = placemarks?.first?.location {
                let fuzzy = self.fuzzyCoordinate(for: location.coordinate)
                DispatchQueue.main.async {
                    self.approximateCoordinate = fuzzy
                }
            }
        }
    }
    
    /// Returns a “fuzzy” version of the coordinate by rounding lat/lon.
    /// Adjust `precision` for coarser or finer rounding.
    private func fuzzyCoordinate(for coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let precision: Double = 100.0  // 2 decimals (~1 km). Increase for coarser.
        let lat = (coordinate.latitude  * precision).rounded() / precision
        let lon = (coordinate.longitude * precision).rounded() / precision
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension AddressLocationService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
}
