# Detection specification

Use this structure for a vendor-neutral detection deliverable.

## Identity

- Name and version
- Owner
- Status: draft, test, or production candidate
- Threat hypothesis
- Explicit non-goals

## Telemetry contract

For each source and field:

- Source and collection path
- Field name, type, and semantic meaning
- Event-time and ingestion-time behavior
- Stable entity identifier
- Coverage, retention, and known gaps

## Logic

- Required event predicates
- Sequence or aggregation
- Correlation keys
- Time window
- Thresholds
- Environmental filters
- Temporary suppression with owner and expiry

## Validation

- Positive fixtures
- Negative and benign fixtures
- Boundary and data-quality fixtures
- Engine or harness used
- Observed result and execution time
- Validation status

## Operations

- Severity rationale
- Alert grouping and deduplication
- Investigation pivots
- Expected volume and false-positive sources
- Data-source health signal
- Tuning, rollback, and retirement conditions
