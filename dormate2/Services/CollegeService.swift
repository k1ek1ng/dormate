import Foundation

class CollegeService: ObservableObject {
    @Published var colleges: [College] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        loadColleges()
    }
    
    func loadColleges() {
        isLoading = true
        error = nil
        
        guard let url = Bundle.main.url(forResource: "Colleges_and_Universities", withExtension: "csv") else {
            error = NSError(domain: "CollegeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV file not found"])
            isLoading = false
            return
        }
        
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let rows = data.components(separatedBy: .newlines)
            
            // Skip header row
            let collegeRows = rows.dropFirst()
            
            colleges = collegeRows.compactMap { row in
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 6 else { return nil }
                
                return College(
                    name: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    city: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                    state: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                    zip: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                    county: columns[4].trimmingCharacters(in: .whitespacesAndNewlines),
                    alias: columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func searchColleges(query: String, searchBy: SearchCategory = .all) -> [College] {
        if query.isEmpty {
            return Array(colleges.prefix(50)) // Return first 50 colleges when no search term
        }
        
        let searchQuery = query.lowercased()
        
        return colleges.filter { college in
            switch searchBy {
            case .name:
                return college.name.lowercased().contains(searchQuery)
            case .city:
                return college.city.lowercased().contains(searchQuery)
            case .state:
                return college.state.lowercased().contains(searchQuery)
            case .zip:
                return college.zip.lowercased().contains(searchQuery)
            case .county:
                return college.county.lowercased().contains(searchQuery)
            case .alias:
                return college.alias.lowercased().contains(searchQuery)
            case .all:
                return college.name.lowercased().contains(searchQuery) ||
                       college.city.lowercased().contains(searchQuery) ||
                       college.state.lowercased().contains(searchQuery) ||
                       college.zip.lowercased().contains(searchQuery) ||
                       college.county.lowercased().contains(searchQuery) ||
                       college.alias.lowercased().contains(searchQuery)
            }
        }
    }
}

enum SearchCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case name = "Name"
    case city = "City"
    case state = "State"
    case zip = "ZIP"
    case county = "County"
    case alias = "Alias"
    
    var id: String { self.rawValue }
} 