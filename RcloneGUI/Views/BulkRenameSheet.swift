import SwiftUI
import RcloneKit

enum RenamePattern: String, CaseIterable {
    case prefix
    case suffix
    case number
    case findReplace

    var label: String {
        switch self {
        case .prefix: return L10n.t("bulkRename.prefix")
        case .suffix: return L10n.t("bulkRename.suffix")
        case .number: return L10n.t("bulkRename.number")
        case .findReplace: return L10n.t("bulkRename.findReplace")
        }
    }
}

struct BulkRenameSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let side: PanelSide

    @State private var pattern: RenamePattern = .prefix
    @State private var text1 = ""  // prefix/suffix/find/start number
    @State private var text2 = ""  // replace text
    @State private var isProcessing = false
    @State private var error: String?

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    private var selectedFiles: [FileItem] {
        tab.files.filter { tab.selectedFiles.contains($0.name) }
    }

    private var previews: [(old: String, new: String)] {
        selectedFiles.enumerated().map { index, file in
            let newName: String
            switch pattern {
            case .prefix:
                newName = "\(text1)\(file.name)"
            case .suffix:
                let ext = (file.name as NSString).pathExtension
                let base = (file.name as NSString).deletingPathExtension
                newName = ext.isEmpty ? "\(base)\(text1)" : "\(base)\(text1).\(ext)"
            case .number:
                let start = Int(text1) ?? 1
                let ext = (file.name as NSString).pathExtension
                let num = String(format: "%03d", start + index)
                newName = ext.isEmpty ? num : "\(num).\(ext)"
            case .findReplace:
                newName = file.name.replacingOccurrences(of: text1, with: text2)
            }
            return (file.name, newName)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("bulkRename.title")).font(.headline)

            // Pattern picker
            Picker(L10n.t("bulkRename.pattern"), selection: $pattern) {
                ForEach(RenamePattern.allCases, id: \.self) { p in
                    Text(p.label).tag(p)
                }
            }
            .pickerStyle(.segmented)

            // Input fields
            HStack {
                switch pattern {
                case .prefix:
                    TextField(L10n.t("bulkRename.prefixText"), text: $text1)
                        .textFieldStyle(.roundedBorder)
                case .suffix:
                    TextField(L10n.t("bulkRename.suffixText"), text: $text1)
                        .textFieldStyle(.roundedBorder)
                case .number:
                    TextField(L10n.t("bulkRename.startNum"), text: $text1)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                case .findReplace:
                    TextField(L10n.t("bulkRename.find"), text: $text1)
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "arrow.right")
                    TextField(L10n.t("bulkRename.replace"), text: $text2)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Preview
            GroupBox(L10n.t("bulkRename.preview")) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(previews, id: \.old) { preview in
                            HStack(spacing: 4) {
                                Text(preview.old)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                Text(preview.new)
                                    .font(.system(size: 11))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Text("\(selectedFiles.count)\(L10n.t("bulkRename.filesSelected"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isProcessing ? L10n.t("bulkRename.renaming") : L10n.t("bulkRename.apply")) {
                    performRename()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text1.isEmpty || isProcessing)
            }
        }
        .padding(20)
        .frame(width: 500, height: 450)
    }

    private func performRename() {
        isProcessing = true
        error = nil
        Task {
            do {
                for preview in previews where preview.old != preview.new {
                    try await appState.panels.rename(side: side, oldName: preview.old, newName: preview.new)
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isProcessing = false
        }
    }
}
