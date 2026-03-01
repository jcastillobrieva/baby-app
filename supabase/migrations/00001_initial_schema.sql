-- ============================================================
-- Baby App — Initial Schema
-- ============================================================

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ============================================================
-- FAMILIES & MEMBERS
-- ============================================================

create table families (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table family_members (
    id uuid primary key default uuid_generate_v4(),
    family_id uuid not null references families(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null default 'member' check (role in ('admin', 'member')),
    display_name text not null,
    created_at timestamptz not null default now(),
    unique(family_id, user_id)
);

create table family_invites (
    id uuid primary key default uuid_generate_v4(),
    family_id uuid not null references families(id) on delete cascade,
    invited_by uuid not null references auth.users(id),
    email text not null,
    role text not null default 'member' check (role in ('admin', 'member')),
    status text not null default 'pending' check (status in ('pending', 'accepted', 'expired')),
    token text not null unique default encode(gen_random_bytes(32), 'hex'),
    created_at timestamptz not null default now(),
    expires_at timestamptz not null default (now() + interval '7 days')
);

-- ============================================================
-- BABIES
-- ============================================================

create table babies (
    id uuid primary key default uuid_generate_v4(),
    family_id uuid not null references families(id) on delete cascade,
    first_name text not null,
    last_name text,
    date_of_birth date not null,
    sex text not null check (sex in ('male', 'female')),
    birth_weight_kg numeric(4,2),
    birth_height_cm numeric(5,2),
    birth_head_circumference_cm numeric(5,2),
    blood_type text,
    notes text,
    photo_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ============================================================
-- SLEEP TRACKING
-- ============================================================

create table sleep_sessions (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    start_time timestamptz not null,
    end_time timestamptz,
    type text not null default 'night' check (type in ('night', 'nap')),
    quality text check (quality in ('good', 'fair', 'poor')),
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table sleep_wakings (
    id uuid primary key default uuid_generate_v4(),
    sleep_session_id uuid not null references sleep_sessions(id) on delete cascade,
    time timestamptz not null,
    duration_minutes int,
    reason text check (reason in ('hungry', 'diaper', 'comfort', 'pain', 'unknown', 'other')),
    notes text,
    created_at timestamptz not null default now()
);

create table bedtime_routines (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    sleep_session_id uuid references sleep_sessions(id) on delete set null,
    date date not null,
    bath boolean not null default false,
    pajamas boolean not null default false,
    diaper_change boolean not null default false,
    bottle boolean not null default false,
    story boolean not null default false,
    song boolean not null default false,
    white_noise boolean not null default false,
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now()
);

-- ============================================================
-- FEEDING
-- ============================================================

create table feeding_logs (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    type text not null check (type in ('breast', 'bottle', 'solid')),
    -- Breast feeding fields
    breast_side text check (breast_side in ('left', 'right', 'both')),
    duration_minutes int,
    -- Bottle feeding fields
    amount_oz numeric(4,1),
    formula_brand text,
    -- Common
    start_time timestamptz not null,
    end_time timestamptz,
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table solid_food_logs (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    food_name text not null,
    preparation text check (preparation in ('puree', 'mashed', 'chopped', 'whole', 'blw', 'other')),
    amount text check (amount in ('taste', 'small', 'medium', 'large')),
    reaction text not null default 'none' check (reaction in ('none', 'liked', 'disliked', 'neutral', 'allergic')),
    -- Allergy tracking
    allergy_symptoms text[], -- e.g. ['rash', 'vomiting', 'diarrhea']
    allergy_severity text check (allergy_severity in ('mild', 'moderate', 'severe')),
    eaten_at timestamptz not null,
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now()
);

create table food_catalog (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    food_name text not null,
    category text not null check (category in ('fruit', 'vegetable', 'grain', 'protein', 'dairy', 'other')),
    status text not null default 'untried' check (status in ('approved', 'untried', 'watch', 'avoid')),
    preference text check (preference in ('loves', 'likes', 'neutral', 'dislikes')),
    first_tried_at timestamptz,
    allergy_watch_until timestamptz, -- 3-day monitoring window
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(baby_id, food_name)
);

-- ============================================================
-- DIAPER TRACKING
-- ============================================================

create table diaper_logs (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    type text not null check (type in ('wet', 'dirty', 'both')),
    consistency text check (consistency in ('liquid', 'soft', 'formed', 'hard')),
    color text check (color in ('yellow', 'green', 'brown', 'black', 'red', 'white', 'other')),
    has_blood boolean not null default false,
    has_mucus boolean not null default false,
    changed_at timestamptz not null default now(),
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now()
);

-- ============================================================
-- GROWTH & DEVELOPMENT
-- ============================================================

create table growth_records (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    measured_at date not null,
    weight_kg numeric(5,2),
    height_cm numeric(5,2),
    head_circumference_cm numeric(5,2),
    weight_percentile numeric(5,2),
    height_percentile numeric(5,2),
    head_percentile numeric(5,2),
    notes text,
    logged_by uuid not null references auth.users(id),
    created_at timestamptz not null default now()
);

create table milestone_definitions (
    id uuid primary key default uuid_generate_v4(),
    category text not null check (category in ('gross_motor', 'fine_motor', 'language', 'social', 'cognitive')),
    title text not null,
    description text,
    expected_min_months int not null,
    expected_max_months int not null,
    sort_order int not null default 0
);

create table baby_milestones (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    milestone_id uuid not null references milestone_definitions(id) on delete cascade,
    achieved_at date,
    notes text,
    logged_by uuid references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(baby_id, milestone_id)
);

-- ============================================================
-- AI CONVERSATIONS
-- ============================================================

create table ai_conversations (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    title text,
    type text not null default 'chat' check (type in ('chat', 'meal_plan', 'summary', 'development')),
    created_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table ai_messages (
    id uuid primary key default uuid_generate_v4(),
    conversation_id uuid not null references ai_conversations(id) on delete cascade,
    role text not null check (role in ('user', 'assistant')),
    content text not null,
    metadata jsonb,
    created_at timestamptz not null default now()
);

-- ============================================================
-- MEAL PLANNING
-- ============================================================

create table meal_plans (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    week_start date not null,
    week_end date not null,
    status text not null default 'draft' check (status in ('draft', 'active', 'completed')),
    grocery_list jsonb, -- structured list from AI
    notes text,
    created_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table meal_plan_items (
    id uuid primary key default uuid_generate_v4(),
    meal_plan_id uuid not null references meal_plans(id) on delete cascade,
    day_of_week int not null check (day_of_week between 0 and 6), -- 0=Sunday
    meal_type text not null check (meal_type in ('breakfast', 'morning_snack', 'lunch', 'afternoon_snack', 'dinner')),
    food_name text not null,
    preparation text,
    amount text,
    notes text,
    sort_order int not null default 0
);

-- ============================================================
-- DAILY PLANNING
-- ============================================================

create table daily_plans (
    id uuid primary key default uuid_generate_v4(),
    baby_id uuid not null references babies(id) on delete cascade,
    date date not null,
    template_name text,
    notes text,
    created_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(baby_id, date)
);

create table plan_items (
    id uuid primary key default uuid_generate_v4(),
    daily_plan_id uuid not null references daily_plans(id) on delete cascade,
    scheduled_time time,
    type text not null check (type in ('sleep', 'feed', 'diaper', 'play', 'bath', 'medicine', 'other')),
    title text not null,
    description text,
    completed boolean not null default false,
    completed_at timestamptz,
    sort_order int not null default 0
);

-- ============================================================
-- HELPER FUNCTION
-- ============================================================

-- Returns family IDs for the authenticated user (used in RLS policies)
create or replace function get_user_family_ids()
returns setof uuid
language sql
security definer
stable
as $$
    select family_id
    from family_members
    where user_id = auth.uid()
$$;

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_family_members_user on family_members(user_id);
create index idx_family_members_family on family_members(family_id);
create index idx_babies_family on babies(family_id);
create index idx_sleep_sessions_baby on sleep_sessions(baby_id);
create index idx_sleep_sessions_start on sleep_sessions(start_time);
create index idx_feeding_logs_baby on feeding_logs(baby_id);
create index idx_feeding_logs_start on feeding_logs(start_time);
create index idx_solid_food_logs_baby on solid_food_logs(baby_id);
create index idx_food_catalog_baby on food_catalog(baby_id);
create index idx_diaper_logs_baby on diaper_logs(baby_id);
create index idx_diaper_logs_changed on diaper_logs(changed_at);
create index idx_growth_records_baby on growth_records(baby_id);
create index idx_baby_milestones_baby on baby_milestones(baby_id);
create index idx_ai_conversations_baby on ai_conversations(baby_id);
create index idx_ai_messages_conversation on ai_messages(conversation_id);
create index idx_meal_plans_baby on meal_plans(baby_id);
create index idx_daily_plans_baby_date on daily_plans(baby_id, date);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

create or replace function update_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger trg_families_updated before update on families
    for each row execute function update_updated_at();
create trigger trg_babies_updated before update on babies
    for each row execute function update_updated_at();
create trigger trg_sleep_sessions_updated before update on sleep_sessions
    for each row execute function update_updated_at();
create trigger trg_feeding_logs_updated before update on feeding_logs
    for each row execute function update_updated_at();
create trigger trg_food_catalog_updated before update on food_catalog
    for each row execute function update_updated_at();
create trigger trg_baby_milestones_updated before update on baby_milestones
    for each row execute function update_updated_at();
create trigger trg_ai_conversations_updated before update on ai_conversations
    for each row execute function update_updated_at();
create trigger trg_meal_plans_updated before update on meal_plans
    for each row execute function update_updated_at();
create trigger trg_daily_plans_updated before update on daily_plans
    for each row execute function update_updated_at();
