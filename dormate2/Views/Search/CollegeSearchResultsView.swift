import SwiftUI

struct CollegeSearchResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var collegeService = CollegeService()
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @Binding var selectedCollege: College?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search colleges...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Search by", selection: $selectedCategory) {
                        ForEach(SearchCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                
                if collegeService.isLoading {
                    ProgressView()
                } else if let error = collegeService.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(collegeService.searchColleges(query: searchText, searchBy: selectedCategory)) { college in
                        Button(action: {
                            selectedCollege = college
                            dismiss()
                        }) {
                            VStack(alignment: .leading) {
                                Text(college.name)
                                    .font(.headline)
                                Text("\(college.city), \(college.state)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select College")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CollegeSearchResultsView(selectedCollege: .constant(nil))
} 