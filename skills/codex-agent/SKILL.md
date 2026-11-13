---
name: codex-agent
description: Delegate a coding task to a Codex CLI agent (OpenAI Codex, gpt-6.1-terra) that runs in the background in its own git worktree and branch, in YOLO mode, and pause, resume, steer, answer or remove it. Use when the user asks to delegate work to Codex, spawn or run a Codex agent or sub-agent, or check, pause, continue, redirect or stop one. Not for the harness's own subagents or for running Codex reviews of a PR.
compatibility: Requires the codex CLI (logged in), git and bash.
---

# Codex agent

`scripts/codex-agent` runs `codex exec` with
`--dangerously-bypass-approvals-and-sandbox` (YOLO: no prompts, no sandbox)
and keeps each agent's state in `~/.cache/codex-agent/<name>/`: `meta`,
`prompt.md`, `inbox.md`, `log`, `log.all` and `last.md` (its final message).
In a git repository it creates the worktree `~/.cache/codex-agent/<name>/worktree`
on a new branch `codex/<name>`, from `--base` (default `HEAD`), so the user's
checkout and uncommitted files stay untouched.

The script prepends rules to every task: work only in the worktree, commit
there, never push or switch branches, read the inbox after each tool call,
and end with `QUESTION: …` when blocked or `DONE: …` when finished.

The script lives in `scripts/codex-agent`, relative to the folder that holds
this SKILL.md, whatever harness loaded it. Set `S` to its absolute path
(`S=<skill folder>/scripts/codex-agent`) for the commands below.

## Delegate

1. Pick a short name (`fix-login`) and the effort: `medium` for bounded or
   mechanical work (a rename, a test, a fix already decided), `high` for
   design, debugging with several possible causes, or reviews.
2. Write the brief to a temporary file: the goal, the files or area,
   the project rules to follow, the checks to run, and what done looks like.
   The agent knows only this brief and the repository.
3. Start it in the background with the harness's background shell (for
   example Claude Code's Bash `run_in_background`), from the repository or
   with `--repo`:

   ```bash
   $S start fix-login --effort medium --prompt-file /path/brief.md
   ```

   Do not poll when the harness notifies you of the exit. Without a
   background tool, run `nohup $S start … > out.txt 2>&1 &` and check
   `$S status <name>` later. The command's output is the state (`done`, `question`, `paused` or `failed`), the
   workdir, branch and session, and the agent's last message.
4. Treat that message as another model's claim: read the diff
   (`git -C <repo> diff HEAD...codex/<name>`) and run the checks before telling
   the user it works. Bring the work in only as the user decides (merge,
   cherry-pick, or a PR from the branch); never push it on your own.

## Answer a question

State `question` means the turn ended with `QUESTION:`. Ask the user unless
the brief already answers it, then continue in the background:

```bash
$S resume fix-login "Use option B: keep the config default."
```

## Steer while it runs

- `$S say fix-login "Stop touching the controller; only change Indexes."`
  appends to the inbox. The agent reads it after its next tool call, so a
  long single command (a test suite) finishes first.
- To redirect at once: `$S pause fix-login`, then
  `$S resume fix-login "<new direction>"` in the background.

## Pause and continue (soft stop)

`$S pause <name>` interrupts the run and keeps the worktree, branch and
session. `$S resume <name>` (in the background) continues where it stopped;
the agent remembers what it already did. A message replaces the default
"continue" one.

## Stop and clean up (hard stop)

`$S stop <name>` kills the run and deletes the worktree, the `codex/<name>`
branch with its unmerged commits, the Codex session and the state folder. It
cannot be undone: run it only when the user asked to discard the work, or
after the work has been merged or is no longer wanted.

## Inspect

- `$S status` lists every agent with its state, branch and workdir.
- `$S status <name>` shows its settings and last message.
- `$S log <name> [lines]` tails the current run's log (commands it ran,
  errors). `log.all` keeps every run.

## Gotchas

- `start` and `resume` block until the turn ends: always run them in the
  background. `say` and `pause` only work while it runs; `resume` refuses a
  running agent.
- `--no-worktree` makes the agent work in `--repo` itself, including its
  uncommitted files. Use it only for read-only tasks or a non-git folder.
- The default model is `gpt-6.1-terra`; `--model` or `CODEX_AGENT_MODEL`
  changes it. The user's Codex MCP servers also load; a failing one only logs
  an error.
- YOLO runs any command as the user. Keep briefs scoped, and never put
  secrets in them.
