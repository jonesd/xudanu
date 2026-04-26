import type {
  WorkspaceListItem,
  CreateWorkspaceRequest,
  CreateWorkspaceResponse,
  BranchItem,
  DocumentResponse,
} from "../types/api";

const BASE = "/api";

async function jsonFetch<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error?.message ?? `HTTP ${res.status}`);
  }
  return res.json();
}

export function listWorkspaces(): Promise<WorkspaceListItem[]> {
  return jsonFetch<WorkspaceListItem[]>(`${BASE}/workspaces`);
}

export function createWorkspace(
  req: CreateWorkspaceRequest,
): Promise<CreateWorkspaceResponse> {
  return jsonFetch<CreateWorkspaceResponse>(`${BASE}/workspaces`, {
    method: "POST",
    body: JSON.stringify(req),
  });
}

export function listBranches(workspaceId: string): Promise<BranchItem[]> {
  return jsonFetch<BranchItem[]>(
    `${BASE}/workspaces/${workspaceId}/branches`,
  );
}

export function getDocument(
  workspaceId: string,
  traceId: string,
): Promise<DocumentResponse> {
  return jsonFetch<DocumentResponse>(
    `${BASE}/workspaces/${workspaceId}/document?traceId=${traceId}`,
  );
}

export interface AssertionResponse {
  traceId: string;
}

export function postAssertion(
  workspaceId: string,
  assertion: object,
): Promise<AssertionResponse> {
  return jsonFetch<AssertionResponse>(
    `${BASE}/workspaces/${workspaceId}/assertions`,
    {
      method: "POST",
      body: JSON.stringify(assertion),
    },
  );
}

export function setSpanText(
  workspaceId: string,
  spanId: number,
  text: string,
): Promise<AssertionResponse> {
  return postAssertion(workspaceId, {
    type: "SetSpanText",
    spanId,
    text,
  });
}
