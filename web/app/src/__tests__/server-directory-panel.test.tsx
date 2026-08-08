import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { ServerDirectoryPanel, type DirectoryServer } from "../components/ServerDirectoryPanel";

function mkClient(response: unknown = { servers: [] }, workData?: Record<string, unknown>, worksList?: unknown[]) {
  return {
    sendRequest: vi.fn().mockImplementation((op: string) => {
      if (op === "cross_server_fetch_work" && workData) return Promise.resolve(workData);
      if (op === "cross_server_list_works") return Promise.resolve({ works: worksList ?? [{ work_id: "42", title: "Remote Doc", revision: 3, char_count: 100 }] });
      return Promise.resolve(response);
    }),
  } as any;
}

const mkServer = (over: Partial<DirectoryServer> = {}): DirectoryServer => ({
  server_id: "aabb",
  address: "alice.example.com",
  port: 8081,
  name: "Alice",
  description: "Alice's server",
  trusted: true,
  ...over,
});

describe("ServerDirectoryPanel", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn());
  });
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("renders 'Not connected' when disconnected", () => {
    const { container } = render(
      <ServerDirectoryPanel client={null} connected={false} onNavigateToWork={vi.fn()} />,
    );
    expect(container.textContent).toContain("Not connected");
  });

  it("renders 'Not connected' when client is null but connected flag is true", () => {
    const { container } = render(
      <ServerDirectoryPanel client={null} connected={true} onNavigateToWork={vi.fn()} />,
    );
    expect(container.textContent).toContain("Not connected");
  });

  it("shows empty state when directory has no servers", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/No servers in directory/)).toBeTruthy();
    });
  });

  it("lists servers from directory_list response", async () => {
    const client = mkClient({
      servers: [mkServer({ name: "Alice" }), mkServer({ server_id: "ccdd", name: "Bob" })],
    });
    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(container.textContent).toContain("Alice");
      expect(container.textContent).toContain("Bob");
    });
  });

  it("handles directory_list wrapped in { value: ... }", async () => {
    const client = mkClient({
      value: { servers: [mkServer({ name: "Wrapped" })] },
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Wrapped/)).toBeTruthy();
    });
  });

  it("handles directory_list returning bare array", async () => {
    const client = mkClient([mkServer({ name: "BareArr" })]);
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/BareArr/)).toBeTruthy();
    });
  });

  it("sets servers to empty on directory_list error", async () => {
    const client = { sendRequest: vi.fn().mockRejectedValue(new Error("network")) };
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/No servers in directory/)).toBeTruthy();
    });
  });

  it("shows trusted checkmark for trusted servers", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true, name: "Trusted" })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Trusted/).textContent).toContain("✅");
    });
  });

  it("shows question mark for untrusted servers", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: false, name: "Untrusted" })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Untrusted/).textContent).toContain("❓");
    });
  });

  it("shows 'Browse works' only for trusted servers", async () => {
    const client = mkClient({
      servers: [mkServer({ trusted: true, name: "Trusted" })],
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });
  });

  it("hides 'Browse works' for untrusted servers", async () => {
    const client = mkClient({
      servers: [mkServer({ trusted: false, name: "Untrusted" })],
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Untrusted/)).toBeTruthy();
    });
    expect(screen.queryByText("Browse")).toBeNull();
  });

  it("calls server_directory_add with parsed address and port", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "alice.example.com:9090" } });
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_add", {
        address: "alice.example.com",
        port: 9090,
      });
    });
  });

  it("defaults port to 8080 when not specified", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "bob.example.com" } });
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_add", {
        address: "bob.example.com",
        port: 8080,
      });
    });
  });

  it("prepends http:// when protocol missing", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "http://carol.example.com:7070" } });
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_add", {
        address: "carol.example.com",
        port: 7070,
      });
    });
  });

  it("disables Add button when input is empty", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Add")).toBeTruthy();
    });
    const addBtn = screen.getByText("Add") as HTMLButtonElement;
    expect(addBtn.disabled).toBe(true);
  });

  it("disables Add button when loading", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "test.com" } });
    // Make sendRequest hang so loading stays true
    client.sendRequest.mockReturnValue(new Promise(() => {}));
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      const btn = screen.getByText("Add") as HTMLButtonElement;
      expect(btn.disabled).toBe(true);
    });
  });

  it("shows error message when add fails", async () => {
    const client = mkClient({ servers: [] });
    client.sendRequest
      .mockResolvedValueOnce({ servers: [] })
      .mockRejectedValueOnce(new Error("Connection refused"))
      .mockResolvedValue({ servers: [] });

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "bad.example.com" } });
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      expect(screen.getByText(/Connection refused/)).toBeTruthy();
    });
  });

  it("clears input after successful add", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/alice/)).toBeTruthy();
    });

    const input = screen.getByPlaceholderText(/alice/) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "new.example.com:8080" } });
    fireEvent.click(screen.getByText("Add"));

    await waitFor(() => {
      expect(input.value).toBe("");
    });
  });

  it("calls server_directory_set_trust with parsed server_id on trust toggle", async () => {
    const client = mkClient({ servers: [mkServer({ server_id: "aabb", trusted: false })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Trust")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Trust"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_set_trust", {
        server_id: expect.any(String),
        trusted: true,
      });
    });
  });

  it("calls server_directory_set_trust with trust=false when untrusting", async () => {
    const client = mkClient({ servers: [mkServer({ server_id: "aabb", trusted: true })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Untrust")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Untrust"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_set_trust", {
        server_id: expect.any(String),
        trusted: false,
      });
    });
  });

  it("calls server_directory_remove on remove click", async () => {
    const client = mkClient({ servers: [mkServer({ server_id: "aabb" })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Remove")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Remove"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_remove", {
        server_id: expect.any(String),
      });
    });
  });

  it("sends server_id as string for trust/remove", async () => {
    const client = mkClient({ servers: [mkServer({ server_id: "ff", trusted: false })] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Trust")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Trust"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("server_directory_set_trust", {
        server_id: "ff",
        trusted: true,
      });
    });
  });

  it("shows error when trust update fails", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: false })] });
    client.sendRequest
      .mockResolvedValueOnce({ servers: [mkServer({ trusted: false })] })
      .mockRejectedValueOnce(new Error("permission denied"))
      .mockResolvedValue({ servers: [mkServer({ trusted: false })] });

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Trust")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Trust"));

    await waitFor(() => {
      expect(screen.getByText(/Failed to update trust/)).toBeTruthy();
    });
  });

  it("shows error when remove fails", async () => {
    const client = mkClient({ servers: [mkServer()] });
    client.sendRequest
      .mockResolvedValueOnce({ servers: [mkServer()] })
      .mockRejectedValueOnce(new Error("not allowed"))
      .mockResolvedValue({ servers: [mkServer()] });

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Remove")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Remove"));

    await waitFor(() => {
      expect(screen.getByText(/Failed to remove server/)).toBeTruthy();
    });
  });

  it("refreshes list when refresh button clicked", async () => {
    const client = mkClient({ servers: [] });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByTitle("Refresh")).toBeTruthy();
    });

    const initialCalls = client.sendRequest.mock.calls.length;
    fireEvent.click(screen.getByTitle("Refresh"));

    await waitFor(() => {
      expect(client.sendRequest.mock.calls.length).toBeGreaterThan(initialCalls);
    });
    expect(client.sendRequest.mock.calls[client.sendRequest.mock.calls.length - 1][0]).toBe(
      "server_directory_list",
    );
  });

  it("renders server description when present", async () => {
    const client = mkClient({
      servers: [mkServer({ description: "My cool server" })],
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("My cool server")).toBeTruthy();
    });
  });

  it("does not render description element when absent", async () => {
    const client = mkClient({
      servers: [mkServer({ description: "" })],
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Alice/)).toBeTruthy();
    });
  });

  it("shows address:port in monospace", async () => {
    const client = mkClient({
      servers: [mkServer({ address: "alice.example.com", port: 8081 })],
    });
    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("alice.example.com:8081")).toBeTruthy();
    });
  });

  // Remote browsing tests
  it.skip("fetches remote works when Browse clicked", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [{ work_id: "42", title: "Remote Doc", revision: 3, char_count: 100 }] }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));

    await waitFor(() => {
      expect(screen.getByText("Remote Doc")).toBeTruthy();
    });
    expect(fetch).toHaveBeenCalledWith("http://alice.example.com:8081/api/public/works", expect.objectContaining({ signal: expect.any(AbortSignal) }));
  });

  it.skip("shows remote error on fetch failure", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockRejectedValue(new Error("network error"));

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));

    await waitFor(() => {
      expect(screen.getByText(/Failed to fetch works list/)).toBeTruthy();
    });
  });

  it.skip("shows remote error on non-ok response", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({ ok: false, status: 404 } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));

    await waitFor(() => {
      expect(screen.getByText(/Server returned 404/)).toBeTruthy();
    });
  });

  it.skip("shows empty state when remote has no works", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [] }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));

    await waitFor(() => {
      expect(screen.getByText(/No public works/)).toBeTruthy();
    });
  });

  it.skip("closes remote browser on close button", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [{ work_id: "1", title: "R", revision: 1, char_count: 5 }] }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("R")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("✕"));
    expect(screen.queryByText("R")).toBeNull();
  });

  it.skip("displays char count and revision for remote works", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({
        works: [{ work_id: "10", title: "Doc", revision: 7, char_count: 2500 }],
      }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));

    await waitFor(() => {
      expect(screen.getByText(/2500 chars/)).toBeTruthy();
      expect(screen.getByText(/7 revisions/)).toBeTruthy();
    });
  });

  // Remote text view tests
  it.skip("fetches and displays remote work text", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, { text: "Hello from remote", title: "Remote", origin_server_name: "Alice", license: "cc-by", tumbler: "test.42.0" }, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [{ work_id: "42", title: "Remote", revision: 1, char_count: 5 }] }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("Remote")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Remote"));
    await waitFor(() => {
      expect(screen.getByText(/Hello from remote/)).toBeTruthy();
    });
  });

  it.skip("shows work ID hint for cross-server linking", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch)
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ works: [{ work_id: "99", title: "T", revision: 1, char_count: 1 }] }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ text: "X", title: "T" }),
      } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("T")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("T"));
    await waitFor(() => {
      expect(screen.getByText(/Work ID: 99/)).toBeTruthy();
    });
  });

  it.skip("truncates remote text at 2000 chars", async () => {
    const longText = "A".repeat(3000);
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch)
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ works: [{ work_id: "1", title: "Long", revision: 1, char_count: 3000 }] }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ text: longText, title: "Long" }),
      } as Response);

    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("Long")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Long"));
    await waitFor(() => {
      expect(container.textContent).toContain("...");
    });
  });

  it.skip("shows error when remote work fetch fails", async () => {
    const client = mkClient(
      { servers: [mkServer({ trusted: true })] },
    );
    client.sendRequest = vi.fn().mockImplementation((op: string) => {
      if (op === "cross_server_fetch_work") return Promise.reject(new Error("timeout"));
      return Promise.resolve({ servers: [mkServer({ trusted: true })] });
    });
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [{ work_id: "5", title: "Err", revision: 1, char_count: 1 }] }),
    } as Response);

    render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("Err")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Err"));
    await waitFor(() => {
      expect(screen.getByText(/Failed: timeout/)).toBeTruthy();
    });
  });

  // XSS protection tests
  it("renders server name as text, not HTML (XSS protection)", async () => {
    const client = mkClient({
      servers: [mkServer({ name: '<img src=x onerror=alert(1)>' })],
    });
    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText(/onerror/)).toBeTruthy();
    });
    // The img tag should NOT be rendered as an actual element
    expect(container.querySelector("img[src=x]")).toBeNull();
  });

  it("renders server description as text, not HTML (XSS protection)", async () => {
    const client = mkClient({
      servers: [mkServer({ description: '<script>alert("xss")</script>' })],
    });
    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(container.textContent).toContain("script");
    });
    expect(container.querySelector("script")).toBeNull();
  });

  it.skip("renders remote work title as text, not HTML (XSS protection)", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, undefined, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({
        works: [{ work_id: "1", title: '<b>bold</b><script>alert(1)</script>', revision: 1, char_count: 1 }],
      }),
    } as Response);

    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(container.textContent).toContain("bold");
    });
    expect(container.querySelector("script")).toBeNull();
    expect(container.querySelector("b")).toBeNull();
  });

  it.skip("renders remote text as text, not HTML (XSS protection)", async () => {
    const client = mkClient({ servers: [mkServer({ trusted: true })] }, { text: '<script>alert("evil")</script>', title: "XSS", origin_server_name: "Alice", license: "cc-by", tumbler: "test.1.0" }, [{ work_id: "42", title: "Remote Doc", revision: 1, char_count: 100 }]);
    vi.mocked(fetch).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ works: [{ work_id: "1", title: "XSS", revision: 1, char_count: 10 }] }),
    } as Response);

    const { container } = render(
      <ServerDirectoryPanel client={client} connected={true} onNavigateToWork={vi.fn()} />,
    );
    await waitFor(() => {
      expect(screen.getByText("Browse")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("Browse"));
    await waitFor(() => {
      expect(screen.getByText("XSS")).toBeTruthy();
    });

    fireEvent.click(screen.getByText("XSS"));
    await waitFor(() => {
      expect(container.textContent).toContain("alert");
    });
    expect(container.querySelector("script")).toBeNull();
  });
});
