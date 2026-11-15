import CoreLocation

struct Waypoint: Identifiable, Codable {
    var id = UUID()
    var name: String
    var lat: Double
    var lon: Double
    var location: CLLocation { CLLocation(latitude: lat, longitude: lon) }
}

@MainActor
final class Nav: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var loc: CLLocation?
    @Published var heading: Double = 0
    @Published var points: [Waypoint] = [] { didSet { save() } }
    private let m = CLLocationManager()
    private let url = URL.documentsDirectory.appending(path: "points.json")

    override init() {
        super.init()
        if let d = try? Data(contentsOf: url), let p = try? JSONDecoder().decode([Waypoint].self, from: d) { points = p }
        m.delegate = self
        m.desiredAccuracy = kCLLocationAccuracyBest
        m.requestWhenInUseAuthorization()
        m.startUpdatingLocation()
        m.startUpdatingHeading()
    }

    private func save() { try? JSONEncoder().encode(points).write(to: url) }

    func addHere(_ name: String) {
        guard let l = loc else { return }
        let n = name.trimmingCharacters(in: .whitespaces)
        points.append(Waypoint(name: n.isEmpty ? "Точка \(points.count + 1)" : n,
                               lat: l.coordinate.latitude, lon: l.coordinate.longitude))
    }

    var direction: String {
        ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"][Int((heading + 22.5) / 45) % 8]
    }

    static func bearing(from a: CLLocation, to b: CLLocationCoordinate2D) -> Double {
        let p1 = a.coordinate.latitude * .pi / 180, p2 = b.latitude * .pi / 180
        let dl = (b.longitude - a.coordinate.longitude) * .pi / 180
        let y = sin(dl) * cos(p2)
        let x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    static func dist(_ m: Double) -> String {
        m < 1000 ? "\(Int(m)) м" : String(format: "%.1f км", m / 1000)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let l = locations.last
        Task { @MainActor in self.loc = l }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading h: CLHeading) {
        let v = h.trueHeading >= 0 ? h.trueHeading : h.magneticHeading
        Task { @MainActor in self.heading = v }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
}
