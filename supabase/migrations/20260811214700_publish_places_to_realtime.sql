-- Souf360 is the content-management surface; Souf Tour consumes published
-- landmark updates as they are added, edited or removed by administrators.
alter publication supabase_realtime add table public.places;
