-- Secure rate limiting for anonymous visitor place submissions.
-- The RPC is deliberately limited to service_role and is called only by the Edge Function.

CREATE TABLE IF NOT EXISTS public.visitor_place_submission_limits (
  client_key TEXT PRIMARY KEY,
  window_started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_count INTEGER NOT NULL DEFAULT 0 CHECK (request_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.visitor_place_submission_limits ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.consume_visitor_place_submission(
  p_client_key TEXT,
  p_window_seconds INTEGER DEFAULT 86400,
  p_max_requests INTEGER DEFAULT 3
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  limit_row public.visitor_place_submission_limits%ROWTYPE;
  is_allowed BOOLEAN := FALSE;
BEGIN
  IF p_client_key IS NULL OR length(trim(p_client_key)) < 8 THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.visitor_place_submission_limits (
    client_key,
    window_started_at,
    request_count,
    updated_at
  )
  VALUES (left(trim(p_client_key), 200), now(), 0, now())
  ON CONFLICT (client_key) DO NOTHING;

  SELECT *
  INTO limit_row
  FROM public.visitor_place_submission_limits
  WHERE client_key = left(trim(p_client_key), 200)
  FOR UPDATE;

  IF limit_row.window_started_at < now() - make_interval(secs => p_window_seconds) THEN
    UPDATE public.visitor_place_submission_limits
    SET window_started_at = now(), request_count = 1, updated_at = now()
    WHERE client_key = limit_row.client_key;
    is_allowed := TRUE;
  ELSIF limit_row.request_count < p_max_requests THEN
    UPDATE public.visitor_place_submission_limits
    SET request_count = request_count + 1, updated_at = now()
    WHERE client_key = limit_row.client_key;
    is_allowed := TRUE;
  END IF;

  RETURN is_allowed;
END;
$$;

REVOKE ALL ON TABLE public.visitor_place_submission_limits FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.consume_visitor_place_submission(TEXT, INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.consume_visitor_place_submission(TEXT, INTEGER, INTEGER) TO service_role;
