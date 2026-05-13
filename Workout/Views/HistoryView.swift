import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    @State private var exportDocument: WorkoutHistoryDocument?
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var alertMessage: String?

    var body: some View {
        VStack {
            if workouts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No workouts yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Complete a workout to see it here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Import History") {
                        isImporterPresented = true
                    }
                    .foregroundColor(.pink)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: HistoryDetailView(workout: workout)) {
                                HistoryCard(workout: workout)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export History", systemImage: "square.and.arrow.up")
                    }
                    .disabled(workouts.isEmpty)

                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Import History", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename()
        ) { result in
            switch result {
            case .success:
                alertMessage = "Exported \(workouts.count) workout\(workouts.count == 1 ? "" : "s")."
            case .failure(let error):
                alertMessage = "Export failed: \(error.localizedDescription)"
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("History", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func prepareExport() {
        do {
            let data = try WorkoutHistoryExporter.encode(workouts: workouts)
            exportDocument = WorkoutHistoryDocument(data: data)
            isExporterPresented = true
        } catch {
            alertMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsScope = url.startAccessingSecurityScopedResource()
            defer {
                if needsScope { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let summary = try WorkoutHistoryExporter.importData(data, into: modelContext)
                alertMessage = "Imported \(summary.imported) workout\(summary.imported == 1 ? "" : "s"). Skipped \(summary.skippedDuplicates) duplicate\(summary.skippedDuplicates == 1 ? "" : "s")."
            } catch {
                alertMessage = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func defaultExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "tiffin-workouts-\(formatter.string(from: Date()))"
    }
}

struct WorkoutHistoryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct HistoryCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)

            HStack {
                Text("\(workout.category.rawValue) Day")
                Text("•")
                Text("\(workout.exercises.count) exercises")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("\(workout.durationSeconds / 60) min")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: [Workout.self, CompletedExercise.self, ExerciseSet.self])
}
