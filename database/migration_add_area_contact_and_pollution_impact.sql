-- Migration for app v1.0.12 (from the project scope document)
--   * mangrove_areas.contact_person / contact_channel : who to contact for each area
--     and how (phone / LINE ...). Shown to admins only (not on the public screens).
--   * pollution_reports.expected_impact : "how is it likely to affect the mangrove"
--
-- Idempotent: safe to run more than once. No data is changed or removed.
-- ORDER OF RELEASE:  1) run this  ->  2) deploy api-server  ->  3) release the app.
-- (If the API is deployed before this runs, saving pollution reports / areas fails.)

SET search_path TO eastern_mangrove_communities, public;

ALTER TABLE mangrove_areas
  ADD COLUMN IF NOT EXISTS contact_person  VARCHAR(150),
  ADD COLUMN IF NOT EXISTS contact_channel VARCHAR(255);

ALTER TABLE pollution_reports
  ADD COLUMN IF NOT EXISTS expected_impact TEXT;
