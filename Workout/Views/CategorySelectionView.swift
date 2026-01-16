import SwiftUI

struct CategorySelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("SELECT CATEGORY")
                .font(.headline)
                .padding(.top, 40)

            Spacer()

            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                NavigationLink(destination: ExerciseSelectionView(category: category)) {
                    Text(category.rawValue.uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
}
