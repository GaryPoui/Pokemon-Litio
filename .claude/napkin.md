# Napkin Runbook

## Execution & Validation
1. **[2026-10-19] Verify Godot asset contracts before replacing map art.**
   Do instead: inspect the scene's sprite anchor, scale, collision, and project grid; keep the support line aligned when the source dimensions change.

## Domain Behavior Guardrails
1. **[2026-10-19] Preserve local art inputs during integration.**
   Do instead: copy a provided source into the active resource path and leave the supplied source file untouched.
