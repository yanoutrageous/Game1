# Branch Change: G8.1 Architecture Hardening

## Branch

`godot/g8-1-architecture-hardening`

## Base

`godot/g8-rules-asset-ledger-core` at `717728087eea2bdabd3a9c031b0f2698cdb5737e`.

## Purpose

Stabilize the Godot G8 rule core by adding explicit UE-inspired boundaries: Query/Snapshot, RuleResult, EffectSpec, command envelope, minimal content-definition fallback, and contract-only Save/Meta adapters.

## Notes

- No new gameplay was added.
- `RunAssetLedger` remains the single run asset state owner.
- No full MetaProgress, Deploy persistence, Warehouse UI, action combat, consignment, insurance, or lottery pool.
- Do not run Godot/editor/game/import unless separately authorized.
