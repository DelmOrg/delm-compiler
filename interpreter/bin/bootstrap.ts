import { assertEquals } from "https://deno.land/std@0.106.0/testing/asserts.ts";

interface InstallParams {
  bin: string;
}

async function installWithNpm(pckg: string, params?: InstallParams) {
  const { bin } = params || {};

  const packageCmd = await Deno.run({
    cmd: [
      "which",
      bin || pckg,
    ],
    stdout: "null",
  });

  const { success: hasPackage } = await packageCmd.status();

  if (!hasPackage) {
    const cmd = await Deno.run({
      cmd: [
        "npm",
        "install",
        pckg,
        "-g",
      ],
      stdout: "piped",
    });
    const { success } = await cmd.status();
    cmd.close();

    if (!success) {
      throw new Error("Failed to install nearley");
    }
  }
}

async function ensurePackageVersion(cmdArray: string[], version: string) {
  const cmd = await Deno.run({
    cmd: cmdArray,
    stdout: "piped",
  });
  const output = await cmd.output();
  cmd.close();
  const outStr = new TextDecoder().decode(output);

  assertEquals(version.trim(), outStr.trim());
}

await installWithNpm("nearley", { bin: "nearleyc" });
await ensurePackageVersion(["nearleyc", "--version"], "2.20.1");
