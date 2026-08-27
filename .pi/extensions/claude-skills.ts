import { existsSync } from "node:fs";
import { dirname, join, parse } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", ({ cwd }) => {
    let directory = cwd;
    while (true) {
      const skills = join(directory, ".claude", "skills");

      if (existsSync(skills)) {
        return { skillPaths: [skills] };
      }

      const parent = dirname(directory);
      if (parent === directory || directory === parse(directory).root) return {};

      directory = parent;
    }
  });
}
