# CLAUDE.md — Baby App

> Guide for Claude Code when working on this project.

## Project Overview

**Baby App** is a native iOS app for tracking baby care: sleep, feeding, diapers, development milestones, and an AI assistant (Claude) that acts as a pediatric nutritionist and development advisor.

**Baby**: Mattia Castillo Arrieta, born August 4, 2025, male.

## Stack

- **iOS**: SwiftUI, iOS 17+, Swift 5.9+
- **Backend**: Supabase (Auth, PostgreSQL, Edge Functions, Realtime)
- **AI**: Claude API via Supabase Edge Functions (claude-haiku-4-5 for chat, claude-sonnet-4-6 for analytics)
- **Dependencies**: supabase-swift (SPM)

## Development Workflow

1. **Windows**: Write Swift, SQL, TypeScript code. Push to GitHub.
2. **Mac (Intel 2019)**: Pull from GitHub, open Xcode, compile and run on simulator/device.
3. **Rule**: Never edit `.xcodeproj` or `.xcworkspace` files from Windows. Only Xcode manages those.
4. **Edge Functions**: Develop and deploy entirely from Windows using Supabase CLI.

## Project Structure

```
baby-app/
  BabyApp/                    # iOS app source
    App/                       # Entry point, root views, global state
    Core/Services/             # Supabase, Auth, AI, Sync, Notifications
    Core/Persistence/          # Offline store, Keychain
    Core/Utilities/            # Age calculator, WHO data, formatters
    Features/                  # Feature modules (Auth, Dashboard, Sleep, etc.)
    SharedUI/                  # Reusable components, theme
    Resources/                 # Assets, WHO growth data JSON
  BabyAppWidgets/              # WidgetKit extension
  supabase/                    # Backend
    migrations/                # SQL migrations (numbered)
    functions/                 # Edge Functions (TypeScript)
```

## Conventions

### Swift
- **Architecture**: MVVM with @Observable ViewModels
- **Naming**: PascalCase types, camelCase vars/funcs
- **Async**: Swift concurrency (async/await), no Combine unless necessary
- **Error handling**: Do/catch with proper error types. Never empty catch blocks.
- **File size**: Max 500 LOC per file, 50 LOC per function

### Supabase
- **Migrations**: Numbered `00001_description.sql`. Always include RLS policies.
- **Edge Functions**: TypeScript. Use shared/ for common code (Claude client, context builder).
- **RLS**: Every table must have Row Level Security. Use `get_user_family_ids()` helper.

### Git
- Commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:` prefixes
- Feature branches: `feature/sprint-N-description`
- Line endings: LF (enforced by .gitattributes)

## Key Domain Concepts

- **Family**: A group of users (parents) sharing access to baby data
- **Sleep Session**: Start/end times with optional wakings and bedtime routine
- **Feeding Log**: Breast (side + duration), bottle (oz), or solids
- **Food Catalog**: Per-food status tracking (approved/untried/watch/avoid) for allergy monitoring
- **Diaper Log**: Type (wet/dirty/both) with optional details
- **Growth Record**: Weight, height, head circumference with WHO percentile calculation
- **Milestone**: Developmental milestone with expected age range and achievement date
- **Night Mode**: Red-tinted UI with large buttons, auto-activates 8PM-7AM

## Important Paths

- Database schema: `supabase/migrations/00001_initial_schema.sql`
- RLS policies: `supabase/migrations/00002_rls_policies.sql`
- Supabase client: `BabyApp/Core/Services/SupabaseService.swift`
- Auth flow: `BabyApp/Features/Auth/`
- AI Edge Functions: `supabase/functions/ai-*/`
- WHO growth data: `BabyApp/Resources/WHO/`

## Testing

- Unit tests for all Service classes
- UI tests for critical flows: auth, sleep logging, feeding logging, diaper logging
- Edge Function tests with mock Claude responses

## Security Reminders

- NEVER put Anthropic API key in iOS code
- NEVER put Supabase service_role key in iOS code
- Store tokens in Keychain (KeychainHelper.swift)
- All Supabase tables must have RLS enabled
