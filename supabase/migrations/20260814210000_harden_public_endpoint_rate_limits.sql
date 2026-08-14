-- Ouedna public Edge Functions use service_role only after strict input validation
-- and this server-side, per-endpoint rate limit. Clients never receive service_role.

create table if not exists private.public_endpoint_rate_limits (
  scope text not null check (char_length(scope) between 1 and 64),
  client_key text not null check (char_length(client_key) between 16 and 128),
  window_started_at timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (scope, client_key, window_started_at)
);

alter table private.public_endpoint_rate_limits enable row level security;
revoke all on table private.public_endpoint_rate_limits from public, anon, authenticated;

create or replace function public.consume_public_endpoint_request(
  p_scope text,
  p_client_key text,
  p_window_seconds integer default 3600,
  p_max_requests integer default 60
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
  if p_scope is null
    or char_length(p_scope) < 1
    or char_length(p_scope) > 64
    or p_client_key is null
    or char_length(p_client_key) < 16
    or char_length(p_client_key) > 128
    or p_window_seconds < 60
    or p_window_seconds > 86400
    or p_max_requests < 1
    or p_max_requests > 10000 then
    return false;
  end if;

  v_window_started_at := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  insert into private.public_endpoint_rate_limits (
    scope, client_key, window_started_at, request_count
  )
  values (p_scope, p_client_key, v_window_started_at, 1)
  on conflict (scope, client_key, window_started_at) do update
    set request_count = private.public_endpoint_rate_limits.request_count + 1
    where private.public_endpoint_rate_limits.request_count < p_max_requests
  returning true into v_allowed;

  return coalesce(v_allowed, false);
end;
$$;

revoke all on function public.consume_public_endpoint_request(text, text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_public_endpoint_request(text, text, integer, integer)
  to service_role;
