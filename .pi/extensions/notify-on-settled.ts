import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", () => {
    const child = spawn("notify-send", ["Pi", "Finished responding"], {
      detached: true,
      stdio: "ignore",
    });
    child.unref();
  });
}
