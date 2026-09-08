On-demand reference for `pr-reviewer`. Read this when the PR's primary language isn't Python or Elixir.

### Generic checklist

- Dependency/config changes: version bumps, new third-party packages, env var/default changes, and their rollout risk
- Error handling & logging: failures surfaced correctly, no swallowed exceptions, no secrets/PII in logs
- Input validation at trust boundaries: user input, external API responses, file/network data validated before use
- Injection/secrets: no string-built queries/commands from untrusted input, no hardcoded secrets/tokens
- Migration/schema-change safety: backward-compatible for rolling deploys, reversible or intentionally not
- Test coverage: happy path, error paths, and the specific behavior this PR changes
