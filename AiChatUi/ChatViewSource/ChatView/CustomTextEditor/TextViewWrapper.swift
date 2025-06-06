//
//  D.swift
//  AiChatUi
//
//  Created by Measna on 18/5/25.
//

import SwiftUI

struct TextViewWrapper: UIViewRepresentable {
    @Environment(\.aiChatTheme) private var theme
    @Binding var text: String
    @Binding var height: CGFloat
    var fontSize: CGFloat = 16.0

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: fontSize)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = theme.colors.inputTextFG.toUIColor()
        textView.becomeFirstResponder()
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        TextViewWrapper.recalculateHeight(view: uiView, result: $height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $height)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var height: CGFloat

        init(text: Binding<String>, height: Binding<CGFloat>) {
            _text = text
            _height = height
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            TextViewWrapper.recalculateHeight(view: textView, result: $height)
        }
    }

    static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height
            }
        }
    }
}
