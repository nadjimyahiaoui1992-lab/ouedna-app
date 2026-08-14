-- Historical migrations created public RPC overloads for rate limiting.
-- Edge Functions now use consume_public_endpoint_request exclusively.

do $$
begin
  if to_regprocedure('public.consume_tour_guide_request(text,integer,integer)') is not null then
    alter function public.consume_tour_guide_request(text, integer, integer)
      set search_path = private, pg_catalog;
    revoke all on function public.consume_tour_guide_request(text, integer, integer)
      from public, anon, authenticated;
  end if;

  if to_regprocedure('public.consume_tour_guide_request(uuid,integer,integer)') is not null then
    alter function public.consume_tour_guide_request(uuid, integer, integer)
      set search_path = private, pg_catalog;
    revoke all on function public.consume_tour_guide_request(uuid, integer, integer)
      from public, anon, authenticated;
  end if;
end;
$$;

alter function public.is_admin(uuid) set search_path = pg_catalog, public;
revoke all on function public.is_admin(uuid) from public, anon, authenticated;
