-- Ouedna archive image storage: public delivery, administrator-only mutation.
begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'archive-images',
  'archive-images',
  true,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Archive images: admins insert" on storage.objects;
drop policy if exists "Archive images: admins update" on storage.objects;
drop policy if exists "Archive images: admins delete" on storage.objects;

create policy "Archive images: admins insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'archive-images'
  and (storage.foldername(name))[1] in ('old_memories', 'heritage')
  and private.is_admin(auth.uid())
);

create policy "Archive images: admins update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'archive-images'
  and (storage.foldername(name))[1] in ('old_memories', 'heritage')
  and private.is_admin(auth.uid())
)
with check (
  bucket_id = 'archive-images'
  and (storage.foldername(name))[1] in ('old_memories', 'heritage')
  and private.is_admin(auth.uid())
);

create policy "Archive images: admins delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'archive-images'
  and (storage.foldername(name))[1] in ('old_memories', 'heritage')
  and private.is_admin(auth.uid())
);

commit;
