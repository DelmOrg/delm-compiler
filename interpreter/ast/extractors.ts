import { AstNode, SpecialValues, TypeDeclarationNode } from "../parser/types.ts";
import { NodeType } from "../parser/types.ts";

export function extractUpdate(treeList: AstNode[], signatures: string[][]): [string, TypeDeclarationNode] {
	const typeMap: Record<string, TypeDeclarationNode> = {};
  let updateFunctionName = "", signatureType;

  for (let i = 0; i < treeList.length; i++) {
    const tree = treeList[i];
    if (
      tree.type === NodeType.DECLARATION &&
      tree.left?.function?.type === NodeType.IDENTIFIER &&
      tree.left?.function?.value === SpecialValues.MAIN_FUNCTION
    ) {
      let ast = tree?.right;
      if (ast?.type === NodeType.FUNCTION_CALL && !Array.isArray(ast?.right)) {
        ast = ast?.right;
        if (
          ast.type === NodeType.FUNCTION_CALL &&
          Array.isArray(ast?.right) &&
          ast.right[1]?.type === NodeType.IDENTIFIER
        ) {
          const [, { value }] = ast.right;
          updateFunctionName = value;
        }
      }
    }

    if (tree.type === NodeType.TYPE_DECLARATION) {
			typeMap[tree.left.value] = tree;
    }
  }

	for (const signature of signatures) {
    const [functionName, , msgTypeName] = signature;

    if (functionName === updateFunctionName) {
      signatureType = typeMap[msgTypeName];
    }
	}

  if (!updateFunctionName) {
    console.log("update function not found");
    throw "";
  }

  if (!signatureType) {
    console.log("signatureType not found");
    throw "";
  }

  return [updateFunctionName, signatureType];
}