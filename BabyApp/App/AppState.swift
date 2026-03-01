import SwiftUI
import Foundation

@Observable
final class AppState {
    // MARK: - Auth State
    var isAuthenticated = false
    var currentUserId: UUID?
    var currentFamilyId: UUID?

    // MARK: - Baby State
    var currentBaby: Baby?

    // MARK: - UI State
    var selectedTab = 0
    var isNightMode = false

    // MARK: - Active Timers
    var activeSleepSession: SleepSession?
    var activeBreastfeedingSession: FeedingLog?

    init() {
        updateNightMode()
    }

    // MARK: - Night Mode

    /// Auto-activates between 8PM and 7AM
    func updateNightMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        isNightMode = hour >= 20 || hour < 7
    }
}

// MARK: - Core Models

struct Baby: Codable, Identifiable, Sendable {
    let id: UUID
    let familyId: UUID
    let firstName: String
    let lastName: String?
    let dateOfBirth: Date
    let sex: Sex
    let birthWeightKg: Double?
    let birthHeightCm: Double?
    let birthHeadCircumferenceCm: Double?
    let bloodType: String?
    let notes: String?
    let photoUrl: String?
    let createdAt: Date
    let updatedAt: Date

    enum Sex: String, Codable, Sendable {
        case male
        case female
    }

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case sex
        case birthWeightKg = "birth_weight_kg"
        case birthHeightCm = "birth_height_cm"
        case birthHeadCircumferenceCm = "birth_head_circumference_cm"
        case bloodType = "blood_type"
        case notes
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Family: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FamilyMember: Codable, Identifiable, Sendable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let role: Role
    let displayName: String
    let createdAt: Date

    enum Role: String, Codable, Sendable {
        case admin
        case member
    }

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

struct SleepSession: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    var startTime: Date
    var endTime: Date?
    var type: SleepType
    var quality: SleepQuality?
    var notes: String?
    let loggedBy: UUID
    let createdAt: Date

    enum SleepType: String, Codable, Sendable {
        case night
        case nap
    }

    enum SleepQuality: String, Codable, Sendable {
        case good
        case fair
        case poor
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case type, quality, notes
        case loggedBy = "logged_by"
        case createdAt = "created_at"
    }

    var durationMinutes: Int? {
        guard let end = endTime else { return nil }
        return Int(end.timeIntervalSince(startTime) / 60)
    }
}

struct SleepWaking: Codable, Identifiable, Sendable {
    let id: UUID
    let sleepSessionId: UUID
    let time: Date
    var durationMinutes: Int?
    var reason: WakingReason?
    var notes: String?

    enum WakingReason: String, Codable, Sendable {
        case hungry
        case diaper
        case comfort
        case pain
        case unknown
        case other
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sleepSessionId = "sleep_session_id"
        case time
        case durationMinutes = "duration_minutes"
        case reason, notes
    }
}

struct FeedingLog: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let type: FeedingType
    var breastSide: BreastSide?
    var durationMinutes: Int?
    var amountOz: Double?
    var formulaBrand: String?
    var startTime: Date
    var endTime: Date?
    var notes: String?
    let loggedBy: UUID
    let createdAt: Date

    enum FeedingType: String, Codable, Sendable {
        case breast
        case bottle
        case solid
    }

    enum BreastSide: String, Codable, Sendable {
        case left
        case right
        case both
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case type
        case breastSide = "breast_side"
        case durationMinutes = "duration_minutes"
        case amountOz = "amount_oz"
        case formulaBrand = "formula_brand"
        case startTime = "start_time"
        case endTime = "end_time"
        case notes
        case loggedBy = "logged_by"
        case createdAt = "created_at"
    }
}

struct SolidFoodLog: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let foodName: String
    var preparation: Preparation?
    var amount: Amount?
    var reaction: Reaction
    var allergySymptoms: [String]?
    var allergySeverity: AllergySeverity?
    let eatenAt: Date
    var notes: String?
    let loggedBy: UUID

    enum Preparation: String, Codable, Sendable {
        case puree, mashed, chopped, whole, blw, other
    }

    enum Amount: String, Codable, Sendable {
        case taste, small, medium, large
    }

    enum Reaction: String, Codable, Sendable {
        case none, liked, disliked, neutral, allergic
    }

    enum AllergySeverity: String, Codable, Sendable {
        case mild, moderate, severe
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case foodName = "food_name"
        case preparation, amount, reaction
        case allergySymptoms = "allergy_symptoms"
        case allergySeverity = "allergy_severity"
        case eatenAt = "eaten_at"
        case notes
        case loggedBy = "logged_by"
    }
}

struct FoodCatalogItem: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let foodName: String
    let category: FoodCategory
    var status: FoodStatus
    var preference: FoodPreference?
    var firstTriedAt: Date?
    var allergyWatchUntil: Date?
    var notes: String?

    enum FoodCategory: String, Codable, Sendable {
        case fruit, vegetable, grain, protein, dairy, other
    }

    enum FoodStatus: String, Codable, Sendable {
        case approved, untried, watch, avoid
    }

    enum FoodPreference: String, Codable, Sendable {
        case loves, likes, neutral, dislikes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case foodName = "food_name"
        case category, status, preference
        case firstTriedAt = "first_tried_at"
        case allergyWatchUntil = "allergy_watch_until"
        case notes
    }
}

struct DiaperLog: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let type: DiaperType
    var consistency: Consistency?
    var color: DiaperColor?
    var hasBlood: Bool
    var hasMucus: Bool
    let changedAt: Date
    var notes: String?
    let loggedBy: UUID

    enum DiaperType: String, Codable, Sendable {
        case wet, dirty, both
    }

    enum Consistency: String, Codable, Sendable {
        case liquid, soft, formed, hard
    }

    enum DiaperColor: String, Codable, Sendable {
        case yellow, green, brown, black, red, white, other
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case type, consistency, color
        case hasBlood = "has_blood"
        case hasMucus = "has_mucus"
        case changedAt = "changed_at"
        case notes
        case loggedBy = "logged_by"
    }
}

struct GrowthRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let measuredAt: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var weightPercentile: Double?
    var heightPercentile: Double?
    var headPercentile: Double?
    var notes: String?
    let loggedBy: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case measuredAt = "measured_at"
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case headCircumferenceCm = "head_circumference_cm"
        case weightPercentile = "weight_percentile"
        case heightPercentile = "height_percentile"
        case headPercentile = "head_percentile"
        case notes
        case loggedBy = "logged_by"
    }
}

struct MilestoneDefinition: Codable, Identifiable, Sendable {
    let id: UUID
    let category: MilestoneCategory
    let title: String
    let description: String?
    let expectedMinMonths: Int
    let expectedMaxMonths: Int
    let sortOrder: Int

    enum MilestoneCategory: String, Codable, Sendable {
        case grossMotor = "gross_motor"
        case fineMotor = "fine_motor"
        case language
        case social
        case cognitive
    }

    enum CodingKeys: String, CodingKey {
        case id, category, title, description
        case expectedMinMonths = "expected_min_months"
        case expectedMaxMonths = "expected_max_months"
        case sortOrder = "sort_order"
    }
}

struct BabyMilestone: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let milestoneId: UUID
    var achievedAt: Date?
    var notes: String?
    let loggedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case milestoneId = "milestone_id"
        case achievedAt = "achieved_at"
        case notes
        case loggedBy = "logged_by"
    }
}

struct AIConversation: Codable, Identifiable, Sendable {
    let id: UUID
    let babyId: UUID
    let title: String?
    let type: ConversationType
    let createdBy: UUID
    let createdAt: Date

    enum ConversationType: String, Codable, Sendable {
        case chat
        case mealPlan = "meal_plan"
        case summary
        case development
    }

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case title, type
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct AIMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let conversationId: UUID
    let role: MessageRole
    let content: String
    let createdAt: Date

    enum MessageRole: String, Codable, Sendable {
        case user
        case assistant
    }

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role, content
        case createdAt = "created_at"
    }
}
