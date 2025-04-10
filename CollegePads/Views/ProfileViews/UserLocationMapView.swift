import SwiftUI
import MapKit

/// A simple map annotation model.
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

/// A SwiftUI view that displays a map with a “location bubble” at the coordinate.
struct UserLocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    let regionSpan: CLLocationDegrees = 0.05  // Adjust for desired zoom level.

    var body: some View {
        let region = MKCoordinateRegion(center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: regionSpan, longitudeDelta: regionSpan))
        Map(coordinateRegion: .constant(region),
            annotationItems: [MapAnnotationItem(coordinate: coordinate)]) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
        .padding()
    }
}

struct UserLocationMapView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCoordinate = CLLocationCoordinate2D(latitude: 44.98, longitude: -93.27)
        UserLocationMapView(coordinate: sampleCoordinate)
    }
}
