-- Souf Tour security baseline: explicit API grants, least-privilege RLS and server-only guide rate limiting.

create schema if not exists private;
revoke all on schema private from public;

create table if not exists private.tour_guide_rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (user_id, window_started_at)
);

alter table private.tour_guide_rate_limits enable row level security;
revoke all on table private.tour_guide_rate_limits from public, anon, authenticated;

create or replace function private.is_admin(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.admin_profiles
    where id = p_user_id
      and role = 'admin'
  );
$$;

create or replace function public.consume_tour_guide_request(
  p_user_id uuid,
  p_window_seconds integer default 600,
  p_max_requests integer default 12
)
returns boolean
language plpgsql
security definer
set search_path = private, pg_catalog
as $$
declare
  v_window_started_at timestamptz;
  v_allowed boolean;
begin
  if p_user_id is null
    or p_window_seconds < 60
    or p_window_seconds > 3600
    or p_max_requests < 1
    or p_max_requests > 100 then
    return false;
  end if;

  v_window_started_at := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  insert into private.tour_guide_rate_limits (
    user_id,
    window_started_at,
    request_count
  )
  values (p_user_id, v_window_started_at, 1)
  on conflict (user_id, window_started_at) do update
    set request_count = private.tour_guide_rate_limits.request_count + 1
    where private.tour_guide_rate_limits.request_count < p_max_requests
  returning true into v_allowed;

  return coalesce(v_allowed, false);
end;
$$;

alter function public.set_updated_at() set search_path = pg_catalog;
alter function public.is_admin(uuid) set search_path = pg_catalog, public;
alter function public.rls_auto_enable() set search_path = pg_catalog;

revoke all on function public.is_admin(uuid) from public, anon, authenticated;
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function private.is_admin(uuid) from public, anon;
revoke all on function public.consume_tour_guide_request(uuid, integer, integer) from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_admin(uuid) to authenticated;
grant execute on function public.consume_tour_guide_request(uuid, integer, integer) to service_role;

-- Remove broad legacy policies before creating the narrow access model.
drop policy if exists "Enable read access for all users" on public.admin_profiles;
drop policy if exists "Enable read access for admins" on public.admins;
drop policy if exists "Allow public inserts for feedback" on public.feedback_suggestions;
drop policy if exists "Allow public inserts for feedback" on public.feedbacks;
drop policy if exists "Enable insert access for all users" on public.heritage;
drop policy if exists "Enable read access for all users" on public.heritage;
drop policy if exists "Enable insert access for all users" on public.old_memories;
drop policy if exists "Enable read access for all users" on public.old_memories;
drop policy if exists "Enable read access for all users" on public.places;
drop policy if exists "Enable read access for all users" on public.testimonials;
drop policy if exists "Allow public inserts for stories" on public.visitor_stories;
drop policy if exists "Allow public to read approved stories" on public.visitor_stories;
drop policy if exists "gallery_write_staff" on public.gallery;
drop policy if exists "places_write_staff" on public.places;
drop policy if exists "site_settings_update_admin" on public.site_settings;
drop policy if exists "testimonials_public_read" on public.testimonials;
drop policy if exists "published_places_read" on public.places;
drop policy if exists "admin_profiles_read_own" on public.admin_profiles;
drop policy if exists "visitor_stories_public_read_approved" on public.visitor_stories;
drop policy if exists "heritage_public_read" on public.heritage;
drop policy if exists "old_memories_public_read" on public.old_memories;

create policy "admin_profiles_read_own"
on public.admin_profiles
for select
to authenticated
using (id = (select auth.uid()));

create policy "published_places_read"
on public.places
for select
to anon, authenticated
using (status = 'منشور');

create policy "places_write_staff"
on public.places
for all
to authenticated
using (
  private.is_admin((select auth.uid()))
  or exists (
    select 1
    from public.admin_profiles profile
    where profile.id = (select auth.uid())
      and coalesce((profile.permissions ->> 'add_place')::boolean, false)
  )
)
with check (
  private.is_admin((select auth.uid()))
  or exists (
    select 1
    from public.admin_profiles profile
    where profile.id = (select auth.uid())
      and coalesce((profile.permissions ->> 'add_place')::boolean, false)
  )
);

create policy "gallery_write_staff"
on public.gallery
for all
to authenticated
using (
  private.is_admin((select auth.uid()))
  or exists (
    select 1
    from public.admin_profiles profile
    where profile.id = (select auth.uid())
      and coalesce((profile.permissions ->> 'add_place')::boolean, false)
  )
)
with check (
  private.is_admin((select auth.uid()))
  or exists (
    select 1
    from public.admin_profiles profile
    where profile.id = (select auth.uid())
      and coalesce((profile.permissions ->> 'add_place')::boolean, false)
  )
);

create policy "site_settings_update_admin"
on public.site_settings
for update
to authenticated
using (private.is_admin((select auth.uid())))
with check (private.is_admin((select auth.uid())));

create policy "testimonials_public_read"
on public.testimonials
for select
to anon, authenticated
using (status = 'approved');

create policy "visitor_stories_public_read_approved"
on public.visitor_stories
for select
to anon, authenticated
using (is_approved = true);

create policy "heritage_public_read"
on public.heritage
for select
to anon, authenticated
using (true);

create policy "old_memories_public_read"
on public.old_memories
for select
to anon, authenticated
using (true);

-- Clear the table grants inherited from the historical dashboard setup.
revoke all on all tables in schema public from anon, authenticated;
grant select on table public.places, public.gallery, public.heritage, public.old_memories,
  public.visitor_stories, public.app_config, public.site_settings, public.testimonials to anon, authenticated;
grant select on table public.admin_profiles to authenticated;
grant insert, update, delete on table public.places, public.gallery, public.site_settings to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Future public tables and functions are closed by default until a migration explicitly grants access.
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated;
