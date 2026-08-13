ALTER TABLE public.feedback
  ADD COLUMN IF NOT EXISTS feedback_scope text NOT NULL DEFAULT 'app',
  ADD COLUMN IF NOT EXISTS place_id bigint NULL REFERENCES public.places(id) ON DELETE SET NULL;

ALTER TABLE public.feedback
  DROP CONSTRAINT IF EXISTS feedback_scope_valid;
ALTER TABLE public.feedback
  ADD CONSTRAINT feedback_scope_valid CHECK (feedback_scope IN ('app', 'place'));

CREATE INDEX IF NOT EXISTS feedback_created_at_idx
  ON public.feedback (created_at DESC);
CREATE INDEX IF NOT EXISTS feedback_place_id_idx
  ON public.feedback (place_id)
  WHERE place_id IS NOT NULL;

ALTER TABLE public.suggestions
  ADD COLUMN IF NOT EXISTS kind text NOT NULL DEFAULT 'suggestion',
  ADD COLUMN IF NOT EXISTS subject text NULL,
  ADD COLUMN IF NOT EXISTS contact_info text NULL,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'new',
  ADD COLUMN IF NOT EXISTS admin_reply text NULL,
  ADD COLUMN IF NOT EXISTS replied_at timestamptz NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.suggestions
  DROP CONSTRAINT IF EXISTS suggestions_kind_valid;
ALTER TABLE public.suggestions
  ADD CONSTRAINT suggestions_kind_valid CHECK (kind IN ('suggestion', 'question'));
ALTER TABLE public.suggestions
  DROP CONSTRAINT IF EXISTS suggestions_status_valid;
ALTER TABLE public.suggestions
  ADD CONSTRAINT suggestions_status_valid CHECK (status IN ('new', 'in_review', 'answered', 'closed'));
ALTER TABLE public.suggestions
  DROP CONSTRAINT IF EXISTS suggestions_message_length;
ALTER TABLE public.suggestions
  ADD CONSTRAINT suggestions_message_length CHECK (char_length(trim(message)) BETWEEN 1 AND 3000);

CREATE INDEX IF NOT EXISTS suggestions_status_created_at_idx
  ON public.suggestions (status, created_at DESC);

DROP POLICY IF EXISTS deny_client_access ON public.suggestions;
DROP POLICY IF EXISTS "Visitors submit suggestions" ON public.suggestions;
DROP POLICY IF EXISTS "Admins manage suggestions" ON public.suggestions;

CREATE POLICY "Visitors submit suggestions"
  ON public.suggestions
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    char_length(trim(message)) BETWEEN 1 AND 3000
    AND (name IS NULL OR char_length(trim(name)) BETWEEN 1 AND 100)
    AND (subject IS NULL OR char_length(trim(subject)) BETWEEN 1 AND 160)
    AND (contact_info IS NULL OR char_length(trim(contact_info)) BETWEEN 3 AND 180)
    AND kind IN ('suggestion', 'question')
    AND status = 'new'
    AND admin_reply IS NULL
    AND replied_at IS NULL
  );

CREATE POLICY "Admins manage suggestions"
  ON public.suggestions
  FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'feedback'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback;
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'suggestions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.suggestions;
  END IF;
END;
$$;
