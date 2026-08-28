import { existsSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", ({ cwd }) => {
    const agentsSkills = join(cwd, ".agents", "skills");
    if (existsSync(agentsSkills)) {
      return { skillPaths: [agentsSkills] };
    }

    const claudeSkills = join(cwd, ".claude", "skills");
    if (existsSync(claudeSkills)) {
      return { skillPaths: [claudeSkills] };
    }

    return {};
  });
}
