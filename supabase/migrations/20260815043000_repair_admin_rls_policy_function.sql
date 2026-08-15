-- The legacy public.is_admin(uuid) function intentionally has no EXECUTE grant.
-- These policies must call the protected private helper instead, otherwise any
-- authenticated admin request fails before the policy can evaluate the role.

alter policy "Allow admins to delete profiles" on public.admin_profiles
  using (private.is_admin(auth.uid()) or auth.role() = 'service_role');

alter policy "Allow admins to insert profiles" on public.admin_profiles
  with check (private.is_admin(auth.uid()) or auth.role() = 'service_role');

alter policy "Allow admins to read all profiles" on public.admin_profiles
  using (private.is_admin(auth.uid()) or id = auth.uid() or auth.role() = 'service_role');

alter policy "Allow admins to update profiles" on public.admin_profiles
  using (private.is_admin(auth.uid()) or auth.role() = 'service_role')
  with check (private.is_admin(auth.uid()) or auth.role() = 'service_role');

alter policy "Admins can insert app config" on public.app_config
  with check (id = 1 and private.is_admin(auth.uid()));

alter policy "Admins can update app config" on public.app_config
  using (id = 1 and private.is_admin(auth.uid()))
  with check (id = 1 and private.is_admin(auth.uid()));

alter policy "Admins manage feedback" on public.feedback
  using (private.is_admin(auth.uid()))
  with check (private.is_admin(auth.uid()));

alter policy "Admins manage memories" on public.memories
  using (private.is_admin(auth.uid()))
  with check (private.is_admin(auth.uid()));

alter policy "Admins manage suggestions" on public.suggestions
  using (private.is_admin(auth.uid()))
  with check (private.is_admin(auth.uid()));

alter policy "Admins moderate testimonials" on public.testimonials
  using (private.is_admin(auth.uid()))
  with check (private.is_admin(auth.uid()));

alter policy "Visitors read approved testimonials" on public.testimonials
  using (status = 'approved' or private.is_admin(auth.uid()));
