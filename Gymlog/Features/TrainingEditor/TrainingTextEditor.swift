import SwiftUI
import UIKit

struct TrainingTextEditor: UIViewRepresentable {
    @Binding var text: String

    var trackedLineIndices: Set<Int> = []
    var rightGutterWidth: CGFloat = 52
    var onSelectionContextChange: (TrainingEditorSelectionContext) -> Void = { _ in }
    var onTrackedLineRectsChange: ([Int: CGRect]) -> Void = { _ in }
    var onLineExit: (TrainingEditorLine, TrainingEditorLine) -> Void = { _, _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = text
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        textView.textColor = .label
        textView.tintColor = .systemBlue
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartInsertDeleteType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: rightGutterWidth)
        textView.textContainer.lineFragmentPadding = 0
        textView.accessibilityIdentifier = "training-text-editor"

        context.coordinator.publishEditorState(from: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        let expectedInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: rightGutterWidth)
        if uiView.textContainerInset != expectedInsets {
            uiView.textContainerInset = expectedInsets
        }

        if uiView.text != text {
            let selectionRange = TrainingEditorTextLayout.selectionRangePreservingLinePosition(
                from: uiView.text,
                to: text,
                selectedRange: uiView.selectedRange
            )

            uiView.text = text
            uiView.selectedRange = context.coordinator.clampedSelectedRange(
                selectionRange,
                in: text
            )
        }

        context.coordinator.publishEditorState(from: uiView)
    }
}

extension TrainingTextEditor {
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TrainingTextEditor
        private var lastPublishedLine: TrainingEditorLine?

        init(parent: TrainingTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            publishEditorState(from: textView)
        }

        func textViewDidChange(_ textView: UITextView) {
            if parent.text != textView.text {
                parent.text = textView.text
            }

            publishEditorState(from: textView)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            publishEditorState(from: textView)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let textView = scrollView as? UITextView else {
                return
            }

            publishEditorState(from: textView)
        }

        func publishEditorState(from textView: UITextView) {
            let selectedRange = clampedSelectedRange(textView.selectedRange, in: textView.text)

            if selectedRange != textView.selectedRange {
                textView.selectedRange = selectedRange
            }

            let currentLine = TrainingEditorTextLayout.line(
                containingUTF16Location: selectedRange.location,
                in: textView.text
            )

            if let previousLine = lastPublishedLine, previousLine.index != currentLine.index {
                parent.onLineExit(previousLine, currentLine)
            }

            lastPublishedLine = currentLine

            parent.onSelectionContextChange(
                TrainingEditorSelectionContext(
                    selectedRange: selectedRange,
                    currentLine: currentLine,
                    currentLineRect: lineRect(for: currentLine, in: textView)
                )
            )

            parent.onTrackedLineRectsChange(trackedLineRects(in: textView))
        }

        func clampedSelectedRange(
            _ selectedRange: NSRange,
            in text: String
        ) -> NSRange {
            let length = (text as NSString).length
            let location = min(max(selectedRange.location, 0), length)
            let selectedLength = min(max(selectedRange.length, 0), length - location)

            return NSRange(location: location, length: selectedLength)
        }

        private func trackedLineRects(in textView: UITextView) -> [Int: CGRect] {
            guard !parent.trackedLineIndices.isEmpty else {
                return [:]
            }

            let linesByIndex = Dictionary(
                uniqueKeysWithValues: TrainingEditorTextLayout.lines(in: textView.text).map { ($0.index, $0) }
            )

            return parent.trackedLineIndices.reduce(into: [:]) { result, lineIndex in
                guard
                    let line = linesByIndex[lineIndex],
                    let rect = lineRect(for: line, in: textView)
                else {
                    return
                }

                result[lineIndex] = rect
            }
        }

        private func lineRect(
            for line: TrainingEditorLine,
            in textView: UITextView
        ) -> CGRect? {
            guard
                let startPosition = textView.position(
                    from: textView.beginningOfDocument,
                    offset: line.contentRange.location
                )
            else {
                return nil
            }

            let caretRect = textView.caretRect(for: startPosition)
            guard !caretRect.isNull else {
                return nil
            }

            let insets = textView.textContainerInset
            let horizontalPadding = textView.textContainer.lineFragmentPadding
            let lineHeight = max(caretRect.height, textView.font?.lineHeight ?? 0)

            return CGRect(
                x: insets.left + horizontalPadding,
                y: caretRect.minY,
                width: max(textView.bounds.width - insets.left - insets.right - horizontalPadding * 2, 0),
                height: lineHeight
            )
        }
    }
}
