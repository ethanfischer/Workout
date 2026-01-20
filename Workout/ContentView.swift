import SwiftUI

enum AppDestination: Hashable {
    case categorySelection
    case history
}

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
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

                Button {
                    navigationPath.append(AppDestination.categorySelection)
                } label: {
                    Text("START WORKOUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Button {
                    navigationPath.append(AppDestination.history)
                } label: {
                    Text("History")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .categorySelection:
                    CategorySelectionView(navigationPath: $navigationPath)
                case .history:
                    HistoryView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
