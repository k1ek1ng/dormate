import Foundation

enum CleaningFrequency: String, CaseIterable {
    case daily = "Daily"
    case twiceWeek = "2-3 times a week"
    case weekly = "Once a week"
    case biweekly = "Every other week"
    case monthly = "Once a month"
}

enum ChoresPreference: String, CaseIterable {
    case schedule = "Fixed schedule for everyone"
    case flexible = "Flexible schedule based on availability"
    case immediate = "Clean up immediately after use"
    case weekly = "Weekly rotation of responsibilities"
}

enum StudyLocation: String, CaseIterable {
    case room = "In the room"
    case library = "Library"
    case commonAreas = "Common areas"
    case outside = "Outside campus"
}

enum SocialFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekends = "Only on weekends"
    case weekly = "Once a week"
    case monthly = "Once a month"
}

enum RoomTemperature: String, CaseIterable {
    case cold = "Cold"
    case medium = "Medium"
    case hot = "Hot"
}

enum GuestPreference: String, CaseIterable {
    case never = "Never"
    case occasionally = "Occasionally with advance notice"
    case weekendsOnly = "Weekends only"
    case anytime = "Anytime is fine"
}

class SurveyModel: ObservableObject {
    @Published var currentQuestionIndex = 0
    @Published var cleaningFrequency: CleaningFrequency?
    @Published var choresPreference: ChoresPreference?
    @Published var bedtime = Date()
    @Published var wakeupTime = Date()
    @Published var studyLocation: StudyLocation?
    @Published var socialFrequency: SocialFrequency?
    @Published var roomTemperature: RoomTemperature?
    @Published var guestPreference: GuestPreference?
    
    var totalQuestions: Int { 8 }
    var progress: Float { Float(currentQuestionIndex) / Float(totalQuestions) }
    
    func nextQuestion() {
        if currentQuestionIndex < totalQuestions - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func toLivingPreferences() -> LivingPreferences {
        // Convert cleaning frequency to a 1-5 scale
        let cleanliness: Int
        switch cleaningFrequency {
        case .daily: cleanliness = 5
        case .twiceWeek: cleanliness = 4
        case .weekly: cleanliness = 3
        case .biweekly: cleanliness = 2
        case .monthly: cleanliness = 1
        case .none: cleanliness = 3
        }
        
        // Convert noise level based on study location
        let noiseLevel: Int
        switch studyLocation {
        case .room: noiseLevel = 1
        case .library: noiseLevel = 2
        case .commonAreas: noiseLevel = 3
        case .outside: noiseLevel = 4
        case .none: noiseLevel = 3
        }
        
        // Convert bedtime to sleep schedule
        let calendar = Calendar.current
        let bedtimeHour = calendar.component(.hour, from: bedtime)
        let sleepSchedule = bedtimeHour < 12 ? "Early Bird" : "Night Owl"
        
        // Convert guest preference
        let guests: String
        switch guestPreference {
        case .never: guests = "Rare"
        case .occasionally: guests = "Occasional"
        case .weekendsOnly: guests = "Occasional"
        case .anytime: guests = "Frequent"
        case .none: guests = "Occasional"
        }
        
        // Convert temperature preference
        let temperature: Int
        switch roomTemperature {
        case .cold: temperature = 1
        case .medium: temperature = 3
        case .hot: temperature = 5
        case .none: temperature = 3
        }
        
        return LivingPreferences(
            cleanliness: cleanliness,
            noiseLevel: noiseLevel,
            sleepSchedule: sleepSchedule,
            guests: guests,
            smoking: false, // Default to false
            drinking: false, // Default to false
            pets: false, // Default to false
            temperature: temperature
        )
    }
} 