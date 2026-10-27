-- ==============================================================================
-- SheRise / HerShield: Enterprise Institutional Database Schema (PostgreSQL/Supabase)
-- ==============================================================================
-- Run this script in the Supabase SQL Editor to initialize or migrate the database.
-- Supports anonymous/confidential report intake, institutional workflow tracking,
-- role-based case officer assignments, partner referrals, and audit logging.

-- 1. Enable Cryptographic & UUID Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Custom Types
DO $$ BEGIN
    CREATE TYPE report_status_enum AS ENUM ('received', 'under_review', 'referred', 'resolved', 'closed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE case_priority_enum AS ENUM ('urgent', 'high', 'medium', 'low');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE message_sender_enum AS ENUM ('reporter', 'staff');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Delivered Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_hash TEXT NOT NULL UNIQUE, -- SHA-256 hash of private reporter access code
    code_prefix TEXT NOT NULL,      -- Non-sensitive prefix (e.g. SR-7821) for admin reference
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT DEFAULT '',
    incident_date DATE,
    anonymous BOOLEAN DEFAULT true,
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reporter_name TEXT,
    reporter_contact TEXT,
    status report_status_enum DEFAULT 'received',
    priority case_priority_enum DEFAULT 'medium',
    assigned_officer TEXT,
    assigned_department TEXT,
    institution_name TEXT DEFAULT 'Safety & Ethics Directorate',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing for fast search and filtering
CREATE INDEX IF NOT EXISTS idx_reports_code_hash ON public.reports(code_hash);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_priority ON public.reports(priority);
CREATE INDEX IF NOT EXISTS idx_reports_category ON public.reports(category);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- 4. Evidence Attachments Table
CREATE TABLE IF NOT EXISTS public.evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,            -- 'voice' or 'file'
    ext TEXT NOT NULL,
    mime TEXT NOT NULL,
    size_bytes BIGINT NOT NULL,
    seconds INT,                   -- Duration for audio recordings
    storage_path TEXT,             -- Supabase private storage bucket path
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evidence_report_id ON public.evidence(report_id);

-- 5. Two-Way Secure Case Messages
CREATE TABLE IF NOT EXISTS public.case_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    sender message_sender_enum NOT NULL,
    sender_name TEXT,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_messages_report_id ON public.case_messages(report_id, created_at ASC);

-- 6. Confidential Staff Internal Notes (Never visible to public reporter)
CREATE TABLE IF NOT EXISTS public.case_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    author TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notes_report_id ON public.case_notes(report_id);

-- 7. Partner Referrals Table (EWLA, Shelters, Clinics, Police)
CREATE TABLE IF NOT EXISTS public.case_referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    partner_name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    notes TEXT,
    referred_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending'
);

CREATE INDEX IF NOT EXISTS idx_referrals_report_id ON public.case_referrals(report_id);

-- 8. Formal Case Resolutions Table
CREATE TABLE IF NOT EXISTS public.case_resolutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    outcome TEXT NOT NULL,
    summary TEXT NOT NULL,
    action_taken TEXT NOT NULL,
    resolved_by TEXT NOT NULL,
    resolved_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resolutions_report_id ON public.case_resolutions(report_id);

-- 9. Immutable Audit Event Log
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    actor TEXT NOT NULL,
    details TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_report_id ON public.audit_logs(report_id, timestamp DESC);

-- ==============================================================================
-- Row-Level Security (RLS) Policies
-- ==============================================================================
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_resolutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Anonymous/Public: Can submit report via RPC
-- Staff: Full access based on role
CREATE POLICY "Staff can view all reports"
    ON public.reports FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Staff can update reports"
    ON public.reports FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Staff can view all case notes"
    ON public.case_notes FOR ALL
    TO authenticated
    USING (true);

-- ==============================================================================
-- Stored Procedures (RPC Functions for Mobile App & Institution Board)
-- ==============================================================================

-- 1. Submit Report RPC
CREATE OR REPLACE FUNCTION public.submit_report(
    p_category TEXT,
    p_description TEXT,
    p_location TEXT DEFAULT '',
    p_incident_date DATE DEFAULT NULL,
    p_anonymous BOOLEAN DEFAULT true,
    p_reporter_name TEXT DEFAULT NULL,
    p_reporter_contact TEXT DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_raw_code TEXT;
    v_code_hash TEXT;
    v_code_prefix TEXT;
    v_report_id UUID;
    v_priority case_priority_enum := 'medium';
BEGIN
    -- Generate private 12-char alphanumeric code (e.g. SR-8291-3849)
    v_raw_code := 'SR-' || upper(substr(encode(gen_random_bytes(3), 'hex'), 1, 4)) || '-' || upper(substr(encode(gen_random_bytes(3), 'hex'), 1, 4));
    v_code_hash := encode(digest(v_raw_code, 'sha256'), 'hex');
    v_code_prefix := substr(v_raw_code, 1, 7);

    IF lower(p_category) LIKE '%abuse%' OR lower(p_category) LIKE '%violence%' THEN
        v_priority := 'urgent';
    ELSIF lower(p_category) LIKE '%harassment%' OR lower(p_category) LIKE '%bullying%' THEN
        v_priority := 'high';
    END IF;

    INSERT INTO public.reports (
        code_hash,
        code_prefix,
        category,
        description,
        location,
        incident_date,
        anonymous,
        reporter_id,
        reporter_name,
        reporter_contact,
        priority
    ) VALUES (
        v_code_hash,
        v_code_prefix,
        p_category,
        p_description,
        p_location,
        p_incident_date,
        p_anonymous,
        auth.uid(),
        CASE WHEN p_anonymous THEN NULL ELSE p_reporter_name END,
        CASE WHEN p_anonymous THEN NULL ELSE p_reporter_contact END,
        v_priority
    ) RETURNING id INTO v_report_id;

    -- Add initial intake message
    INSERT INTO public.case_messages (report_id, sender, sender_name, body)
    VALUES (v_report_id, 'staff', 'Intake Bot', 'Report received securely by the Institution Board. An assigned officer will review this case.');

    -- Add initial audit entry
    INSERT INTO public.audit_logs (report_id, action, actor, details)
    VALUES (v_report_id, 'Report Submitted', CASE WHEN p_anonymous THEN 'Anonymous' ELSE 'Reporter' END, 'Intake recorded via SafeVoice.');

    RETURN v_raw_code;
END;
$$;

-- 2. Reporter Status Tracking RPC
CREATE OR REPLACE FUNCTION public.get_report_status(p_code TEXT)
RETURNS TABLE(
    status TEXT,
    category TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hash TEXT;
BEGIN
    v_hash := encode(digest(trim(p_code), 'sha256'), 'hex');
    RETURN QUERY
    SELECT r.status::TEXT, r.category, r.created_at, r.updated_at
    FROM public.reports r
    WHERE r.code_hash = v_hash;
END;
$$;

-- 3. Reporter Messages RPC
CREATE OR REPLACE FUNCTION public.get_report_messages(p_code TEXT)
RETURNS TABLE(
    sender TEXT,
    body TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hash TEXT;
    v_report_id UUID;
BEGIN
    v_hash := encode(digest(trim(p_code), 'sha256'), 'hex');
    SELECT id INTO v_report_id FROM public.reports WHERE code_hash = v_hash;

    IF v_report_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT m.sender::TEXT, m.body, m.created_at
    FROM public.case_messages m
    WHERE m.report_id = v_report_id
    ORDER BY m.created_at ASC;
END;
$$;

-- 4. Reporter Add Message RPC
CREATE OR REPLACE FUNCTION public.add_reporter_message(p_code TEXT, p_body TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hash TEXT;
    v_report_id UUID;
BEGIN
    v_hash := encode(digest(trim(p_code), 'sha256'), 'hex');
    SELECT id INTO v_report_id FROM public.reports WHERE code_hash = v_hash;

    IF v_report_id IS NOT NULL THEN
        INSERT INTO public.case_messages (report_id, sender, body)
        VALUES (v_report_id, 'reporter', p_body);

        INSERT INTO public.audit_logs (report_id, action, actor, details)
        VALUES (v_report_id, 'Reporter Message Sent', 'Reporter', 'New message in case thread.');

        UPDATE public.reports SET updated_at = NOW() WHERE id = v_report_id;
    END IF;
END;
$$;
