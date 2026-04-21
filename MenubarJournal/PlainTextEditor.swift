import AppKit
import SwiftUI

/// `TextEditor` on macOS always shows its scrollers and keeps an opaque background,
/// so we wrap `NSTextView` directly to hide scrollers and match the popover surface.
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: NSFont = .systemFont(ofSize: 15)
    var textInset: CGSize = CGSize(width: 6, height: 8)
    var isFocused: Bool = false
    var onFocusChange: ((Bool) -> Void)? = nil

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        var isUpdatingFromBinding = false

        init(_ parent: PlainTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromBinding, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let container = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: .greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.heightTracksTextView = false
        layoutManager.addTextContainer(container)

        let textView = NSTextView(frame: .zero, textContainer: container)
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = textInset
        textView.font = font
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.smartInsertDeleteEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.string = text

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            context.coordinator.isUpdatingFromBinding = true
            let selected = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selected.filter { range in
                guard let r = range as? NSRange else { return false }
                return NSMaxRange(r) <= (text as NSString).length
            }
            context.coordinator.isUpdatingFromBinding = false
        }

        if textView.font != font {
            textView.font = font
        }

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }
}
