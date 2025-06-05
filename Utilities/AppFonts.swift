import UIKit

class AppFonts { // Consider renaming to AppTextStyles or AppAppearance

    struct TextStyle {
        let font: UIFont
        let color: UIColor
    }

    // MARK: - Text Styles

    private static let strongerSecondaryColor = UIColor { traitCollection -> UIColor in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(white: 0.75, alpha: 1.0) // Good secondary color for dark mode
        } else {
            return UIColor(white: 0.25, alpha: 1.0) // Darker gray for light mode
        }
    }

    static let title = TextStyle(
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .label
    )

    static let subtitleBold = TextStyle(
        font: .systemFont(ofSize: 17, weight: .bold),
        color: .label
    )

    static let bodyPrimary = TextStyle(
        font: .systemFont(ofSize: 18),
        color: .label
    )

    static let bodySecondary = TextStyle(
        font: .systemFont(ofSize: 16),
        color: strongerSecondaryColor
    )

    static let button = TextStyle(
        font: .systemFont(ofSize: 17, weight: .bold),
        color: .systemBlue
    )
    static let captionSecondary = TextStyle(
        font: .systemFont(ofSize: 15),
        color: strongerSecondaryColor
    )

    // Private initializer to prevent instantiation
    private init() {}
}
