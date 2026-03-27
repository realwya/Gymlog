import SwiftUI

struct TrainingEditorScreen: View {
    @State private var noteText = """
    @卧推
    20 x 8 x 5
    最后两组感觉很重
    """

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("训练记录")
                    .font(.largeTitle.bold())

                Text("P0-1 最小骨架先提供一个可持续迭代的训练编辑宿主，后续再替换为 UIKit-backed 编辑器。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $noteText)
                    .font(.body.monospaced())
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(uiColor: .systemBackground))
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    TrainingEditorScreen()
}
