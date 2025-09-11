/** domain/reporting/types.ts */
export type FieldRef = { name: string; alias?: string };
export type FilterOp = "eq" | "ne" | "gt" | "lt" | "gte" | "lte" | "in" | "contains";

export type FilterExpr = {
  field: string;
  op: FilterOp;
  value: unknown;
};

export type SortSpec = { field: string; dir: "asc" | "desc" };

export type ReportSpec = {
  source: string;              // 데이터 소스 식별자
  fields: FieldRef[];
  filters?: FilterExpr[];
  groupBy?: string[];
  sort?: SortSpec[];
  limit?: number;
  format: "csv" | "json";
};
