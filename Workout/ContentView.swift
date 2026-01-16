import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Text("TIFFIN")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("WORKOUT")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: CategorySelectionView()) {
                    Text("START WORKOUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                NavigationLink(destination: HistoryView()) {
                    Text("History")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
