# GIT_FLOW.md

## Git & Collaboration Workflow

### 1. Branching Strategy
- `main` / `master`: Production-ready, stable codebase.
- `develop`: Integration branch for ongoing development.
- `feature/<feature-name>`: Dedicated branch for specific features or refactor tasks.
- `bugfix/<issue-name>`: Dedicated branch for resolving bugs.

---

### 2. Commit Message Standards

Use Conventional Commits format:
```text
<type>(<scope>): <short description>
```

#### Allowed Types:
- `feat`: A new SDK capability or public feature.
- `fix`: A bug fix.
- `refactor`: Code restructuring without changing behavior.
- `chore`: Tooling, dependencies, or configuration changes.
- `ci`: Continuous-integration configuration or gates.
- `docs`: Documentation updates.
- `test`: Adding or modifying tests.

#### Examples:
- `feat(health): add health capability mapping`
- `refactor(executor): centralize response failure mapping`
- `ci: add package quality gate`

---

### 3. Strict Rules

1. **NO Co-author Metadata:** Never append co-author signatures (`Co-authored-by: ...`) to commit messages.
2. **Logical Atomic Commits:** Group related changes together logically; avoid unorganized blobs.
3. **Pre-commit Verification:** Run `make verify` (or `flutter analyze` and `flutter test`) before committing.
