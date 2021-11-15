export enum NodeType {
  IDENTIFIER = "IDENTIFIER",
  ARRAY = "ARRAY",
  FUNCTION_CALL = "FUNCTION_CALL",
  STRING = "STRING",
  SUM = "SUM",
  PRODUCT = "PRODUCT",
  EXPOENT = "EXPOENT",
  LITERAL = "LITERAL",
  COMPARATOR = "COMPARATOR",
  TUPLE = "TUPLE",
  BRANCH = "BRANCH",
  CASE = "CASE",
  MATCH = "MATCH",
  SCOPE = "SCOPE",
  RECORD = "RECORD",
  DECLARATION = "DECLARATION",
  TYPE_DECLARATION = "TYPE_DECLARATION",
  TYPE_STATEMENT = "TYPE_STATEMENT",
}

export enum SpecialValues {
  MAIN_FUNCTION = "main",
}

enum Operator {
  SUM,
  SUB,
  MUL,
  DIV,
  DIV_INT,
  EXP,
}

enum Comparator {
  BIGGER_THAN,
  SMALLER_THAN,
  BIGGER_THAN_OR_EQUAL,
  SMALLER_THAN_OR_EQUAL,
  EQUALS,
  DIFFERENT_THAN,
  OR,
  AND,
}

export type IdentifierNode = {
  type: NodeType.IDENTIFIER;
  value: string;
  // value: string | AstNode | null,
};

export type ArrayNode = {
  type: NodeType.ARRAY;
  value: AstNode | null;
};

export type FunctionCallNode = {
  type: NodeType.FUNCTION_CALL;
  left: AstNode;
  right: AstNode | AstNode[];
};

export type StringNode = {
  type: NodeType.STRING;
  value: string;
  position: string | number;
};

export type SumNode = {
  type: NodeType.SUM;
  operation: Operator.SUM | Operator.SUB;
  left: AstNode;
  right: AstNode;
};

export type ProductNode = {
  type: NodeType.PRODUCT;
  operation: Operator.MUL | Operator.DIV | Operator.DIV_INT;
  left: AstNode;
  right: AstNode;
};

export type ExpoentNode = {
  type: NodeType.EXPOENT;
  operation: Operator.EXP;
  left: AstNode;
  right: AstNode;
};

export type LiteralNode = {
  type: NodeType.LITERAL;
  value: string;
};

export type ComparatorNode = {
  type: NodeType.COMPARATOR;
  comparator: Comparator;
  left: AstNode;
  right: AstNode;
};

export type TupleNode = {
  type: NodeType.TUPLE;
  value: [AstNode, AstNode, AstNode?];
};

export type CaseNode = {
  type: NodeType.CASE;
  condition: IdentifierNode;
  branches: BranchNode[];
};

export type Match = {
  type: NodeType.MATCH;
  branch: IdentifierNode;
  param: Match | IdentifierNode;
};

export type BranchNode = {
  type: NodeType.BRANCH;
  match: Match | IdentifierNode;
  statement: AstNode;
};

export type Declaration = {
  left: IdentifierNode;
  right: AstNode;
};

export type ScopeNode = {
  type: NodeType.SCOPE;
  declarations: Declaration[];
  statement: AstNode;
};

export type RecordItem = {
  key: IdentifierNode;
  value: AstNode;
};

export type RecordNode = {
  type: NodeType.RECORD;
  update: IdentifierNode;
  value: RecordItem[];
};

type _Declaration = {
  function: IdentifierNode;
  parameters: AstNode[];
};

export type DeclarationNode = {
  type: NodeType.DECLARATION;
  left: _Declaration;
  right: AstNode;
};

export type TypeStatementNode = {
  type: NodeType.TYPE_STATEMENT;
  id: IdentifierNode;
  statements: TypeStatementNode[];
};

export type TypeDeclarationNode = {
  type: NodeType.TYPE_DECLARATION;
  left: IdentifierNode;
  right: TypeStatementNode[];
};

export type AstNode =
  | IdentifierNode
  | FunctionCallNode
  | ArrayNode
  | StringNode
  | SumNode
  | ProductNode
  | ExpoentNode
  | LiteralNode
  | CaseNode
  | ComparatorNode
  | TupleNode
  | BranchNode
  | ScopeNode
  | RecordNode
  | DeclarationNode
  | TypeDeclarationNode;
