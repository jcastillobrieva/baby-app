-- ============================================================
-- Baby App — Row Level Security Policies
-- ============================================================
-- Principle: Users can only access data belonging to their family.
-- Uses get_user_family_ids() helper from migration 00001.
-- ============================================================

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================

alter table families enable row level security;
alter table family_members enable row level security;
alter table family_invites enable row level security;
alter table babies enable row level security;
alter table sleep_sessions enable row level security;
alter table sleep_wakings enable row level security;
alter table bedtime_routines enable row level security;
alter table feeding_logs enable row level security;
alter table solid_food_logs enable row level security;
alter table food_catalog enable row level security;
alter table diaper_logs enable row level security;
alter table growth_records enable row level security;
alter table milestone_definitions enable row level security;
alter table baby_milestones enable row level security;
alter table ai_conversations enable row level security;
alter table ai_messages enable row level security;
alter table meal_plans enable row level security;
alter table meal_plan_items enable row level security;
alter table daily_plans enable row level security;
alter table plan_items enable row level security;

-- ============================================================
-- FAMILIES
-- ============================================================

create policy "Users can view their families"
    on families for select
    using (id in (select get_user_family_ids()));

create policy "Authenticated users can create families"
    on families for insert
    with check (auth.uid() is not null);

create policy "Admins can update their families"
    on families for update
    using (id in (
        select family_id from family_members
        where user_id = auth.uid() and role = 'admin'
    ));

-- ============================================================
-- FAMILY MEMBERS
-- ============================================================

create policy "Users can view members of their families"
    on family_members for select
    using (family_id in (select get_user_family_ids()));

create policy "Users can insert themselves into a family"
    on family_members for insert
    with check (user_id = auth.uid());

create policy "Admins can manage family members"
    on family_members for delete
    using (family_id in (
        select family_id from family_members fm
        where fm.user_id = auth.uid() and fm.role = 'admin'
    ));

-- ============================================================
-- FAMILY INVITES
-- ============================================================

create policy "Admins can view invites for their families"
    on family_invites for select
    using (family_id in (
        select family_id from family_members
        where user_id = auth.uid() and role = 'admin'
    ));

create policy "Admins can create invites"
    on family_invites for insert
    with check (family_id in (
        select family_id from family_members
        where user_id = auth.uid() and role = 'admin'
    ));

create policy "Admins can update invites"
    on family_invites for update
    using (family_id in (
        select family_id from family_members
        where user_id = auth.uid() and role = 'admin'
    ));

-- ============================================================
-- BABIES
-- ============================================================

create policy "Users can view babies in their family"
    on babies for select
    using (family_id in (select get_user_family_ids()));

create policy "Users can add babies to their family"
    on babies for insert
    with check (family_id in (select get_user_family_ids()));

create policy "Users can update babies in their family"
    on babies for update
    using (family_id in (select get_user_family_ids()));

-- ============================================================
-- SLEEP TRACKING
-- ============================================================

create policy "Users can view sleep sessions"
    on sleep_sessions for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert sleep sessions"
    on sleep_sessions for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

create policy "Users can update sleep sessions"
    on sleep_sessions for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can delete sleep sessions"
    on sleep_sessions for delete
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can view sleep wakings"
    on sleep_wakings for select
    using (sleep_session_id in (
        select ss.id from sleep_sessions ss
        join babies b on ss.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can insert sleep wakings"
    on sleep_wakings for insert
    with check (sleep_session_id in (
        select ss.id from sleep_sessions ss
        join babies b on ss.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can manage sleep wakings"
    on sleep_wakings for delete
    using (sleep_session_id in (
        select ss.id from sleep_sessions ss
        join babies b on ss.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can view bedtime routines"
    on bedtime_routines for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert bedtime routines"
    on bedtime_routines for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

-- ============================================================
-- FEEDING
-- ============================================================

create policy "Users can view feeding logs"
    on feeding_logs for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert feeding logs"
    on feeding_logs for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

create policy "Users can update feeding logs"
    on feeding_logs for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can delete feeding logs"
    on feeding_logs for delete
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can view solid food logs"
    on solid_food_logs for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert solid food logs"
    on solid_food_logs for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

create policy "Users can view food catalog"
    on food_catalog for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can manage food catalog"
    on food_catalog for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can update food catalog"
    on food_catalog for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

-- ============================================================
-- DIAPERS
-- ============================================================

create policy "Users can view diaper logs"
    on diaper_logs for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert diaper logs"
    on diaper_logs for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

create policy "Users can update diaper logs"
    on diaper_logs for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can delete diaper logs"
    on diaper_logs for delete
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

-- ============================================================
-- GROWTH & DEVELOPMENT
-- ============================================================

create policy "Users can view growth records"
    on growth_records for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can insert growth records"
    on growth_records for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and logged_by = auth.uid());

create policy "Users can update growth records"
    on growth_records for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

-- Milestone definitions are read-only for all authenticated users
create policy "Authenticated users can view milestones"
    on milestone_definitions for select
    using (auth.uid() is not null);

create policy "Users can view baby milestones"
    on baby_milestones for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can manage baby milestones"
    on baby_milestones for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can update baby milestones"
    on baby_milestones for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

-- ============================================================
-- AI CONVERSATIONS
-- ============================================================

create policy "Users can view AI conversations"
    on ai_conversations for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can create AI conversations"
    on ai_conversations for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and created_by = auth.uid());

create policy "Users can view AI messages"
    on ai_messages for select
    using (conversation_id in (
        select ac.id from ai_conversations ac
        join babies b on ac.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can insert AI messages"
    on ai_messages for insert
    with check (conversation_id in (
        select ac.id from ai_conversations ac
        join babies b on ac.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

-- ============================================================
-- MEAL PLANNING
-- ============================================================

create policy "Users can view meal plans"
    on meal_plans for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can create meal plans"
    on meal_plans for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and created_by = auth.uid());

create policy "Users can update meal plans"
    on meal_plans for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can view meal plan items"
    on meal_plan_items for select
    using (meal_plan_id in (
        select mp.id from meal_plans mp
        join babies b on mp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can manage meal plan items"
    on meal_plan_items for insert
    with check (meal_plan_id in (
        select mp.id from meal_plans mp
        join babies b on mp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can update meal plan items"
    on meal_plan_items for update
    using (meal_plan_id in (
        select mp.id from meal_plans mp
        join babies b on mp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can delete meal plan items"
    on meal_plan_items for delete
    using (meal_plan_id in (
        select mp.id from meal_plans mp
        join babies b on mp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

-- ============================================================
-- DAILY PLANNING
-- ============================================================

create policy "Users can view daily plans"
    on daily_plans for select
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can create daily plans"
    on daily_plans for insert
    with check (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ) and created_by = auth.uid());

create policy "Users can update daily plans"
    on daily_plans for update
    using (baby_id in (
        select id from babies where family_id in (select get_user_family_ids())
    ));

create policy "Users can view plan items"
    on plan_items for select
    using (daily_plan_id in (
        select dp.id from daily_plans dp
        join babies b on dp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can manage plan items"
    on plan_items for insert
    with check (daily_plan_id in (
        select dp.id from daily_plans dp
        join babies b on dp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can update plan items"
    on plan_items for update
    using (daily_plan_id in (
        select dp.id from daily_plans dp
        join babies b on dp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));

create policy "Users can delete plan items"
    on plan_items for delete
    using (daily_plan_id in (
        select dp.id from daily_plans dp
        join babies b on dp.baby_id = b.id
        where b.family_id in (select get_user_family_ids())
    ));
