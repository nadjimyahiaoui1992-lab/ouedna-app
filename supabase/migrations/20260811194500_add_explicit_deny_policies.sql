-- Explicitly deny all client access to internal and currently unused tables.
-- Grants remain revoked; these restrictive policies document and enforce deny-by-default intent.

create policy "deny_client_access"
on private.tour_guide_rate_limits
as restrictive
for all
to anon, authenticated
using (false)
with check (false);

create policy "deny_client_access"
on public.admins
as restrictive
for all
to anon, authenticated
using (false)
with check (false);

create policy "deny_client_access"
on public.feedback_suggestions
as restrictive
for all
to anon, authenticated
using (false)
with check (false);

create policy "deny_client_access"
on public.feedbacks
as restrictive
for all
to anon, authenticated
using (false)
with check (false);

create policy "deny_client_access"
on public.suggestions
as restrictive
for all
to anon, authenticated
using (false)
with check (false);
