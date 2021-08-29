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

export interface Token {
  type: TokenType;
  symbol: string;
}

const keywords = [
  "port",
  "module",
  "exposing",
  "import",
  "as",
  "(..)",
  "type",
  "alias",
  "case",
  "of",
  "_",
  "->",
  "let",
  "in",
];

const operators = [
  ">",
  "<",
  ">=",
  "<=",
  "&&",
  "||",
  "<|",
  "|>",
  ">>",
  "<<",
  "++",
  "==",
  "/=",
  "+",
  "-",
  "*",
  "/",
  "//",
  "^",
];

const ignore = [
  " ",
  "",
];

export function lexer(lines: string[]): [string[], Token[]] {
  const stringTable: string[] = [];

  const tokens: Token[] = [];
  let inMultilineComment = 0,
    inMultilineString = false,
    multilineStringContent = "",
    alias = false;

  for (const line of lines) {
    let lexedLine = line.trim();
    if (inMultilineComment) {
      const commentOpen = (lexedLine.match(/{-/g) || []).length;
      inMultilineComment += commentOpen;
      const commentClose = (lexedLine.match(/-}/g) || []).length;
      inMultilineComment -= commentClose;
      continue;
    } else {
      const commentOpen = (lexedLine.match(/{-/g) || []).length;
      if (commentOpen > 0 && !inMultilineString) {
        inMultilineComment += commentOpen;
        const commentClose = (lexedLine.match(/-}/g) || []).length;
        inMultilineComment -= commentClose;
        if (inMultilineComment) {
          continue;
        }
      }
    }

    if (inMultilineString) {
      const commentEnd = line.indexOf('"""');
      if (commentEnd !== -1) {
        multilineStringContent += line.slice(0, commentEnd);
        tokens.push({
          type: TokenType.contents,
          symbol: `$STRING_LITERAL$ ${stringTable.length}`,
        });
        stringTable.push(multilineStringContent);
        inMultilineString = false;
        multilineStringContent = "";
        tokens.push({
          type: TokenType.tripleDQuotes,
          symbol: '"',
        });
        tokens.push({
          type: TokenType.whitespace,
          symbol: " ",
        });
        const lineContinuation = line.slice(commentEnd + 3);
        if (lineContinuation) {
          throw "unhandled multiline string";
        }
        continue;
      }
      multilineStringContent += `${line}\n`;
      continue;
    } else if (lexedLine.slice(0, 3) === '"""') {
      console.log(
        "Warning: Proper multiline strings have not been implemented yet.",
      );

      inMultilineString = true;
      tokens.push({
        type: TokenType.tripleDQuotes,
        symbol: '"', // TODO triple quotes
      });
      const content = lexedLine.slice(3);
      if (content) multilineStringContent += `${lexedLine.slice(3)}\n`;
      continue;
    }

    if (lexedLine.slice(0, 2) == "--") continue;

    if (
      !alias &&
      lexedLine.includes(":") &&
      (!lexedLine.match(/\"/g))
    ) {
      continue;
    }

    if (line == "" && tokens.length) {
      if (tokens[tokens.length - 2].type === TokenType.blockEnd) {
        tokens[tokens.length - 3] = ({
          type: TokenType.scopeEnd,
          symbol: "\\n\\n",
        });
        alias = false;
        tokens.pop();
        tokens.pop(); // to remove last whitespace
      } else {
        tokens.push({
          type: TokenType.blockEnd,
          symbol: "\\n",
        });
        tokens.push({
          type: TokenType.whitespace,
          symbol: " ",
        });
      }
      continue;
    }

    const contents: string[] = [""],
      replaceLineIndexes = [[0, 0]];

    let iContent = 0,
      insideContent = "",
      skipNext = false;
    if (lexedLine.includes('"') || lexedLine.includes("'")) {
      // generate contents
      for (let i = 0; i < lexedLine.length; i++) {
        const char = lexedLine[i];
        if (skipNext) {
          skipNext = false;
        } else if (char === '"' && !insideContent) {
          insideContent = '"';
          contents[iContent] = "";
          replaceLineIndexes[iContent] = [i, 0];
        } else if (char === "'" && !insideContent) {
          insideContent = "'";
          contents[iContent] = "";
          replaceLineIndexes[iContent] = [i, 0];
        } else if (insideContent && char === insideContent) {
          const [a] = replaceLineIndexes[iContent];
          replaceLineIndexes[iContent] = [a, i];
          insideContent = "";
          iContent++;
        } else if (insideContent && char === "\\") {
          skipNext = true;
          contents[iContent] += `\\${lexedLine[i + 1]}`;
        } else if (insideContent) {
          contents[iContent] += char;
        }
      }
    }
    let metaContentLine = "", begin = 0, currentContent = 0;
    if (replaceLineIndexes[0][0]) {
      for (let i = 0; i < replaceLineIndexes.length; i++) {
        const [start, end] = replaceLineIndexes[i];
        metaContentLine += lexedLine.slice(begin, start);
        metaContentLine += lexedLine[start];
        metaContentLine += "$CONTENT$";

        const [next] = replaceLineIndexes[i + 1] || [lexedLine.length + 1];

        metaContentLine += lexedLine.slice(end, next);
        begin = next;
      }
      // console.log(lexedLine);
      // console.log(contents);
      // console.log(metaContentLine);
    }

    lexedLine = metaContentLine || lexedLine;
    lexedLine = lexedLine.replace(/\(([^.])/g, "( $1");
    lexedLine = lexedLine.replace(/([^.])\)/g, "$1 )");
    lexedLine = lexedLine.replace(/\[(.)/g, "[ $1");
    lexedLine = lexedLine.replace(/(.)\]/g, "$1 ]");
    lexedLine = lexedLine.replace(/(.),/g, "$1 ,");
    lexedLine = lexedLine.replace(/\(\.\.\)/g, " (..) ");
    lexedLine = lexedLine.replace(/\\([a-zA-Z])/g, "\\ $1");
    lexedLine = lexedLine.replace(/"/g, ' " ');
    lexedLine = lexedLine.replace(/'/g, " ' ");

    const words = lexedLine.split(" ");

    for (const word of words) {
      if (keywords.includes(word)) {
        if (word === "alias") alias = true;
        tokens.push({
          type: TokenType.keyword,
          symbol: word,
        });
      } else if (operators.includes(word)) {
        tokens.push({
          type: TokenType.operator,
          symbol: word,
        });
      } else {
        switch (word) {
          case "(":
            tokens.push({
              type: TokenType.lparen,
              symbol: "(",
            });
            break;
          case ")":
            tokens.push({
              type: TokenType.rparen,
              symbol: ")",
            });
            break;
          case "[":
            tokens.push({
              type: TokenType.lbracket,
              symbol: "[",
            });
            break;
          case "]":
            tokens.push({
              type: TokenType.rbracket,
              symbol: "]",
            });
            break;
          case "{":
            tokens.push({
              type: TokenType.lbrace,
              symbol: "{",
            });
            break;
          case "}":
            tokens.push({
              type: TokenType.rbrace,
              symbol: "}",
            });
            break;
          case "|":
          case ",":
            tokens.push({
              type: TokenType.separator,
              symbol: word,
            });
            break;
          case "=":
            tokens.push({
              type: TokenType.assign,
              symbol: "=",
            });
            break;
          case ":":
            tokens.push({
              type: TokenType.reference,
              symbol: ":",
            });
            break;
          case "\\":
            tokens.push({
              type: TokenType.anonymous,
              symbol: "\\",
            });
            break;
          case '"':
            tokens.push({
              type: TokenType.dQuote,
              symbol: '"',
            });
            break;
          case "'":
            tokens.push({
              type: TokenType.sQuote,
              symbol: "'",
            });
            break;
          case "$CONTENT$": {
            const i = currentContent++;
            tokens.push({
              type: TokenType.contents,
              symbol: `$STRING_LITERAL$ ${stringTable.length}`,
            });
            stringTable.push(contents[i]);
            break;
          }
          default:
            if (!ignore.includes(word)) {
              if (
                word.match(/^[-]?[\d+]/g) ||
                word.match(/^[-]?[\d+]\.[\d+]/g) ||
                word.match(/^[-]?0x[0-9|A|a|B|b|C|c|D|d|E|e|F|f]+/g)
              ) {
                tokens.push({
                  type: TokenType.numberLiteral,
                  symbol: word,
                });
              } else {
                tokens.push({
                  type: TokenType.identifier,
                  symbol: word,
                });
              }
              break;
            }
        }
      }

      const lastToken = tokens.length > 1
        ? tokens[tokens.length - 1].type
        : TokenType.keyword;
      const tokenBeforeLastToken = tokens.length > 2
        ? tokens[tokens.length - 2].type
        : TokenType.keyword;

      if (
        tokens.length &&
        lastToken != TokenType.whitespace
        // && lastToken != TokenType.contents
        // && (lastToken != TokenType.dQuote || (lastToken == TokenType.dQuote && tokenBeforeLastToken == TokenType.contents))
      ) {
        tokens.push({
          type: TokenType.whitespace,
          symbol: " ",
        });
      }
    }
  }

  let lastToken = tokens[tokens.length - 1];
  while (
    [
      TokenType.whitespace,
      TokenType.blockEnd,
    ].includes(lastToken.type)
  ) {
    tokens.pop();
    lastToken = tokens[tokens.length - 1];
  }

  tokens.push({
    type: TokenType.scopeEnd,
    symbol: "\\n\\n",
  });

  return [stringTable, tokens];
}
