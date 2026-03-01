import Foundation

/// Calculates baby's age from date of birth.
enum AgeCalculator {
    struct Age: Sendable {
        let years: Int
        let months: Int
        let weeks: Int
        let days: Int
        let totalDays: Int
        let totalWeeks: Int
        let totalMonths: Int

        /// Human-readable age string in Spanish.
        var displayString: String {
            if years > 0 {
                let monthPart = months > 0 ? " y \(months) \(months == 1 ? "mes" : "meses")" : ""
                return "\(years) \(years == 1 ? "año" : "años")\(monthPart)"
            } else if totalMonths > 0 {
                let weekRemainder = weeks % 4
                let weekPart = weekRemainder > 0 ? " y \(weekRemainder) \(weekRemainder == 1 ? "semana" : "semanas")" : ""
                return "\(totalMonths) \(totalMonths == 1 ? "mes" : "meses")\(weekPart)"
            } else if totalWeeks > 0 {
                let dayRemainder = totalDays % 7
                let dayPart = dayRemainder > 0 ? " y \(dayRemainder) \(dayRemainder == 1 ? "día" : "días")" : ""
                return "\(totalWeeks) \(totalWeeks == 1 ? "semana" : "semanas")\(dayPart)"
            } else {
                return "\(totalDays) \(totalDays == 1 ? "día" : "días")"
            }
        }

        /// Short display: "7m" or "2a 3m"
        var shortString: String {
            if years > 0 {
                return months > 0 ? "\(years)a \(months)m" : "\(years)a"
            } else if totalMonths > 0 {
                return "\(totalMonths)m"
            } else if totalWeeks > 0 {
                return "\(totalWeeks)s"
            } else {
                return "\(totalDays)d"
            }
        }
    }

    /// Calculate age from date of birth to a reference date (defaults to now).
    static func calculate(from dateOfBirth: Date, to referenceDate: Date = Date()) -> Age {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .weekOfYear, .day],
            from: dateOfBirth,
            to: referenceDate
        )

        let totalDays = calendar.dateComponents([.day], from: dateOfBirth, to: referenceDate).day ?? 0
        let totalWeeks = totalDays / 7
        let totalMonths = calendar.dateComponents([.month], from: dateOfBirth, to: referenceDate).month ?? 0

        return Age(
            years: components.year ?? 0,
            months: components.month ?? 0,
            weeks: components.weekOfYear ?? 0,
            days: components.day ?? 0,
            totalDays: totalDays,
            totalWeeks: totalWeeks,
            totalMonths: totalMonths
        )
    }
}
