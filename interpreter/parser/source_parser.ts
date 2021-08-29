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

type Operator =
  | ">"
  | "<"
  | ">="
  | "<="
  | "&&"
  | "||"
  | "<|"
  | "|>"
  | ">>"
  | "<<"
  | "++"
  | "=="
  | "/="
  | "+"
  | "-"
  | "*"
  | "/"
  | "//"
  | "^";

// --------------

interface LiteralNode {
  type: "LiteralNode";
  value: number | string;
}

interface TupleNode {
  type: "TupleNode";
  values: [AstNode, AstNode, AstNode?];
}

interface OperatorNode {
  type: "OperatorNode";
  operator: Operator;
  left: AstNode;
  right: AstNode;
}

interface CallNode {
  type: "CallNode";
  callee: Token;
  parameters: AstNode[];
}

interface DeclarationNode {
  type: "DeclarationNode";
  callee: Token;
  parameters: Token[];
  body: AstNode;
}

interface DecisionNode {
  type: "DecisionNode";
  condition: AstNode;
  branches: [[LiteralNode, AstNode]];
}

interface AstNode {
  scope: Token[];
  node:
    | DeclarationNode
    | CallNode
    | DecisionNode
    | OperatorNode
    | TupleNode
    | LiteralNode;
}

export function parser(tokens: Token[]): Token[][] {
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
