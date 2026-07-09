import SwiftUI

struct LivingPreferencesSurveyView: View {
    @StateObject private var surveyModel = SurveyModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel

    
    private var bedtimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = Date()
        
        let startDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!
        var endDate = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: today)!
        
        // If end time is before start time, add 24 hours to end time
        if endDate < startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
        }
        
        return startDate...endDate
    }
    
    private var wakeupRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = Date()
        
        let startDate = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: today)!
        let endDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        
        return startDate...endDate
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Roommate Preferences")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textColor)
                        
                        Text("Question \(surveyModel.currentQuestionIndex + 1) of \(surveyModel.totalQuestions)")
                            .font(.subheadline)
                            .foregroundColor(Theme.textColor.opacity(0.8))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Progress bar
                    ProgressView(value: surveyModel.progress)
                        .tint(Theme.primaryColor)
                        .padding(.horizontal, 30)
                    
                    // Question content
                    ScrollView {
                        VStack(spacing: 30) {
                            switch surveyModel.currentQuestionIndex {
                            case 0:
                                QuestionView(
                                    question: "How often do you like to clean?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(CleaningFrequency.allCases, id: \.self) { frequency in
                                                SelectionButton(
                                                    title: frequency.rawValue,
                                                    isSelected: surveyModel.cleaningFrequency == frequency
                                                ) {
                                                    withAnimation {
                                                        surveyModel.cleaningFrequency = frequency
                                                    }
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            case 1:
                                QuestionView(
                                    question: "How do you prefer to handle chores?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(ChoresPreference.allCases, id: \.self) { preference in
                                                SelectionButton(
                                                    title: preference.rawValue,
                                                    isSelected: surveyModel.choresPreference == preference
                                                ) {
                                                    surveyModel.choresPreference = preference
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            case 2:
                                QuestionView(
                                    question: "What time do you like to go to bed?",
                                    content: AnyView(
                                        TimeSliderView(
                                            time: $surveyModel.bedtime,
                                            range: bedtimeRange,
                                            step: 30 * 60 // 30 minutes in seconds
                                        )
                                    )
                                )
                                
                            case 3:
                                QuestionView(
                                    question: "What time do you wake up?",
                                    content: AnyView(
                                        TimeSliderView(
                                            time: $surveyModel.wakeupTime,
                                            range: wakeupRange,
                                            step: 30 * 60 // 30 minutes in seconds
                                        )
                                    )
                                )
                                
                            case 4:
                                QuestionView(
                                    question: "Where do you prefer to study?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(StudyLocation.allCases, id: \.self) { location in
                                                SelectionButton(
                                                    title: location.rawValue,
                                                    isSelected: surveyModel.studyLocation == location
                                                ) {
                                                    surveyModel.studyLocation = location
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            case 5:
                                QuestionView(
                                    question: "How often do you go out?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(SocialFrequency.allCases, id: \.self) { frequency in
                                                SelectionButton(
                                                    title: frequency.rawValue,
                                                    isSelected: surveyModel.socialFrequency == frequency
                                                ) {
                                                    surveyModel.socialFrequency = frequency
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            case 6:
                                QuestionView(
                                    question: "What temperature do you like to keep the room at?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(RoomTemperature.allCases, id: \.self) { temp in
                                                SelectionButton(
                                                    title: temp.rawValue,
                                                    isSelected: surveyModel.roomTemperature == temp
                                                ) {
                                                    surveyModel.roomTemperature = temp
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            case 7:
                                QuestionView(
                                    question: "How do you feel about having guests over in the room?",
                                    content: AnyView(
                                        VStack(spacing: 12) {
                                            ForEach(GuestPreference.allCases, id: \.self) { preference in
                                                SelectionButton(
                                                    title: preference.rawValue,
                                                    isSelected: surveyModel.guestPreference == preference
                                                ) {
                                                    surveyModel.guestPreference = preference
                                                }
                                            }
                                        }
                                    )
                                )
                                
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 40)
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if surveyModel.currentQuestionIndex > 0 {
                            Button {
                                withAnimation {
                                    surveyModel.previousQuestion()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .fontWeight(.semibold)
                            }
                            .buttonStyle(.bordered)
                            .tint(Theme.primaryColor)
                        }
                        
                        Button {
                            if surveyModel.currentQuestionIndex == surveyModel.totalQuestions - 1 {
                                let preferences = surveyModel.toLivingPreferences()
                                
                                // Save preferences; on success appState moves to
                                // .profileSetup and ContentView navigates.
                                Task {
                                    await viewModel.updateLivingPreferences(preferences)
                                }
                            } else {
                                withAnimation {
                                    surveyModel.nextQuestion()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(surveyModel.currentQuestionIndex == surveyModel.totalQuestions - 1 ? "Finish" : "Next")
                                if surveyModel.currentQuestionIndex < surveyModel.totalQuestions - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .fontWeight(.semibold)
                        }
                        .primaryButtonStyle()
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        Rectangle()
                            .fill(Theme.backgroundColor)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct QuestionView: View {
    let question: String
    let content: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(question)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textColor)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .white : Theme.textColor)
                    .font(.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.primaryColor : Theme.secondaryColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Theme.primaryColor : Theme.textColor.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct TimeSliderView: View {
    @Binding var time: Date
    let range: ClosedRange<Date>
    let step: TimeInterval
    
    var body: some View {
        VStack(spacing: 16) {
            Text(timeFormatter.string(from: time))
                .font(.system(size: 36, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textColor)
                .frame(height: 44)
            
            Slider(
                value: Binding(
                    get: { time.timeIntervalSince1970 },
                    set: { time = Date(timeIntervalSince1970: $0) }
                ),
                in: range.lowerBound.timeIntervalSince1970...range.upperBound.timeIntervalSince1970,
                step: step
            )
            .tint(Theme.primaryColor)
        }
        .padding(.vertical, 20)
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

#Preview {
    NavigationStack {
        LivingPreferencesSurveyView()
            .environmentObject(AuthViewModel())
    }
} 
