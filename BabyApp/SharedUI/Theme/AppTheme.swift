import SwiftUI

/// Centralized app theme: colors, typography, spacing.
enum AppTheme {
    // MARK: - Colors

    enum Colors {
        static let primary = Color.pink
        static let sleep = Color.indigo
        static let feeding = Color.orange
        static let diaper = Color.cyan
        static let development = Color.green
        static let ai = Color.pink
        static let nightMode = Color.red

        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
}
