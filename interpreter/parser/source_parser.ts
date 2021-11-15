import { AstNode } from "./types.ts";
import { lexer } from "../parser/source_lexer.ts";

import {
  Grammar,
  Parser,
} from "https://deno.land/x/nearley@2.19.7-deno/mod.ts";

import { assertEquals } from "https://deno.land/std@0.84.0/testing/asserts.ts";

import compiledSrcGrammar from "../grammar/dist/grammar.ts";
import compiledTypeGrammar from "../grammar/dist/type_grammar.ts";
import compiledTypeAliasGrammar from "../grammar/dist/type_alias_grammar.ts";

const srcGrammar = Grammar.fromCompiled(compiledSrcGrammar);
const typeGrammar = Grammar.fromCompiled(compiledTypeGrammar);
const typeAliasGrammar = Grammar.fromCompiled(compiledTypeAliasGrammar);

enum TokenType {
  whitespace = "WHITESPACE",
  keyword = "KEYWORD",
  assign = "ASSING",
  reference = "REFERENCE",
  anonymous = "ANONYMOUS",
  blockEnd = "BLOCK_END",
  scopeEnd = "SCOPE_END",
  identifier = "IDENTIFIER",
  numberLiteral = "NUMBER_LITERAL",
  separator = "SEPARATOR",
  operator = "OPERATOR",
  lparen = "LPAREN",
  rparen = "RPAREN",
  lbrace = "LBRACE",
  rbrace = "RBRACE",
  lbracket = "LBRACKET",
  rbracket = "RBRACKET",
  dQuote = "D_QUOTE",
  sQuote = "S_QUOTE",
  tripleDQuotes = "TRIPLE_D_QUOTES",
  contents = "CONTENTS",
}

interface Token {
  type: TokenType;
  symbol: string;
}

function internalParser(tokens: Token[]): Token[][] {
  const tree = [];
  let segmentStart = 0;

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.type === TokenType.scopeEnd) {
      tree.push(tokens.slice(segmentStart, i++));
      segmentStart = i;
    }
  }

  return tree;
}

function runParser(parser: Parser, tokens: string): AstNode {
  // console.log("====>", tokens);

  const { results } = parser.feed(tokens);

  /*
    This assertion is important.
    Anything higher than 1 implies an ambiguous grammar and should be fixed.
  */
  assertEquals(results.length, 1);
  const [tree] = results;

  return tree as AstNode;
}

export function parser(source: string): [AstNode[], string[][]] {
  const lines = source.split("\n");

  const segment: string[] = lines;

  const [stringTable, tokens, signatures] = lexer(segment);
  // TODO replace these back
  // console.log("string table: ", "|" + stringTable.join("|") + "|");

  const semiTree = internalParser(tokens);

  const treeList: AstNode[] = [];
  for (let i = 0; i < semiTree.length; i++) {
    const nodes = semiTree[i];

    const tokenz: string[] = nodes.map((node: Token) => node.symbol);

    if (tokenz[0] === "module") continue;
    if (tokenz[0] === "import") continue;

    if (tokenz[0] === "type") {
      if (tokenz[2] === "alias") {
        // console.log("type alias");

        const parser = new Parser(typeAliasGrammar);

        const t = tokenz.join("");

        treeList.push(runParser(parser, t));
      } else {
        // console.log("type");

        const parser = new Parser(typeGrammar);

        const t = tokenz.join("");

        treeList.push(runParser(parser, t));
      }
    } else {
      // console.log("source");

      const parser = new Parser(srcGrammar);

      const t = tokenz.join("");

      treeList.push(runParser(parser, t));
    }
  }

  return [treeList, signatures];
}
