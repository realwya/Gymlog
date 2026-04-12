import Foundation

enum PlanWeight: Hashable, Comparable {
    case numeric(Double)
    case bodyweight

    init?(parsing rawText: String) {
        let normalized = rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
        case "bodyweight", "bw":
            self = .bodyweight
        default:
            guard let value = Double(normalized), value > 0 else {
                return nil
            }
            self = .numeric(value)
        }
    }

    var formattedText: String {
        switch self {
        case let .numeric(value):
            guard value.rounded() == value else {
                return String(value)
            }

            return String(Int(value))
        case .bodyweight:
            return "BW"
        }
    }

    static func < (lhs: PlanWeight, rhs: PlanWeight) -> Bool {
        switch (lhs, rhs) {
        case let (.numeric(lhsValue), .numeric(rhsValue)):
            return lhsValue < rhsValue
        case (.bodyweight, .numeric):
            return true
        case (.numeric, .bodyweight):
            return false
        case (.bodyweight, .bodyweight):
            return false
        }
    }
}

struct PlanLine: Identifiable, Hashable {
    let id: UUID
    let lineIndex: Int
    let exerciseBlockId: UUID
    let weight: PlanWeight
    let reps: Int
    let targetSets: Int
    let rawText: String

    init(
        id: UUID = UUID(),
        lineIndex: Int,
        exerciseBlockId: UUID,
        weight: PlanWeight,
        reps: Int,
        targetSets: Int,
        rawText: String
    ) {
        self.id = id
        self.lineIndex = lineIndex
        self.exerciseBlockId = exerciseBlockId
        self.weight = weight
        self.reps = reps
        self.targetSets = targetSets
        self.rawText = rawText
    }
    
    var formattedWeight: String {
        weight.formattedText
    }
}
