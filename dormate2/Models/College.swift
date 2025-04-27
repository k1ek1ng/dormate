import Foundation

struct College: Identifiable {
    let id = UUID()
    let name: String
    let city: String
    let state: String
    let zip: String
    let county: String
    let alias: String
    
    var displayName: String {
        "\(name), \(city), \(state)"
    }
    
    static func == (lhs: College, rhs: College) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 