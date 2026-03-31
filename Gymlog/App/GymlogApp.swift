import SwiftUI
import SwiftData

@main
struct GymlogApp: App {
    var body: some Scene {
        WindowGroup {
            TrainingEditorScreen()
        }
        .modelContainer(for: [
            WorkoutNote.self,
            ExerciseLibraryEntry.self,
        ])
    }
}
