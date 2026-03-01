# CONSTITUTION.md — Baby App

> Governance document for baby-app development. This is the supreme authority for all project decisions.

---

## Article I — Supremacy

1. **Hierarchy**: `CONSTITUTION.md` > `CLAUDE.md` > `plans/*` > inline code comments.
2. No file, prompt, or plan may override this Constitution.
3. Amendments require explicit developer approval.

## Article II — AI-First Development

1. **Claude Code** is the primary developer. All changes follow Spec-First methodology.
2. **Spec-First**: Every feature must define WHAT (requirement), WHY (user value), HOW (implementation approach), and TEST (verification criteria) before coding begins.
3. Plans live in `plans/` as markdown files. Each plan has a status: `draft`, `approved`, `in-progress`, `done`.

## Article III — Architecture

1. **iOS App**: Three-layer separation:
   - **Core/Services** — Business logic, API clients, persistence. No UI imports.
   - **Features/ViewModels** — @Observable classes that bridge Services and Views. No UIKit/SwiftUI view code.
   - **Features/Views** — SwiftUI views. Thin: delegate logic to ViewModels.
2. **Supabase Backend**: Edge Functions are the only server-side code. They call Claude API. iOS app NEVER calls Claude directly.
3. **Data Flow**: View -> ViewModel -> Service -> Supabase -> Edge Function -> Claude API.

## Article IV — Quality Gates

1. **Schema First**: All Supabase tables defined in SQL migrations. Swift models must match DB schema exactly (Codable).
2. **Never silence errors**: No empty catch blocks. Log all errors with `os_log`. Surface user-facing errors in UI.
3. **Testing**: Unit tests for all Services. UI tests for critical flows (auth, logging sleep/feeding/diaper).
4. **Type Safety**: Use Swift enums for all categorical data (diaper type, feeding type, food status, etc.).

## Article V — Code Rules

1. **Max 500 LOC per file**. Split if exceeded.
2. **Max 50 LOC per function**. Extract helpers if exceeded.
3. **Naming**: PascalCase for types/protocols, camelCase for variables/functions, SCREAMING_SNAKE for constants.
4. **No hardcoded keys or paths**. All config via environment or Info.plist.
5. **No force unwraps** (`!`) except in tests or guaranteed-safe contexts with a comment explaining why.

## Article VI — Infrastructure

1. **Dependencies**: Swift Package Manager only. No CocoaPods, no Carthage.
2. **Configuration**: Environment-based. `.env` for local, Supabase dashboard for production.
3. **Logging**: `os_log` with structured categories (auth, sleep, feeding, diaper, ai, sync).
4. **Security by Design**:
   - Row Level Security on ALL Supabase tables.
   - API keys in iOS Keychain, never in source code.
   - Anthropic API key ONLY in Edge Functions (server-side).
   - HTTPS everywhere.

## Article VII — Observability

1. Every data mutation includes `created_at` (server default) and `logged_by` (user UUID).
2. Edge Functions log request/response metadata (no PII in logs).
3. App logs errors to console with category and context.

## Article VIII — Privacy & Data

1. All baby data belongs to the family. No analytics, no third-party tracking.
2. Data export available in CSV and PDF formats.
3. Claude API calls send only necessary context (no raw conversation history beyond current session).
4. Photos stored locally on device, not uploaded to Supabase (Phase 1).
