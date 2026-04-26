export interface WorkspaceListItem {
  workspaceId: string;
  name: string;
}

export interface CreateWorkspaceRequest {
  name: string;
}

export interface CreateWorkspaceResponse {
  workspaceId: string;
}

export interface BranchItem {
  branchId: string;
  name: string;
  headTraceId: string;
}

export type ApiText =
  | { type: "single"; value: string }
  | { type: "alternatives"; values: string[] };

export interface ApiAnnotation {
  annotationId: string;
  kind: string;
  payload: string;
}

export interface ApiSpan {
  spanId: string;
  text: ApiText;
  annotations?: ApiAnnotation[];
}

export interface ApiNode {
  nodeId: string;
  kind: string;
  children?: ApiNode[];
  spans?: ApiSpan[];
  annotations?: ApiAnnotation[];
}

export interface DocumentResponse {
  workspaceId: string;
  traceId: string;
  document: ApiNode | null;
}
