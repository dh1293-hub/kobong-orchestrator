export type Identifier = string;

export interface SelectNode {
  type: "Select";
  columns: Identifier[];
  from: Identifier;
  where?: string; // v0.4: 문자열 포함 규칙 (후속 확장 예정)
}

export type AST = SelectNode;