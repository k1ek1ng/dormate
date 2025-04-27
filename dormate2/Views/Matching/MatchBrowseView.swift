import SwiftUI

struct MatchCardView: View {
    let user: User
    @StateObject private var matchingService: MatchingService
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    init(user: User) {
        self.user = user
        _matchingService = StateObject(wrappedValue: MatchingService(currentUser: user))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile Image
            if let imageUrl = user.profileImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ZStack {
                        Color(.systemGray6)
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(height: 300)
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 60, height: 60)
                }
                .frame(height: 300)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Name, College and Match Percentage
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(user.college)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(matchingService.calculateMatchPercentage(with: user))%")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
                
                // Bio Preview
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                // Interests Preview
                if !user.interests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.interests.prefix(3), id: \.self) { interest in
                                Text(interest)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .clipShape(Capsule())
                            }
                            
                            if user.interests.count > 3 {
                                Text("+\(user.interests.count - 3)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8, x: 0, y: 2)
        .onAppear {
            if let currentUser = authViewModel.currentUser {
                matchingService.updateCurrentUser(currentUser)
            }
        }
    }
}

struct MatchBrowseView: View {
    let currentUser: User
    @StateObject private var matchingService: MatchingService
    @StateObject private var chatService: ChatService
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var currentMatch: User?
    @State private var showMatchDetail = false
    @State private var selectedTab = 0
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showMatchSuccess = false
    @State private var matchedUser: User?
    @Environment(\.dismiss) private var dismiss
    
    init(currentUser: User) {
        self.currentUser = currentUser
        _matchingService = StateObject(wrappedValue: MatchingService(currentUser: currentUser))
        _chatService = StateObject(wrappedValue: ChatService(currentUserId: currentUser.id))
    }
    
    private var browseTabContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let nextMatch = matchingService.getNextPotentialMatch() {
                    NavigationLink {
                        MatchDetailView(user: nextMatch, isIncomingMatch: false)
                            .environmentObject(authViewModel)
                    } label: {
                        MatchCardView(user: nextMatch)
                            .environmentObject(authViewModel)
                            .padding(.horizontal)
                    }
                    
                    // Match Actions
                    HStack(spacing: 60) {
                        Button {
                            matchingService.rejectUser(nextMatch)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "xmark")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button {
                            Task {
                                do {
                                    try await matchingService.likeUser(nextMatch)
                                    // Create a notification to refresh chat list
                                    NotificationCenter.default.post(name: NSNotification.Name("RefreshChatList"), object: nil)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No More Matches")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Check back later for new potential roommates!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var matchesTabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Incoming Match Requests Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Match Requests")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    if !matchingService.matchedByUsers.isEmpty {
                        ForEach(matchingService.matchedByUsers) { user in
                            VStack(spacing: 12) {
                                NavigationLink {
                                    MatchDetailView(user: user, isIncomingMatch: true)
                                        .environmentObject(authViewModel)
                                } label: {
                                    MatchCardView(user: user)
                                        .environmentObject(authViewModel)
                                }
                                
                                // Accept/Reject Buttons
                                HStack(spacing: 20) {
                                    Button {
                                        matchingService.rejectUser(user)
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Decline")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        Task {
                                            do {
                                                try await matchingService.likeUser(user)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showingError = true
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Accept")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No Match Requests")
                                .font(.headline)
                            Text("When someone likes your profile, they'll appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                
                // Confirmed Matches Section
                if !matchingService.matches.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Confirmed Matches")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(matchingService.matches) { user in
                            NavigationLink {
                                MatchDetailView(user: user, isIncomingMatch: false)
                                    .environmentObject(authViewModel)
                            } label: {
                                MatchCardView(user: user)
                                    .environmentObject(authViewModel)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Match Type", selection: $selectedTab) {
                    Text("Browse").tag(0)
                    Text("Matches").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    browseTabContent
                        .tag(0)
                    
                    matchesTabContent
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Find Roommates")
            .alert("Error", isPresented: $showingError) {
                Button("OK") { showingError = false }
            } message: {
                Text(errorMessage)
            }
            .task {
                do {
                    try await matchingService.loadMatchedByUsers()
                } catch {
                    errorMessage = "Failed to load matches: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct LivingPreferenceRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.body)
        }
    }
}

struct InterestTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purple.opacity(0.1))
            .foregroundColor(.purple)
            .cornerRadius(12)
    }
}

struct LivingPreferenceTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(10)
    }
}

struct MatchesListView: View {
    let matches: [User]
    let title: String
    let isIncomingMatches: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading matches...")
            } else if matches.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No matches yet")
                        .font(.headline)
                    Text("Keep browsing to find your perfect roommate!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List(matches) { user in
                    NavigationLink {
                        MatchDetailView(user: user, isIncomingMatch: isIncomingMatches)
                    } label: {
                        HStack {
                            if let imageUrl = user.profileImageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 50)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("\(user.firstName) \(user.lastName)")
                                    .font(.headline)
                                Text(user.college)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
}

struct MatchDetailView: View {
    let user: User
    let isIncomingMatch: Bool
    @StateObject private var matchingService: MatchingService
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionAlert = false
    @State private var actionType: MatchAction?
    @State private var showingError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    init(user: User, isIncomingMatch: Bool = false) {
        self.user = user
        self.isIncomingMatch = isIncomingMatch
        _matchingService = StateObject(wrappedValue: MatchingService(currentUser: user))
    }
    
    private var currentUser: User? {
        authViewModel.currentUser
    }
    
    enum MatchAction {
        case accept
        case reject
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = user.profileImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(20)
                        }
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 4)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(width: 220, height: 220)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(user.college)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.body)
                            .padding(.top, 8)
                    }
                    
                    if let preferences = user.livingPreferences {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Living Preferences")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 16)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                                LivingPreferenceTag(text: "Cleanliness: \(preferences.cleanliness)/5")
                                LivingPreferenceTag(text: "Noise: \(preferences.noiseLevel)/5")
                                LivingPreferenceTag(text: "Sleep: \(preferences.sleepSchedule)")
                                LivingPreferenceTag(text: "Guests: \(preferences.guests)")
                                LivingPreferenceTag(text: preferences.smoking ? "Smoking" : "Non-smoking")
                                LivingPreferenceTag(text: preferences.drinking ? "Drinking" : "Non-drinking")
                                LivingPreferenceTag(text: preferences.pets ? "Pets OK" : "No Pets")
                                LivingPreferenceTag(text: "Temp: \(preferences.temperature)/5")
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if !user.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Interests")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 16)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(user.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                if isIncomingMatch {
                    // Action Buttons for incoming matches
                    HStack(spacing: 40) {
                        Button {
                            actionType = .reject
                            showingActionAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Reject")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            actionType = .accept
                            showingActionAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Accept")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Match Details")
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage)
        }
        .alert(isPresented: $showingActionAlert) {
            switch actionType {
            case .accept:
                Alert(
                    title: Text("Accept Match"),
                    message: Text("Would you like to accept the match request from \(user.firstName)?"),
                    primaryButton: .default(Text("Accept")) {
                        Task {
                            do {
                                try await matchingService.likeUser(user)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .reject:
                Alert(
                    title: Text("Reject Match"),
                    message: Text("Would you like to reject the match request from \(user.firstName)?"),
                    primaryButton: .destructive(Text("Reject")) {
                        matchingService.rejectUser(user)
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            case .none:
                Alert(title: Text("Error"), message: Text("Unknown action"))
            }
        }
        .onAppear {
            if let currentUser = currentUser {
                matchingService.updateCurrentUser(currentUser)
            }
        }
    }
}

struct MatchSectionPreview: View {
    let title: String
    let count: Int
    let systemImage: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("\(count) \(count == 1 ? "person" : "people")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    NavigationStack {
        MatchBrowseView(currentUser: User(
            id: "preview",
            email: "preview@example.com",
            firstName: "Preview",
            lastName: "User",
            sex: "Male",
            college: "Example University",
            bio: "This is a preview user",
            interests: ["Hiking", "Music"],
            profileImageUrl: nil,
            livingPreferences: nil
        ))
        .environmentObject(AuthViewModel())
    }
} 