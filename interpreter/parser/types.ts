
export enum NodeType {
	IDENTIFIER = 'IDENTIFIER',
	ARRAY = 'ARRAY',
	FUNCTION_CALL = 'FUNCTION_CALL',
	STRING = 'STRING',
	SUM = 'SUM',
	PRODUCT = 'PRODUCT',
	EXPOENT = 'EXPOENT',
	LITERAL = 'LITERAL',
	COMPARATOR = 'COMPARATOR',
	TUPLE = 'TUPLE',
	BRANCH = 'BRANCH',
	SCOPE = 'SCOPE',
	RECORD = 'RECORD',
	DECLARATION = 'DECLARATION',
	TYPE_DECLARATION = 'TYPE_DECLARATION',
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


type IdentifierNode = {
	type: NodeType.IDENTIFIER,
	value: string,
	// value: string | AstNode | null,
};

type ArrayNode = {
	type: NodeType.ARRAY,
	value: AstNode | null,
};

type FunctionCallNode = {
	type: NodeType.FUNCTION_CALL,
	left: AstNode,
	right: AstNode | AstNode[],
};

type StringNode = {
	type: NodeType.STRING,
	value: string,
	position: string | number,
};

type SumNode = {
	type: NodeType.SUM,
	operation: Operator.SUM | Operator.SUB,
	left: AstNode,
	right: AstNode,
};

type ProductNode = {
	type: NodeType.PRODUCT,
	operation: Operator.MUL | Operator.DIV | Operator.DIV_INT,
	left: AstNode,
	right: AstNode,
};

type ExpoentNode = {
	type: NodeType.EXPOENT,
	operation: Operator.EXP,
	left: AstNode,
	right: AstNode,
};

type LiteralNode = {
	type: NodeType.LITERAL,
	value: string,
};

type ComparatorNode = {
	type: NodeType.COMPARATOR,
	comparator: Comparator,
	left: AstNode,
	right: AstNode,
};

type TupleNode = {
	type: NodeType.TUPLE,
	value: [AstNode, AstNode, AstNode?],
};

type Match = {
	branch: IdentifierNode,
	param: Match | IdentifierNode,
};

type BranchNode = {
	type: NodeType.BRANCH,
	match: Match,
	statement: AstNode,
};

type Declaration = {
	left: IdentifierNode,
	right: AstNode,
};

type ScopeNode = {
	type: NodeType.SCOPE,
	declarations: Declaration[],
	statement: AstNode,
};

type RecordItem = {
	key: IdentifierNode,
	value: AstNode,
};

type RecordNode = {
	type: NodeType.RECORD,
	update: IdentifierNode,
	value: RecordItem[],
};

type _Declaration = {
	function: IdentifierNode,
	parameters: AstNode[],
};

type DeclarationNode = {
	type: NodeType.DECLARATION,
	left: _Declaration,
	right: AstNode,
};

type TypeDeclarationNode = {
	type: NodeType.TYPE_DECLARATION,
	// TODO
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
	| ComparatorNode
	| TupleNode
	| BranchNode
	| ScopeNode
	| RecordNode
	| DeclarationNode
	| TypeDeclarationNode;
