-- Ouedna archive: preserve existing records while allowing verified historical dates and image galleries.
begin;

alter table public.old_memories
  add column if not exists year text,
  add column if not exists gallery jsonb not null default '[]'::jsonb;

alter table public.heritage
  add column if not exists year text,
  add column if not exists gallery jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'old_memories_gallery_is_array'
      and conrelid = 'public.old_memories'::regclass
  ) then
    alter table public.old_memories
      add constraint old_memories_gallery_is_array
      check (jsonb_typeof(gallery) = 'array');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'heritage_gallery_is_array'
      and conrelid = 'public.heritage'::regclass
  ) then
    alter table public.heritage
      add constraint heritage_gallery_is_array
      check (jsonb_typeof(gallery) = 'array');
  end if;
end $$;

comment on column public.old_memories.year is 'Verified historical date or period supplied by the contributor or archivist.';
comment on column public.old_memories.gallery is 'JSON array of additional approved archive image URLs.';
comment on column public.heritage.year is 'Verified historical date or period supplied by the curator.';
comment on column public.heritage.gallery is 'JSON array of additional approved archive image URLs.';

commit;
