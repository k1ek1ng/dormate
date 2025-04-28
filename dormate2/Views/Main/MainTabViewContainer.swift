import SwiftUI

struct MainTabViewContainer: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showEditProfile = false
    @State private var showEditLivingPreferences = false
    @State private var activeSheet: ActiveSheet?
    @State private var showImagePicker = false
    @State private var uiImage: UIImage?
    
    enum ActiveSheet: Identifiable {
        case editBasicInfo
        case editLivingPreferences
        case editInterests
        
        var id: Int {
            switch self {
            case .editBasicInfo: return 0
            case .editLivingPreferences: return 1
            case .editInterests: return 2
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                if let currentUser = viewModel.currentUser {
                    MatchBrowseView(currentUser: currentUser)
                } else {
                    ProgressView("Loading...")
                }
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Matching")
            }
            .tag(0)
            
            NavigationView {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Messages")
            }
            .tag(1)
            
            NavigationView {
                ScrollView {
                    if let user = viewModel.currentUser {
                        VStack(spacing: 24) {
                            // Profile Header with Image
                            VStack(spacing: 16) {
                                // Profile Image
                                ZStack {
                                    if let uiImage = uiImage {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color(.systemGray5), lineWidth: 1)
                                            )
                                    } else if let imageUrl = user.profileImageUrl,
                                              let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 120, height: 120)
                                                    .background(Color(.systemGray5))
                                                    .clipShape(Circle())
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                                    )
                                            case .failure(_):
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 120, height: 120)
                                                    .foregroundColor(.gray)
                                                    .background(Color(.systemGray6))
                                                    .clipShape(Circle())
                                            @unknown default:
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 120, height: 120)
                                                    .foregroundColor(.gray)
                                                    .background(Color(.systemGray6))
                                                    .clipShape(Circle())
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(Theme.primaryColor)
                                            .background(Color(.systemGray6))
                                            .clipShape(Circle())
                                    }
                                    // Tap area
                                    Circle()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.clear)
                                        .contentShape(Circle())
                                        .onTapGesture {
                                            showImagePicker = true
                                        }
                                }
                                Text("Change Photo")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.primaryColor)
                                    .onTapGesture {
                                        showImagePicker = true
                                    }
                                // Name and College
                                VStack(spacing: 8) {
                                    Text("\(user.firstName) \(user.lastName)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text(user.college)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top)
                            
                            // Basic Info Section
                            GroupBox(label: HStack {
                                Label("Basic Information", systemImage: "person.text.rectangle")
                                Spacer()
                                Button {
                                    activeSheet = .editBasicInfo
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(Theme.primaryColor)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    InfoRow(title: "Email", value: user.email)
                                    InfoRow(title: "Sex", value: user.sex)
                                    if !user.bio.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Bio")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Text(user.bio)
                                                .font(.body)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal)
                            
                            // Interests Section
                            if !user.interests.isEmpty {
                                GroupBox(label: HStack {
                                    Label("Interests", systemImage: "heart.fill")
                                    Spacer()
                                    Button {
                                        activeSheet = .editInterests
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(Theme.primaryColor)
                                    }
                                }) {
                                    VStack(spacing: 16) {
                                        LazyVGrid(
                                            columns: [
                                                GridItem(.adaptive(minimum: 100), spacing: 12)
                                            ],
                                            spacing: 12
                                        ) {
                                            ForEach(user.interests, id: \.self) { interest in
                                                Text(interest)
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Theme.primaryColor.opacity(0.1))
                                                    .foregroundColor(Theme.primaryColor)
                                                    .cornerRadius(20)
                                                    .frame(height: 35)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Living Preferences Section
                            if let prefs = user.livingPreferences {
                                GroupBox(label: HStack {
                                    Label("Living Preferences", systemImage: "house.fill")
                                    Spacer()
                                    Button {
                                        activeSheet = .editLivingPreferences
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(Theme.primaryColor)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        InfoRow(title: "Cleanliness", value: String(prefs.cleanliness) + "/5")
                                        InfoRow(title: "Noise Level", value: String(prefs.noiseLevel) + "/5")
                                        InfoRow(title: "Sleep Schedule", value: prefs.sleepSchedule)
                                        InfoRow(title: "Guests", value: prefs.guests)
                                        InfoRow(title: "Temperature", value: String(prefs.temperature) + "/5")
                                        InfoRow(title: "Smoking", value: prefs.smoking ? "Yes" : "No")
                                        InfoRow(title: "Drinking", value: prefs.drinking ? "Yes" : "No")
                                        InfoRow(title: "Pets", value: prefs.pets ? "Yes" : "No")
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Sign Out Button
                            Button {
                                viewModel.signOut()
                            } label: {
                                Text("Sign Out")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                    } else {
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Loading profile...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
            .tag(2)
        }
        .tint(Theme.primaryColor)
        .onAppear {
            print("✅ MainTabView appeared. Current user: \(viewModel.currentUser?.firstName ?? "nil")")
            print("✅ App state: \(viewModel.appState)")
        }
        .sheet(isPresented: $showImagePicker, onDismiss: handleImagePicked) {
            ImagePicker(image: $uiImage)
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .editBasicInfo:
                    if let user = viewModel.currentUser {
                        EditBasicInfoView(user: user) { updatedUser in
                            viewModel.currentUser = updatedUser
                        }
                        .environmentObject(viewModel)
                    }
                case .editLivingPreferences:
                    if let user = viewModel.currentUser {
                        EditLivingPreferencesView(user: user) { updatedUser in
                            viewModel.currentUser = updatedUser
                        }
                        .environmentObject(viewModel)
                    }
                case .editInterests:
                    if let user = viewModel.currentUser {
                        EditInterestsView(user: user) { updatedUser in
                            viewModel.currentUser = updatedUser
                        }
                        .environmentObject(viewModel)
                    }
                }
            }
        }
    }
    
    private func handleImagePicked() {
        guard let uiImage = uiImage, var user = viewModel.currentUser else { return }
        Task {
            if let imageUrl = try? await viewModel.updateProfileImage(uiImage: uiImage) {
                user.profileImageUrl = imageUrl
                await viewModel.updateUserProfile(user: user)
                await MainActor.run {
                    viewModel.currentUser = user
                    self.uiImage = nil // Clear local image after upload
                }
            }
        }
    }
}

// Basic Info Edit View
struct EditBasicInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var firstName: String
    @State private var lastName: String
    @State private var sex: String
    @State private var college: String
    @State private var bio: String
    @State private var showCollegeSearch = false
    @State private var selectedCollege: College?
    @State private var uiImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let sexOptions = ["Male", "Female", "Other"]
    let user: User
    let onSave: (User) -> Void
    
    init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _sex = State(initialValue: user.sex)
        _college = State(initialValue: user.college)
        _bio = State(initialValue: user.bio)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileImageSection
                basicInfoSection
                bioSection
            }
            .padding(.horizontal)
        }
        .navigationTitle("Edit Basic Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveBasicInfo()
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $uiImage)
        }
        .sheet(isPresented: $showCollegeSearch) {
            CollegeSearchView(selectedCollege: $selectedCollege)
                .onDisappear {
                    if let college = selectedCollege {
                        self.college = college.name
                    }
                }
        }
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 12) {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else if let imageUrl = user.profileImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(Theme.primaryColor)
            }
            
            Button {
                showImagePicker = true
            } label: {
                Text("Change Photo")
                    .font(.subheadline)
                    .foregroundColor(Theme.primaryColor)
            }
        }
        .padding(.top, 20)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                CustomTextField(text: $firstName, title: "First Name", placeholder: "Enter your first name")
                CustomTextField(text: $lastName, title: "Last Name", placeholder: "Enter your last name")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sex")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("College")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button {
                        showCollegeSearch = true
                    } label: {
                        HStack {
                            Text(college.isEmpty ? "Select your college" : college)
                                .foregroundColor(college.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(15)
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Me")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(15)
    }
    
    private func saveBasicInfo() {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              !lastName.trimmingCharacters(in: .whitespaces).isEmpty,
              !college.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        Task {
            print("⏳ Starting basic info update...")
            
            // 1. Set loading state
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                print("✅ Loading state set to true")
            }
            
            // 2. Build updated user
            var updatedUser = user
            updatedUser.firstName = firstName.trimmingCharacters(in: .whitespaces)
            updatedUser.lastName = lastName.trimmingCharacters(in: .whitespaces)
            updatedUser.sex = sex
            updatedUser.college = college
            updatedUser.bio = bio
            
            // 3. Save to Firestore
            print("⏳ Saving to Firestore...")
            await viewModel.updateUserProfile(user: updatedUser)
            print("✅ Profile saved to Firestore")
            
            // 4. Update currentUser and call onSave
            await MainActor.run {
                viewModel.currentUser = updatedUser
                onSave(updatedUser)
                print("✅ currentUser updated and onSave called")
            }
            
            // 5. Handle image upload (optional)
            if let uiImage = uiImage {
                print("⏳ Uploading profile image...")
                if let imageUrl = try? await viewModel.updateProfileImage(uiImage: uiImage) {
                    updatedUser.profileImageUrl = imageUrl
                    await viewModel.updateUserProfile(user: updatedUser)
                    await MainActor.run {
                        viewModel.currentUser = updatedUser
                    }
                    print("✅ Profile image uploaded and user updated")
                }
            }
            
            // 6. Clear loading state and dismiss
            await MainActor.run {
                isLoading = false
                dismiss()
                print("✅ Loading state cleared and view dismissed")
            }
        }
    }
}

// Interests Edit View
struct EditInterestsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var selectedInterests: Set<String>
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let interestOptions: [String] = [
        "Writing", "Photography", "Painting/Drawing", "Music", "Dancing",
        "Baking/Cooking", "Hiking", "Fishing", "Travel", "Sports",
        "Fitness", "Working out", "Yoga", "Thrifting"
    ]
    
    let user: User
    let onSave: (User) -> Void
    
    init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        _selectedInterests = State(initialValue: Set(user.interests))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Your Interests")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(interestOptions, id: \.self) { interest in
                        InterestToggleButton(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest),
                            action: {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Edit Interests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveInterests()
                }
                .disabled(isLoading)
            }
        }
    }
    
    private func saveInterests() {
        Task {
            print("⏳ Starting interests update...")
            
            // 1. Set loading state
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                print("✅ Loading state set to true")
            }
            
            // 2. Build updated user
            var updatedUser = user
            updatedUser.interests = Array(selectedInterests)
            
            // 3. Save to Firestore
            print("⏳ Saving to Firestore...")
            await viewModel.updateUserProfile(user: updatedUser)
            print("✅ Profile saved to Firestore")
            
            // 4. Update currentUser and call onSave
            await MainActor.run {
                viewModel.currentUser = updatedUser
                onSave(updatedUser)
                print("✅ currentUser updated and onSave called")
            }
            
            // 5. Clear loading state and dismiss
            await MainActor.run {
                isLoading = false
                dismiss()
                print("✅ Loading state cleared and view dismissed")
            }
        }
    }
}

// Living Preferences Edit View
struct EditLivingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var cleanliness: Int
    @State private var noiseLevel: Int
    @State private var sleepSchedule: String
    @State private var guests: String
    @State private var temperature: Int
    @State private var smoking: Bool
    @State private var drinking: Bool
    @State private var pets: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]
    private let guestsOptions = ["Never", "Occasionally", "Frequently"]
    
    let user: User
    let onSave: (User) -> Void
    
    init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        
        let prefs = user.livingPreferences ?? LivingPreferences(
            cleanliness: 3,
            noiseLevel: 3,
            sleepSchedule: "Flexible",
            guests: "Occasionally",
            smoking: false,
            drinking: false,
            pets: false,
            temperature: 3
        )
        
        _cleanliness = State(initialValue: prefs.cleanliness)
        _noiseLevel = State(initialValue: prefs.noiseLevel)
        _sleepSchedule = State(initialValue: prefs.sleepSchedule)
        _guests = State(initialValue: prefs.guests)
        _temperature = State(initialValue: prefs.temperature)
        _smoking = State(initialValue: prefs.smoking)
        _drinking = State(initialValue: prefs.drinking)
        _pets = State(initialValue: prefs.pets)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Cleanliness
                PreferenceSlider(value: $cleanliness,
                               title: "Cleanliness",
                               subtitle: "How clean do you keep your space?",
                               range: 1...5)
                
                // Noise Level
                PreferenceSlider(value: $noiseLevel,
                               title: "Noise Level",
                               subtitle: "What noise level are you comfortable with?",
                               range: 1...5)
                
                // Sleep Schedule
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Schedule")
                        .font(.headline)
                    
                    Picker("Sleep Schedule", selection: $sleepSchedule) {
                        ForEach(sleepScheduleOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Guests
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guests")
                        .font(.headline)
                    
                    Picker("Guests", selection: $guests) {
                        ForEach(guestsOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Temperature
                PreferenceSlider(value: $temperature,
                               title: "Temperature",
                               subtitle: "What temperature do you prefer?",
                               range: 1...5)
                
                // Toggles
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Smoking", isOn: $smoking)
                    Toggle("Drinking", isOn: $drinking)
                    Toggle("Pets", isOn: $pets)
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.primaryColor))
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Living Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveLivingPreferences()
                }
                .disabled(isLoading)
            }
        }
    }
    
    private func saveLivingPreferences() {
        Task {
            print("⏳ Starting living preferences update...")
            
            // 1. Set loading state
            await MainActor.run {
                isLoading = true
                errorMessage = nil
                print("✅ Loading state set to true")
            }
            
            // 2. Build updated user
            var updatedUser = user
            updatedUser.livingPreferences = LivingPreferences(
                cleanliness: cleanliness,
                noiseLevel: noiseLevel,
                sleepSchedule: sleepSchedule,
                guests: guests,
                smoking: smoking,
                drinking: drinking,
                pets: pets,
                temperature: temperature
            )
            
            // 3. Save to Firestore
            print("⏳ Saving to Firestore...")
            await viewModel.updateUserProfile(user: updatedUser)
            print("✅ Profile saved to Firestore")
            
            // 4. Update currentUser and call onSave
            await MainActor.run {
                viewModel.currentUser = updatedUser
                onSave(updatedUser)
                print("✅ currentUser updated and onSave called")
            }
            
            // 5. Clear loading state and dismiss
            await MainActor.run {
                isLoading = false
                dismiss()
                print("✅ Loading state cleared and view dismissed")
            }
        }
    }
}

struct PreferenceSlider: View {
    @Binding var value: Int
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                ForEach(range, id: \.self) { number in
                    Button {
                        value = number
                    } label: {
                        Text("\(number)")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(value == number ? Theme.primaryColor : Color.clear)
                            .foregroundColor(value == number ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// Helper view for consistent info row styling
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    MainTabViewContainer()
        .environmentObject(AuthViewModel())
} 