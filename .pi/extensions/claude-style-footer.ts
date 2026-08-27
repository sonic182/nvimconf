import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const execFileAsync = promisify(execFile);

interface CodexbarWindow {
  usedPercent?: number;
  resetsAt?: string;
}

interface CodexbarOutput {
  usage?: {
    primary?: CodexbarWindow;
    secondary?: CodexbarWindow | null;
  };
}

interface Quota {
  sessionPercent: number;
  sessionReset: string;
  weeklyPercent?: number;
  weeklyReset?: string;
}

function formatReset(resetsAt: string, includeDate: boolean): string {
  const date = new Date(resetsAt);
  if (Number.isNaN(date.getTime())) return resetsAt;

  return new Intl.DateTimeFormat("en-GB", {
    ...(includeDate ? { day: "2-digit", month: "short" } : {}),
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(date).replace(",", " at");
}

function parseQuota(output: string): Quota | undefined {
  const payload: unknown = JSON.parse(output);
  const account = Array.isArray(payload) ? payload[0] : payload;
  if (!account || typeof account !== "object") return undefined;

  const { usage } = account as CodexbarOutput;
  const primary = usage?.primary;
  if (typeof primary?.usedPercent !== "number" || !primary.resetsAt) return undefined;

  const secondary = usage?.secondary;
  return {
    sessionPercent: primary.usedPercent,
    sessionReset: formatReset(primary.resetsAt, false),
    weeklyPercent: typeof secondary?.usedPercent === "number" ? secondary.usedPercent : undefined,
    weeklyReset: secondary?.resetsAt ? formatReset(secondary.resetsAt, true) : undefined,
  };
}

function formatTokens(tokens: number): string {
  return tokens < 1_000 ? `${tokens}` : `${(tokens / 1_000).toFixed(tokens < 10_000 ? 1 : 0)}k`;
}

function quotaBar(percent: number, width = 10): string {
  const filled = Math.max(0, Math.min(width, Math.round((percent / 100) * width)));
  return "█".repeat(filled) + "░".repeat(width - filled);
}

function isCodexModel(modelId?: string): boolean {
  return /(?:^|[-/])(gpt|codex)|openai/i.test(modelId ?? "");
}

const REFRESH_COOLDOWN_MS = 5 * 60_000;

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    let quota: Quota | undefined;
    let requestRender = () => {};
    let refreshing = false;
    let lastFetchAt = 0;
    let effort = ctx.thinkingLevel ?? "off";

    const refreshQuota = async () => {
      if (refreshing) return;
      if (!isCodexModel(ctx.model?.id)) {
        quota = undefined;
        requestRender();
        return;
      }
      if (Date.now() - lastFetchAt < REFRESH_COOLDOWN_MS) return;

      refreshing = true;
      lastFetchAt = Date.now();
      try {
        const { stdout } = await execFileAsync(
          "codexbar",
          ["usage", "--format", "json", "--provider", "codex"],
          { timeout: 10_000 },
        );
        quota = parseQuota(stdout);
      } catch {
        quota = undefined;
      } finally {
        refreshing = false;
        requestRender();
      }
    };

    pi.on("model_select", () => void refreshQuota());
    pi.on("thinking_level_select", (event) => {
      effort = event.level;
      requestRender();
    });
    pi.on("agent_settled", () => {
      requestRender();
      void refreshQuota();
    });

    ctx.ui.setFooter((tui, theme, footerData) => {
      requestRender = () => tui.requestRender();
      const unsubscribe = footerData.onBranchChange(requestRender);
      void refreshQuota();

      const usage = (label: string, percent: number, reset: string) => {
        const color = percent >= 90 ? "error" : percent >= 70 ? "warning" : "success";
        return `${theme.fg("muted", `${label} `)}${theme.fg(color, quotaBar(percent))} ${theme.fg(color, `${percent}%`)}${theme.fg("muted", ` · resets ${reset}`)}`;
      };

      return {
        dispose() {
          unsubscribe();
        },
        invalidate() {},
        render(width: number): string[] {
          const branch = footerData.getGitBranch();
          const statuses = [...footerData.getExtensionStatuses().values()];
          const contextUsage = ctx.getContextUsage();
          const contextTokens = contextUsage?.tokens;
          const contextWindow = ctx.model?.contextWindow;
          const context = contextTokens === undefined || contextWindow === undefined
            ? "context: unavailable"
            : `context: ${formatTokens(contextTokens)}/${formatTokens(contextWindow)}`;

          const header = [
            theme.fg("accent", `[${ctx.model?.id ?? "no model"}]`),
            theme.fg("muted", context),
            theme.fg("muted", `effort: ${effort}`),
            theme.fg("muted", `cwd: ${ctx.cwd}`),
            branch ? theme.fg("muted", `| ${branch}`) : "",
            ...statuses,
          ].filter(Boolean).join(" ");

          const lines = [truncateToWidth(header, width)];
          if (quota) {
            const session = usage("Session", quota.sessionPercent, quota.sessionReset);
            const weekly = quota.weeklyPercent === undefined || !quota.weeklyReset
              ? ""
              : `  ${usage("Week", quota.weeklyPercent, quota.weeklyReset)}`;
            lines.push(truncateToWidth(session + weekly, width));
          }
          return lines;
        },
      };
    });
  });
}
