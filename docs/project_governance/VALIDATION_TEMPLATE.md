# Validation Template

## Validation Target

- Stage:
- Branch:
- Commit:
- Files or systems under validation:

## Commands / Checks

```text
command or checklist item here
```

## Result Categories

- `Godot headless project-load/parser smoke PASS`: yes/no/not run
- `gameplay runtime PASS`: yes/no/not run
- `manual playtest PASS`: yes/no/not run
- Static docs/code check: yes/no/not run

## Boundaries

- Parser smoke is not gameplay runtime PASS.
- Parser smoke is not manual playtest PASS.
- Foundation scope is not complete system scope.
- Unverified content must be marked not run, not claimed, or unknown.

## Dirty Check

- Business code changed:
- Godot project/scene/resource/font/import product changed:
- `.uid` changed:
- `.translation` changed:
- Base Docs original changed:
