//
//  AppFonts.swift
//  Breaze
//
//  Created by Joseph Hardy
//  Copyright © 2023 Carquinez. All rights reserved.
//

import UIKit

/// AppFonts provides a centralized place to define and access all fonts used in the app.
/// Using this class instead of directly specifying fonts ensures consistency throughout the app
/// and makes it easier to update fonts globally.
public final class AppFonts {
    
    // MARK: - Title Fonts
    
    /// Large title font used for main headers (20pt bold)
    public static var title: UIFont {
        return .systemFont(ofSize: 20, weight: .bold)
    }
    
    /// Subtitle font used for secondary headers (18pt bold)
    public static var subtitle: UIFont {
        return .systemFont(ofSize: 18, weight: .bold)
    }
    
    // MARK: - Body Fonts
    
    /// Primary body text (16pt regular)
    public static var body: UIFont {
        return .systemFont(ofSize: 16, weight: .regular)
    }
    
    /// Secondary body text, usually smaller or less emphasized (14pt regular)
    public static var bodySecondary: UIFont {
        return .systemFont(ofSize: 14, weight: .regular)
    }
    
    // MARK: - Special Fonts
    
    /// Monospaced font used for timers and counters (12pt medium)
    public static var monospaced: UIFont {
        return .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Helper method to get scaled font for title with dynamic type support
    public static func scaledTitle() -> UIFont {
        let descriptor = title.fontDescriptor.withDesign(.default)!
        return UIFont.systemFont(ofSize: title.pointSize, weight: .bold)
            .with(traits: .traitBold)
    }
    
    /// Helper method to get scaled font for subtitle with dynamic type support
    public static func scaledSubtitle() -> UIFont {
        let descriptor = subtitle.fontDescriptor.withDesign(.default)!
        return UIFont.systemFont(ofSize: subtitle.pointSize, weight: .bold)
            .with(traits: .traitBold)
    }
    
    /// Helper method to get scaled font for body with dynamic type support
    public static func scaledBody() -> UIFont {
        let descriptor = body.fontDescriptor.withDesign(.default)!
        return UIFont.systemFont(ofSize: body.pointSize, weight: .regular)
    }
    
    /// Helper method to get scaled font for secondary body with dynamic type support
    public static func scaledBodySecondary() -> UIFont {
        let descriptor = bodySecondary.fontDescriptor.withDesign(.default)!
        return UIFont.systemFont(ofSize: bodySecondary.pointSize, weight: .regular)
    }
}

// MARK: - Helper Extensions

extension UIFont {
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}
