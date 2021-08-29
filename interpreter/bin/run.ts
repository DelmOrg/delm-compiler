async function compileGrammar(name: string) {
  const cmd = await Deno.run({
    cwd: "./grammar",
    cmd: [
      "nearleyc",
      `${name}.ne`,
      "-o",
      `dist/${name}.ts`,
    ],
    stdout: "piped",
  });
  const { success } = await cmd.status();
  cmd.close();

  if (!success) {
    throw new Error("Compilation failed");
  }
}
await compileGrammar("grammar");
await compileGrammar("type_alias_grammar");
await compileGrammar("type_grammar");
