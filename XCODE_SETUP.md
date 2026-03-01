# Xcode Project Setup (Mac)

Step-by-step instructions to create the Xcode project on your Mac Intel 2019.

## Prerequisites

- macOS Ventura or later
- Xcode 15+ (for iOS 17 and SwiftUI support)
- Apple Developer account (free for simulator testing)

## Step 1: Pull the Repo

```bash
cd ~/Projects
git clone https://github.com/jcastillobrieva/baby-app.git
cd baby-app
```

## Step 2: Create Xcode Project

1. Open Xcode
2. File > New > Project
3. Choose **App** (under iOS)
4. Configure:
   - Product Name: `BabyApp`
   - Team: Your Apple ID
   - Organization Identifier: `com.babyapp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use Supabase)
   - Include Tests: **Yes**
5. Save in the `baby-app/` directory (same level as the existing `BabyApp/` folder)
6. **Important**: When Xcode creates default files (ContentView.swift, BabyAppApp.swift), DELETE them — we already have our own in `BabyApp/App/`

## Step 3: Add Existing Files

1. In Xcode's project navigator, right-click the `BabyApp` group
2. "Add Files to BabyApp..."
3. Navigate to the `BabyApp/` folder and add ALL subfolders:
   - `App/`
   - `Core/`
   - `Features/`
   - `SharedUI/`
   - `Resources/`
4. Make sure "Create groups" is selected (not "Create folder references")
5. Check that target membership is set to `BabyApp`

## Step 4: Add WHO JSON Files as Resources

1. Select the `Resources/WHO/` group in Xcode
2. In the File Inspector, ensure all `.json` files have Target Membership checked for `BabyApp`

## Step 5: Add Swift Package (supabase-swift)

1. File > Add Package Dependencies...
2. Search: `https://github.com/supabase/supabase-swift`
3. Dependency Rule: Up to Next Major Version
4. Add to project: `BabyApp`
5. Select product: `Supabase`
6. Click "Add Package"

## Step 6: Configure Info.plist

Add these keys to your project's Info.plist (or via Build Settings > Info):

```xml
<key>SUPABASE_URL</key>
<string>https://YOUR_PROJECT.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>YOUR_ANON_KEY_HERE</string>
```

**To get these values:**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Settings > API
4. Copy the "Project URL" and "anon public" key

## Step 7: Add Widget Extension (Optional - Sprint 8)

1. File > New > Target
2. Choose **Widget Extension**
3. Product Name: `BabyAppWidgets`
4. Include Configuration Intent: No
5. Delete the auto-generated files and add the existing `BabyAppWidgets/BabyAppWidgets.swift`

## Step 8: Build & Run

1. Select an iOS 17+ simulator (iPhone 15 recommended)
2. Cmd+B to build
3. Fix any issues (usually package resolution)
4. Cmd+R to run

## Supabase Setup

Before the app can work, you need a Supabase project:

1. Go to https://supabase.com and create a new project
2. Go to SQL Editor
3. Run the migrations in order:
   - `supabase/migrations/00001_initial_schema.sql`
   - `supabase/migrations/00002_rls_policies.sql`
   - `supabase/migrations/00003_seed_milestones.sql`
4. Go to Settings > API and copy your URL + anon key into Info.plist
5. For Edge Functions, set up Supabase CLI on Windows and deploy

## Troubleshooting

- **"Missing SUPABASE_URL"**: Make sure Info.plist entries are correct
- **Package resolution fails**: File > Packages > Reset Package Caches
- **Build errors about missing modules**: Make sure `Supabase` package is added
- **Line ending warnings**: The `.gitattributes` enforces LF endings
