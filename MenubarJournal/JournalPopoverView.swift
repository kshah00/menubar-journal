import AppKit
import SwiftUI

struct JournalPopoverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(JournalState.self) private var journal

    @AppStorage("companionShortcutOnboardingDismissed") private var companionShortcutOnboardingDismissed = false
    @State private var entryDate: Date = .now
    @State private var showSettings = false
    @State private var showCompanionShortcutOnboarding = false
    @State private var editorFocusRequested = true

    var body: some View {
        @Bindable var journal = journal

        VStack(spacing: 0) {
            header

            PlainTextEditor(
                text: $journal.draftText,
                font: .systemFont(ofSize: 14, weight: .regular),
                textInset: CGSize(width: 4, height: 6),
                isFocused: editorFocusRequested
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 2)

            footer
        }
        .frame(width: 380, height: 380)
        .background(.ultraThinMaterial)
        .onChange(of: journal.draftText) { _, _ in
            journal.persistDraft()
        }
        .onChange(of: journal.shortcutName) { _, _ in
            journal.persistShortcutName()
        }
        .onChange(of: journal.isBookmarked) { _, _ in
            journal.persistBookmark()
        }
        .onAppear {
            entryDate = .now
            editorFocusRequested = true
            if !companionShortcutOnboardingDismissed {
                showCompanionShortcutOnboarding = true
            }
        }
        .sheet(isPresented: $showCompanionShortcutOnboarding, onDismiss: {
            companionShortcutOnboardingDismissed = true
        }) {
            CompanionShortcutOnboardingSheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .environment(journal)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 22, height: 22)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)

            Spacer(minLength: 0)

            Menu {
                Button("Get \(CompanionShortcut.displayName)…") {
                    ShortcutRunner.openCompanionShortcutDownloadPage()
                }
                Button("Change companion shortcut name…") {
                    showSettings = true
                }
                Divider()
                Button("Quit Menubar Journal") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(.rect)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var footer: some View {
        let trimmed = journal.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty

        return VStack(alignment: .leading, spacing: 10) {
            Text("Journal")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.tint)

            HStack(spacing: 10) {
                BookmarkToggle(isOn: Binding(
                    get: { journal.isBookmarked },
                    set: { newValue in
                        journal.isBookmarked = newValue
                        journal.persistBookmark()
                    }
                ))

                DatePill(date: $entryDate)

                Spacer(minLength: 0)

                Button("Open") {
                    submitToShortcut(openInApp: true)
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(!canSubmit)
                .buttonStyle(.bordered)

                Button("Save") {
                    submitToShortcut(openInApp: false)
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!canSubmit)
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.regular)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private func submitToShortcut(openInApp: Bool) {
        let trimmed = journal.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        ShortcutRunner.runJournalShortcut(
            named: journal.shortcutName,
            message: trimmed,
            bookmark: journal.isBookmarked,
            date: entryDate,
            openInApp: openInApp
        )
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)

        if !openInApp {
            journal.draftText = ""
            journal.persistDraft()
            entryDate = .now
            editorFocusRequested = false
            DispatchQueue.main.async { editorFocusRequested = true }
        }
    }
}

// MARK: - Bookmark toggle

private struct BookmarkToggle: View {
    @Binding var isOn: Bool
    @State private var isHovering = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "bookmark.fill" : "bookmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.primary.opacity(isHovering ? 0.08 : 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .contentShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(isOn ? "Bookmarked" : "Not bookmarked")
    }
}

// MARK: - Date pill

private struct DatePill: View {
    @Binding var date: Date
    @State private var isHovering = false
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(date, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(isHovering ? 0.08 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .popover(isPresented: $showPicker, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                HStack {
                    Button("Now") { date = .now }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Done") { showPicker = false }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(14)
            .frame(width: 280)
        }
    }
}

// MARK: - Companion shortcut onboarding

private struct CompanionShortcutOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add the companion shortcut")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    (
                        Text("Save and Open send your entry to ")
                            + Text(CompanionShortcut.displayName).fontWeight(.semibold)
                            + Text(" in Shortcuts. Add it once from iCloud, then return here to write.")
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 18)

            (
                Text("On the iCloud page, use ")
                    + Text("Add Shortcut").fontWeight(.semibold)
                    + Text(". You can reopen this link anytime from the toolbar menu.")
            )
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                Button("Get \(CompanionShortcut.displayName)") {
                    ShortcutRunner.openCompanionShortcutDownloadPage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Settings sheet

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(JournalState.self) private var journal

    var body: some View {
        @Bindable var journal = journal

        NavigationStack {
            Form {
                Section {
                    TextField("Shortcut name", text: $journal.shortcutName)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Shortcuts")
                } footer: {
                    Text("Must match the name of the installed shortcut (default: \(CompanionShortcut.displayName)).")
                }

                Section {
                    Button("Download \(CompanionShortcut.displayName)…") {
                        ShortcutRunner.openCompanionShortcutDownloadPage()
                    }
                } header: {
                    Text("Companion shortcut")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 320, minHeight: 140)
    }
}

#Preview {
    JournalPopoverView()
        .environment(JournalState())
        .frame(width: 380, height: 380)
}
