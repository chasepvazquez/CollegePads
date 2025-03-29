import Foundation

final class UniversityDataProvider {
    static let shared = UniversityDataProvider()
    private(set) var universities: [String] = []
    private var isLoaded = false

    private init() {}

    /// Loads the CSV from the app bundle asynchronously and caches the results.
    func loadUniversities(completion: @escaping ([String]) -> Void) {
        if isLoaded {
            print("Universities already loaded, returning cached list.")
            completion(universities)
        } else {
            DispatchQueue.global(qos: .background).async {
                guard let url = Bundle.main.url(forResource: "Most-Recent-Cohorts-Institution", withExtension: "csv") else {
                    print("CSV file not found in bundle!")
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                do {
                    let content = try String(contentsOf: url)
                    let lines = content.components(separatedBy: "\n")
                    guard let headerLine = lines.first else {
                        print("CSV header not found.")
                        DispatchQueue.main.async { completion([]) }
                        return
                    }
                    let headers = headerLine.components(separatedBy: ",")
                    // Look for "INSTNM" header (ignoring case and trimming whitespace)
                    guard let idx = headers.firstIndex(where: {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "INSTNM"
                    }) else {
                        print("Header 'INSTNM' not found in CSV: \(headers)")
                        DispatchQueue.main.async { completion([]) }
                        return
                    }
                    var collegeSet = Set<String>()
                    for line in lines.dropFirst() {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { continue }
                        let fields = trimmed.components(separatedBy: ",")
                        if fields.count > idx {
                            let college = fields[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                            if !college.isEmpty {
                                collegeSet.insert(college)
                            }
                        }
                    }
                    let sortedColleges = Array(collegeSet).sorted()
                    print("Loaded \(sortedColleges.count) unique colleges.")
                    self.universities = sortedColleges
                    self.isLoaded = true
                    DispatchQueue.main.async {
                        completion(sortedColleges)
                    }
                } catch {
                    print("Error reading CSV: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            }
        }
    }
}
