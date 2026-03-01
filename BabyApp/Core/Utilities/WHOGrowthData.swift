import Foundation

/// Calculates WHO growth percentiles for weight, height, and head circumference.
/// Uses LMS method (Lambda-Mu-Sigma) for percentile calculation.
enum WHOGrowthData {
    // MARK: - Percentile Calculation

    /// Calculate percentile using the LMS method.
    /// - Parameters:
    ///   - value: The measured value (weight in kg, height in cm, etc.)
    ///   - l: Lambda (Box-Cox transformation power)
    ///   - m: Mu (median)
    ///   - s: Sigma (coefficient of variation)
    /// - Returns: Percentile (0-100)
    static func calculatePercentile(value: Double, l: Double, m: Double, s: Double) -> Double {
        let z: Double
        if abs(l) < 0.001 {
            z = log(value / m) / s
        } else {
            z = (pow(value / m, l) - 1) / (l * s)
        }
        return normalCDF(z) * 100
    }

    /// Standard normal cumulative distribution function (approximation).
    private static func normalCDF(_ z: Double) -> Double {
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let p = 0.3275911

        let sign: Double = z < 0 ? -1 : 1
        let x = abs(z) / sqrt(2)
        let t = 1.0 / (1.0 + p * x)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x)

        return 0.5 * (1.0 + sign * y)
    }

    // MARK: - LMS Data Types

    struct LMSEntry: Codable {
        let ageMonths: Int
        let l: Double
        let m: Double
        let s: Double
    }

    enum Sex {
        case male
        case female
    }

    enum MeasurementType {
        case weight
        case height
        case headCircumference
    }

    // MARK: - Data Loading

    /// Load WHO LMS data from bundled JSON files.
    static func loadLMSData(sex: Sex, type: MeasurementType) -> [LMSEntry] {
        let sexPrefix = sex == .male ? "boys" : "girls"
        let typeString: String
        switch type {
        case .weight: typeString = "weight"
        case .height: typeString = "height"
        case .headCircumference: typeString = "head"
        }

        let filename = "who_\(sexPrefix)_\(typeString)"

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([LMSEntry].self, from: data)
        else {
            return []
        }

        return entries
    }

    // MARK: - Convenience

    /// Calculate percentile for a given measurement.
    static func percentile(
        value: Double,
        ageMonths: Int,
        sex: Sex,
        type: MeasurementType
    ) -> Double? {
        let data = loadLMSData(sex: sex, type: type)

        // Find closest age entry
        guard let entry = data.first(where: { $0.ageMonths == ageMonths })
                ?? data.min(by: { abs($0.ageMonths - ageMonths) < abs($1.ageMonths - ageMonths) })
        else {
            return nil
        }

        return calculatePercentile(value: value, l: entry.l, m: entry.m, s: entry.s)
    }
}
