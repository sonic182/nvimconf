---
name: create-skill
description: Create or revise Agent Skills with SKILL.md instructions and supporting resources that follow the Agent Skills specification. Use when the user asks to make a skill, turn a proven workflow into a skill, or improve an existing skill's scope, triggers, or instructions. Does not cover installing skills or implementing the underlying product feature.
---

# Create a skill

Produce a focused, usable skill grounded in the user's actual workflow. Preserve the requested destination and scope; creating a skill does not authorize publishing it, installing it, or changing unrelated agent configuration.

## Authoritative guidance

Read the current [Agent Skills specification](https://agentskills.io/specification.md) and [skill creation best practices](https://agentskills.io/skill-creation/best-practices.md) before creating a skill or changing its format or workflow. If the browser cannot read Markdown responses, fetch these URLs with an available HTTP client. If access fails, use the requirements below, disclose the limitation, and avoid claiming current specification verification.

The specification defines format requirements; best practices guide design. Keep recommendations distinct from mandatory requirements.

## Establish scope and name

1. Identify the reusable task, intended users, inputs, successful output, and requests that should not activate the skill. Use supplied examples, corrections from completed tasks, project conventions, runbooks, schemas, or API documentation. Ask only for missing context that materially changes the result; do not invent domain expertise or unverified project facts.
2. Inspect existing skills in the destination and discoverable skill locations. Check frontmatter names as well as folder names, including bundled or plugin skills when visible. Update an existing skill when requested; do not overwrite a different skill merely because its name matches.
3. Choose a short, descriptive name and use it for both the folder and frontmatter. Prefer lowercase ASCII letters, digits, and single hyphens. The name must be 1–64 characters, with no leading, trailing, or consecutive hyphens. If a proposed name collides, choose a meaningful domain or action qualifier and explain the choice. Distinct names can still have overlapping triggers: narrow the description rather than pretending renaming resolves that overlap.

## Write the smallest useful skill

Start with `<destination>/<name>/SKILL.md`. Add other files only when they directly help execute the task. Use the dedicated editing tool when available.

Use this minimal structure, replacing the example values:

```markdown
---
name: export-report
description: Export an existing analysis as the team's report format. Use when the user requests a report from completed analysis; does not perform new analysis.
---

# Export a report

Read the supplied analysis and the team's report template. Populate the
template using supported findings, flag missing inputs, and verify the
exported document before delivering it.
```

### Frontmatter requirements

- `name` and `description` are required strings. The name must match the containing directory; the description must contain 1–1024 characters and explain both capability and activation conditions.
- Supported optional fields are `license`, `compatibility`, `metadata`, and `allowed-tools`. Omit them unless needed. `compatibility`, when present, contains 1–500 characters describing actual environment requirements. `metadata` maps string keys to string values. `allowed-tools` is an experimental space-separated string whose support depends on the host.
- Preserve valid existing optional values when updating. Do not invent licensing, dependencies, or permissions. Put host-specific extensions in separate host metadata files when supported, rather than adding unsupported top-level frontmatter fields.
- Write concrete trigger language in the description because it is available during discovery. Put execution steps in the body; exclusions should prevent plausible false activations.

### Instructions and resources

- Capture knowledge the agent would otherwise lack: specific tools, project constraints, verified gotchas, input/output conventions, and recovery steps. Cut generic expertise, repeated rules, and speculative features.
- Teach a reusable procedure rather than prescribing the answer to one example. Choose a default approach with a brief fallback when useful. Allow judgment for flexible work; prescribe exact sequences only where deviations have a concrete cost.
- Include a small input/output example or template when it clarifies an ambiguous workflow. State how to handle missing inputs, failed checks, or risky side effects when those situations apply to the task. Preserve the user's authorization boundaries.
- Keep `SKILL.md` below 500 lines and aim for fewer than 5,000 tokens; these are size recommendations, not frontmatter validity rules. Move substantial conditional detail into `references/` and say exactly when to read each reference.
- Use skill-root-relative links, preferably directly from `SKILL.md`, without deep reference chains. Put executable helpers in `scripts/`, documentation in `references/`, and output templates or other static resources in `assets/`.
- Bundle a script only when repeated execution or deterministic handling justifies it. Document its dependencies and inputs, provide useful failure messages, and run it. Avoid empty directories, scaffold placeholders, extra README files, or copied manuals without a concrete need.
- Avoid dependencies on another skill or a particular host unless required by the workflow. Never assume a named tool is available in every environment.

## Validate and refine

1. Validate the completed folder using the reference validator when available:

   ```bash
   skills-ref validate <destination>/<name>
   ```

   If `skills-ref` is not on `PATH` and `uvx` is available, run the reference implementation in an isolated tool environment:

   ```bash
   uvx --from 'git+https://github.com/agentskills/agentskills.git#subdirectory=skills-ref' skills-ref validate <destination>/<name>
   ```

   If only `uv` is available, replace `uvx` with `uv tool run` in that command. This requires network access unless the tool is already cached. If neither runner is available or fetching fails, use an existing local validator or check the frontmatter against the specification manually. State which validation actually ran. Fix reported issues and rerun the check; structural validation alone does not establish behavioral quality.

2. Check that relative resources exist, each has a clear loading condition, and all examples and commands fit the target environment. Run any new or changed executable helpers using representative inputs.
3. Exercise the instructions on a representative authorized task, preferably using supplied artifacts in a temporary workspace. Compare the observable result with the user's success criteria and inspect the steps for wasted work. Also assess a plausible near-miss request that should not activate the skill. Do not create external side effects merely to evaluate it. If execution is unavailable or requires additional authorization, report the gap rather than presenting a paper review as a passed behavioral test.
4. Revise only where the evidence shows missing guidance, false triggers, or unnecessary instructions. For later refinements, consider successful runs as well as failures; avoid growing a universal rule from one unusual example.

Deliver the skill path, explain any naming change or remaining trigger overlap, and summarize the checks performed and any untested behavior.
