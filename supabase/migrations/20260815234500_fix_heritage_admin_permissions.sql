-- Fix RLS and grants for public.heritage to allow admin updates/inserts
grant insert, update, delete on table public.heritage to authenticated;

drop policy if exists "heritage_admin_all" on public.heritage;
create policy "heritage_admin_all"
on public.heritage
for all
to authenticated
using (true)
with check (true);
