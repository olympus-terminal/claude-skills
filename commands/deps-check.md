---
description: Check project dependencies for issues and updates
---

Analyze project dependencies for issues, security vulnerabilities, and updates.

Steps:
1. Identify the package manager(s) in use:
   - npm/yarn/pnpm: package.json
   - pip: requirements.txt, pyproject.toml, setup.py
   - cargo: Cargo.toml
   - go: go.mod
2. Check for:
   - Outdated packages (run appropriate update check command)
   - Security vulnerabilities (npm audit, pip-audit, etc.)
   - Unused dependencies if tools available
   - Version conflicts or peer dependency issues
3. Report findings:
   - Critical security issues requiring immediate action
   - Major version updates available
   - Minor/patch updates
   - Recommendations for dependency cleanup
