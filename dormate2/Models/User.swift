import Foundation
import FirebaseFirestore

public struct User: Identifiable {
    public let id: String
    public let email: String
    public var firstName: String
    public var lastName: String
    public var sex: String
    public var college: String
    public var bio: String
    public var interests: [String]
    public var profileImageUrl: String?
    public var livingPreferences: LivingPreferences?
    public var matches: [String]
    
    public var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    public init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        sex: String,
        college: String,
        bio: String,
        interests: [String],
        profileImageUrl: String? = nil,
        livingPreferences: LivingPreferences? = nil,
        matches: [String] = []
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        self.college = college
        self.bio = bio
        self.interests = interests
        self.profileImageUrl = profileImageUrl
        self.livingPreferences = livingPreferences
        self.matches = matches
    }
    
    public init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        guard let email = data["email"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let sex = data["sex"] as? String,
              let college = data["college"] as? String,
              let bio = data["bio"] as? String,
              let interests = data["interests"] as? [String] else {
            return nil
        }
        
        self.id = document.documentID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        self.college = college
        self.bio = bio
        self.interests = interests
        self.profileImageUrl = data["profileImageUrl"] as? String
        self.matches = data["matches"] as? [String] ?? []
        
        if let livingPrefsData = data["livingPreferences"] as? [String: Any] {
            self.livingPreferences = LivingPreferences(
                cleanliness: livingPrefsData["cleanliness"] as? Int ?? 3,
                noiseLevel: livingPrefsData["noiseLevel"] as? Int ?? 3,
                sleepSchedule: livingPrefsData["sleepSchedule"] as? String ?? "Early Bird",
                guests: livingPrefsData["guests"] as? String ?? "Occasional",
                smoking: livingPrefsData["smoking"] as? Bool ?? false,
                drinking: livingPrefsData["drinking"] as? Bool ?? false,
                pets: livingPrefsData["pets"] as? Bool ?? false,
                temperature: livingPrefsData["temperature"] as? Int ?? 3
            )
        }
    }
}

public struct LivingPreferences: Codable {
    public var cleanliness: Int // 1-5
    public var noiseLevel: Int // 1-5
    public var sleepSchedule: String // "Early Bird" or "Night Owl"
    public var guests: String // "Frequent", "Occasional", "Rare"
    public var smoking: Bool
    public var drinking: Bool
    public var pets: Bool
    public var temperature: Int // 1-5 (cold to hot)
    
    public init(
        cleanliness: Int,
        noiseLevel: Int,
        sleepSchedule: String,
        guests: String,
        smoking: Bool,
        drinking: Bool,
        pets: Bool,
        temperature: Int
    ) {
        self.cleanliness = cleanliness
        self.noiseLevel = noiseLevel
        self.sleepSchedule = sleepSchedule
        self.guests = guests
        self.smoking = smoking
        self.drinking = drinking
        self.pets = pets
        self.temperature = temperature
    }
} 