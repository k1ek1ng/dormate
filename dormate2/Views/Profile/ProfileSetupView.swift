import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var sex = "Male"
    @State private var selectedCollege: College?
    @State private var bio = ""
    @State private var selectedInterests: Set<String> = []
    @State private var uiImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCollegeSearch = false
    @State private var showMainView = false

    private let sexOptions = ["Male", "Female", "Other"]
    private let interestOptions: [String] = [
        "Writing", "Photography", "Painting/Drawing", "Music", "Dancing",
        "Baking/Cooking", "Hiking", "Fishing", "Travel", "Sports",
        "Fitness", "Working out", "Yoga", "Thrifting"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileImageSection
                    basicInfoSection
                    bioSection
                    interestsSection
                    completeButton

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $uiImage)
        }
        .sheet(isPresented: $showCollegeSearch) {
            CollegeSearchView(selectedCollege: $selectedCollege)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainTabViewContainer()
                .environmentObject(viewModel)
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
                Text("Select Photo")
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
                            Text(selectedCollege?.name ?? "Select your college")
                                .foregroundColor(selectedCollege == nil ? .gray : .primary)
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

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
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
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(15)
    }

    private var completeButton: some View {
        Button {
            Task {
                await completeProfileSetup()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Complete Profile Setup")
                    .fontWeight(.semibold)
            }
        }
        .primaryButtonStyle()
        .disabled(viewModel.isLoading)
        .padding(.top, 20)
    }

    private func completeProfileSetup() async {
        // Validate required fields
        guard !firstName.isEmpty, !lastName.isEmpty, !sex.isEmpty, selectedCollege != nil else {
            viewModel.errorMessage = "Please fill in all required fields"
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        // Build updated user object
        let updatedUser = User(
            id: viewModel.currentUser?.id ?? "",
            email: viewModel.currentUser?.email ?? "",
            firstName: firstName,
            lastName: lastName,
            sex: sex,
            college: selectedCollege?.name ?? "",
            bio: bio,
            interests: Array(selectedInterests),
            profileImageUrl: viewModel.currentUser?.profileImageUrl,
            livingPreferences: viewModel.currentUser?.livingPreferences
        )
        
        // Save to Firestore
        await viewModel.updateUserProfile(user: updatedUser)
        
        // Check if the update was successful
        if viewModel.errorMessage == nil {
            showMainView = true
        }
        
        viewModel.isLoading = false
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.primary)
            .font(.body)
    }
}

struct InterestToggleButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Theme.primaryColor : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : Theme.primaryColor)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            isSelected ? Theme.primaryColor : Theme.primaryColor.opacity(0.3),
                            lineWidth: isSelected ? 0 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
       ProfileSetupView()
            .environmentObject(AuthViewModel())
    }
}


