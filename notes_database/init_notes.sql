-- Notes schema + minimal seed data for local verification
-- This script is intended to be executed on container startup.
-- It is safe to run multiple times.

-- Ensure uuid generation support is available (preferred for IDs).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Helpful index for sorting by recency
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON public.notes (updated_at DESC);

-- Auto-update updated_at timestamp on UPDATE
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_notes_set_updated_at ON public.notes;
CREATE TRIGGER trg_notes_set_updated_at
BEFORE UPDATE ON public.notes
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Minimal seed: insert a couple of example notes if table is empty
INSERT INTO public.notes (title, content)
SELECT 'Welcome', 'This is an example note created on startup.'
WHERE NOT EXISTS (SELECT 1 FROM public.notes);

INSERT INTO public.notes (title, content)
SELECT 'Second note', 'Edit or delete this note to verify CRUD works end-to-end.'
WHERE (SELECT COUNT(*) FROM public.notes) < 2;
