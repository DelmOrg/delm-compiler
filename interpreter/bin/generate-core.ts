async function generateElmFile(name: string) {
  const file = await Deno.readTextFile(`../examples/src/Concept/${name}.elm`);

  await Deno.writeTextFile(
    `codegen/core/${name}.ts`,
    `
export const ${name} = \`
${file.replaceAll("\\", "\\\\")}
\`;
`,
  );
}

async function generateElmJsonFile() {
  const file = await Deno.readTextFile(`../examples/elm.json`);

  await Deno.writeTextFile(
    `codegen/core/elm.json.ts`,
    `
export const ElmJson = \`
    ${file}
\`;
`,
  );
}

await generateElmFile("Core");
await generateElmFile("Contract");
await generateElmFile("DefaultValues");
await generateElmFile("Mapping");
await generateElmJsonFile();
