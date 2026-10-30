import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { AdminDashboard } from "../components/AdminDashboard";

// FR-156: the license posture panel is a MIRROR, not a switch. These
// tests pin that from the UI side: both opt-in states render
// (absence is information too), the footer says where changes really
// happen — and no control ever appears that could change an opt-in
// from this screen.

const POSTURE = {
  entries: [
    {
      id: "heif",
      name: "HEIF/HEIC image decode",
      license: "LGPL-3.0-or-later (libheif C library; MIT libheif-rs bindings)",
      blast_radius: "Decodes .heif/.heic camera photos for image previews.",
      terms_url: "https://www.gnu.org/licenses/lgpl-3.0.html",
      source: "build_feature",
      feature: "heif",
      state: "available",
    },
    {
      id: "translate-nllb",
      name: "NLLB translation engine",
      license: "CC-BY-NC-4.0 (model weights)",
      blast_radius: "Machine translation of document spans.",
      terms_url: "https://creativecommons.org/licenses/by-nc/4.0/",
      source: "runtime_config",
      feature: null,
      state: "enabled",
    },
  ],
};

function mkClient(posture: unknown = POSTURE, reject = false) {
  return {
    sendRequest: vi.fn().mockImplementation((op: string) => {
      if (op === "admin_license_posture") {
        return reject ? Promise.reject(new Error("not admin")) : Promise.resolve(posture);
      }
      return Promise.resolve({});
    }),
  } as any;
}

function renderDashboard(client: any) {
  return render(
    <AdminDashboard
      onClose={vi.fn()}
      client={client}
      isAdmin={true}
      works={[]}
      onNavigateToWork={vi.fn()}
    />,
  );
}

const openLicenseTab = () =>
  fireEvent.click(screen.getByRole("button", { name: "License" }));

describe("AdminDashboard — License tab (FR-156)", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ status: "ok" }),
      }),
    );
  });
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("loads posture when the License tab is entered", async () => {
    const client = mkClient();
    renderDashboard(client);
    openLicenseTab();
    await waitFor(() =>
      expect(client.sendRequest).toHaveBeenCalledWith("admin_license_posture"),
    );
  });

  it("renders BOTH states: enabled and available-not-chosen", async () => {
    renderDashboard(mkClient());
    openLicenseTab();
    await waitFor(() =>
      expect(screen.getByText("HEIF/HEIC image decode")).toBeTruthy(),
    );
    // Absence is information too: the declined opt-in is listed, not hidden.
    expect(screen.getByText("available · not chosen")).toBeTruthy();
    expect(screen.getByText("enabled")).toBeTruthy();
    expect(screen.getByText("1 opted in · 1 available, not chosen")).toBeTruthy();
  });

  it("renders the mirror-not-switch footer and terms links", async () => {
    renderDashboard(mkClient());
    openLicenseTab();
    await waitFor(() =>
      expect(screen.getByText("HEIF/HEIC image decode")).toBeTruthy(),
    );
    expect(screen.getByText("mirror, not a switch")).toBeTruthy();
    const terms = screen.getAllByRole("link", { name: "terms" });
    expect(terms).toHaveLength(2);
    expect(terms[0].getAttribute("href")).toBe(
      "https://www.gnu.org/licenses/lgpl-3.0.html",
    );
  });

  // The design principle as a regression test: the panel CONFIRMS
  // choices, it never makes them. If someone later adds a toggle
  // here, this fails — and that is the point. Refresh (a read) is
  // the only action the panel may offer.
  it("renders NO control that could change an opt-in", async () => {
    renderDashboard(mkClient());
    openLicenseTab();
    await waitFor(() =>
      expect(screen.getByText("HEIF/HEIC image decode")).toBeTruthy(),
    );
    for (const name of [/enable/i, /disable/i, /toggle/i, /opt in/i, /activate/i, /turn on/i, /choose/i]) {
      expect(screen.queryByRole("button", { name })).toBeNull();
    }
    expect(screen.queryByRole("checkbox")).toBeNull();
    expect(screen.queryByRole("switch")).toBeNull();
    // Refresh (a read) is the only action the panel offers. (The
    // overview tab stays mounted with display:none, hence >=1.)
    expect(screen.getAllByRole("button", { name: "Refresh" }).length).toBeGreaterThanOrEqual(1);
  });

  it("shows the admin sign-in message when the server refuses", async () => {
    renderDashboard(mkClient(undefined, true));
    openLicenseTab();
    await waitFor(() =>
      expect(
        screen.getByText("Could not load license posture (admin sign-in required)"),
      ).toBeTruthy(),
    );
  });
});
