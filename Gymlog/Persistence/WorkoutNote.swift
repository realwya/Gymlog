import Foundation
import SwiftData

@Model
final class WorkoutNote {
    @Attribute(.unique) var id: UUID

    // `rawText` stores the editable workout content and finalized workout
    // result. In-flight plan progress is persisted separately until the workout
    // is explicitly finished.
    var rawText: String
    var draftProgressData: Data?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        rawText: String = "",
        draftProgressData: Data? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.rawText = rawText
        self.draftProgressData = draftProgressData
        self.updatedAt = updatedAt
    }

    var draftProgressState: WorkoutDraftProgressState {
        get {
            guard let draftProgressData else {
                return WorkoutDraftProgressState()
            }

            return (try? JSONDecoder().decode(
                WorkoutDraftProgressState.self,
                from: draftProgressData
            )) ?? WorkoutDraftProgressState()
        }
        set {
            draftProgressData = try? JSONEncoder().encode(newValue)

            if newValue.isEmpty {
                draftProgressData = nil
            }
        }
    }

    func textSnapshot(
        reconcilingWith previous: WorkoutTextSnapshot? = nil
    ) -> WorkoutTextSnapshot {
        WorkoutTextSnapshot(
            rawText: rawText,
            reconcilingWith: previous
        )
    }

    func parsedText(
        reconcilingWith previous: WorkoutTextSnapshot? = nil
    ) -> WorkoutTextParseResult {
        WorkoutTextParser.parse(
            rawText: rawText,
            reconcilingWith: previous
        )
    }
}
