import Foundation

final class UniversityDataProvider {
    static let shared = UniversityDataProvider()
    private(set) var universities: [String] = []
    private var isLoaded = false

    private init() {}

    /// Loads the CSV from the app bundle asynchronously and caches the results.
    func loadUniversities(completion: @escaping ([String]) -> Void) {
        if isLoaded {
            completion(universities)
        } else {
            DispatchQueue.global(qos: .background).async {
                guard let url = Bundle.main.url(forResource: "Most-Recent-Cohorts-Institution", withExtension: "csv") else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                do {
                    let content = try String(contentsOf: url)
                    let lines = content.components(separatedBy: "\n")
                    guard let headerLine = lines.first else {
                        DispatchQueue.main.async { completion([]) }
                        return
                    }
                    let headers = headerLine.components(separatedBy: ",")
                    // Look for "INSTNM" header (ignoring case and trimming whitespace)
                    guard let idx = headers.firstIndex(where: {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "INSTNM"
                    }) else {
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
                    self.universities = sortedColleges
                    self.isLoaded = true
                    DispatchQueue.main.async {
                        completion(sortedColleges)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            }
        }
    }
    
    /// Searches the cached list of universities using the given query.
    func searchUniversities(query: String) -> [String] {
        if query.isEmpty {
            return universities
        } else {
            return universities.filter { $0.lowercased().contains(query.lowercased()) }
        }
    }
}
