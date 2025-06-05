import UIKit

class AppFonts { // Consider renaming to AppTextStyles or AppAppearance

    struct TextStyle {
        let font: UIFont
        let color: UIColor
    }

    // MARK: - Text Styles

    static let title = TextStyle(
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .label
    )

    static let subtitleBold = TextStyle(
        font: .systemFont(ofSize: 17, weight: .bold),
        color: .label
    )

    static let bodyPrimary = TextStyle(
        font: .systemFont(ofSize: 16),
        color: .label
    )

    static let bodySecondary = TextStyle(
        font: .systemFont(ofSize: 16),
        color: .secondaryLabel
    )

    static let captionSecondary = TextStyle(
        font: .systemFont(ofSize: 15),
        color: .secondaryLabel
    )

    // Private initializer to prevent instantiation
    private init() {}
}
