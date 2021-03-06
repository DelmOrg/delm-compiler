import { parser } from "./parser/source_parser.ts";
import { NodeType, AstNode, BranchNode } from "./parser/types.ts";
import { extractUpdate } from "./ast/extractors.ts";

const command = Deno.args[0];
const filename = Deno.args[1];

if (command !== "run") throw new Error(`Unkown command ${command}`);

if (!filename) throw new Error("No filename provided");

let [packageName] = filename.match(/(\w+).elm$/) || [""];
packageName = packageName.split(".")[0];

const run = async () => {
  const source = await Deno.readTextFile(`./src/${packageName}/${filename}`);
  const [treeList, sourceSignatures] = parser(source);
  const [updateFunctionName, signatureType] = extractUpdate(
    treeList,
    sourceSignatures,
  );

  // TODO continue here
  // const returnMap: Record<string, AstNode | undefined> = {};
  const returnMap: any = {};
  for (let i = 0; i < treeList.length; i++) {
    const tree: AstNode = treeList[i];
    if (
      tree.type === NodeType.DECLARATION &&
      tree.left?.function?.type === NodeType.IDENTIFIER &&
      tree.left?.function?.value === updateFunctionName &&
      tree.right?.type === NodeType.CASE
    ) {
      const { branches } = tree?.right;
      branches.map((branch: BranchNode) => {
        let retrn;
        if (
          branch.statement?.type === NodeType.TUPLE &&
          branch.statement?.value) {
          const [, , r] = branch.statement.value;
          retrn = r;
        } else if (
          branch.statement?.type === NodeType.SCOPE &&
          branch.statement?.statement.type === NodeType.TUPLE &&
          branch.statement?.statement?.value) {
          const [, , r] = branch.statement.statement.value;
          retrn = r;
        } else throw "Unexpected return value";

        let val;
        if (
          branch.match.type === NodeType.IDENTIFIER &&
          branch.match.value) {
          const { value } = branch.match;
          val = value;
        } else if (
          branch.match.type === NodeType.MATCH &&
          branch.match.branch.value) {
          const { value } = branch.match.branch;
          val = value;
        } else throw "Unexpected match value";

        returnMap[val] = retrn;
      });
    }
  }

  const signatureMap = [
    "INone",
    "ISingle",
    "ITuple2",
    "ITuple3",
  ];

  // TODO
  // vision: Code gen segment, separated from code syntax

  let signatures = "";
  signatures += "signatures : List ( String, Signature )" + "\n";
  signatures += "signatures =" + "\n";
  signatures += "\t" + "[";

  let encode = "";
  encode +=
    `encodeMsg : ( String, FunctionIO ) -> ${packageName}.${packageName}.Msg` +
    "\n";
  encode += "encodeMsg toEncode =" + "\n";
  encode += "\t" + "case toEncode of" + "\n";

  for (let i = 0; i < signatureType?.right.length; i++) {
    const node: any = signatureType?.right[i];
    let paramSig = "", paramEncode = "", variables: string[] = [];

    node.statements = node.statements ? node.statements : [];

    let num = node.statements[0]?.statements?.length;
    num = typeof num === "undefined" ? -1 : num;
    paramSig += signatureMap[num + 1];

    switch (num + 1) {
      case 0:
        break;
      case 1: {
        const s1 = node.statements[0].id;
        paramSig = `(${paramSig} I${s1.value})`;
        variables = ["a"];
        paramEncode = `Single (R${s1.value} a)`;
        break;
      }
      case 2: {
        const s1 = node.statements[0].id;
        const [s2] = node.statements[0].statements;
        paramSig = `(${paramSig} (I${s1.value}, I${s2.value}))`;
        variables = ["a", "b"];
        paramEncode = `Tuple2 ( R${s1.value} a, R${s2.value} b )`;
        break;
      }
      case 3: {
        const s1 = node.statements[0].id;
        const [s2, s3] = node.statements[0].statements;
        paramSig = `(${paramSig} (I${s1.value}, I${s2.value}, I${s3.value}))`;
        variables = ["a", "b", "c"];
        paramEncode =
          `Tuple3 ( R${s1.value} a, R${s2.value} b, R${s3.value} c )`;
        break;
      }
      default:
        break;
    }

    const retrn = returnMap[node.id.value]; // Assume always single for now
    const { value } = retrn.right[0] ? retrn.right[0].left : retrn.right.left;

    if (i > 0) {
      paramSig = `, ( "${node.id.value}" , Signature ${paramSig} (ISingle ${
        value.replace(/^./, "I")
      }) )`;
      signatures += "\t" + paramSig + "\n";
    } else {
      paramSig = ` ( "${node.id.value}" , Signature ${paramSig} (ISingle ${
        value.replace(/^./, "I")
      }) )`;
      signatures += paramSig + "\n";
    }

    paramEncode = "\t" + `( "${node.id.value}", ${
      paramEncode
        ? paramEncode
        : "None"
    } ) ->` + "\n";
    const variable = variables.length ? ` ${variables.join(" ")}` : "";
    paramEncode += "\t\t" + `${node.id.value}${variable}` +
      "\n";
    encode += paramEncode + "\n";
  }
  signatures += "\t" + "]" + "\n";
  encode += "\t" + "_ ->" + "\n";
  encode += "\t\t" + 'throw "Invalid Call"' + "\n";

  const elmInterpreterLayer = `module Deployer exposing (..)

import Concept.Contract as ContractModule exposing (Basic(..), ContractCore, FunctionIO(..), Interface(..), InterfaceIO(..), Signature, interpret)
import Concept.Core exposing (throw)
import ${packageName}.${packageName} exposing (..)


main : Program () (ContractModule.Model Model) ContractModule.Msg
main =
    interpret <|
        ContractCore ( ${packageName}.${packageName}.constructor, ITuple3 ( IString, IString, IInt ) )
            ${packageName}.${packageName}.update
            signatures
            encodeMsg


${signatures}

${encode}`.replace(/\t/g, "    ");

  await Deno.writeTextFile(
    `src/Deployer.elm`,
    elmInterpreterLayer,
  );
};

const wrap = async (p: any) => {
  const { code } = await p.status();

  // Reading the outputs closes their pipes
  const rawOutput = await p.output();
  const rawError = await p.stderrOutput();

  if (code === 0) {
    await Deno.stdout.write(rawOutput);
  } else {
    const errorString = new TextDecoder().decode(rawError);
    console.log(errorString);
  }
  return code;
};

await run();
const code = await wrap(Deno.run({
  cmd: ["elm", "make", `src/Deployer.elm`],
  stdout: "piped",
  stderr: "piped",
}));
if (code !== 0) Deno.exit(code);

const path = await Deno.realPath(`src/${packageName}/${packageName}.elm`);
const watcher = Deno.watchFs(`./src/${packageName}`);
let timeout = null;

// TODO ensure elm cli is installed

await Promise.all([
  wrap(Deno.run({
    cmd: ["elm", "reactor", `--port=8000`],
    stdout: "piped",
    stderr: "piped",
  })),
  (async () => {
    console.log("Watching changes");

    for await (const event of watcher) {
      if (event.kind === "modify" && event.paths[0] === path) {
        console.clear();
        console.log("Watching changes");
        if (timeout) continue;
        timeout = 500;
        setTimeout(async () => {
          timeout = null;

          try {
            await run();
          } catch (e: any) {}

          await wrap(Deno.run({
            cmd: ["elm", "make", `src/Deployer.elm`],
            stdout: "piped",
            stderr: "piped",
          }));
        }, timeout);
      } else {
        // TODO make modular, as this is only useful when coding the interpreter
        // await wrap(Deno.run({
        //   cmd: ["elm", "make", `src/Deployer.elm`],
        //   stdout: "piped",
        //   stderr: "piped",
        // }));
      }
    }
  })(),
]);
