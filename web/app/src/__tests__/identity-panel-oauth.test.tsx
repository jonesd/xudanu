import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { IdentityPanel } from "../components/IdentityPanel";

function renderSignedOut(oauthProviders?: { github: boolean; google: boolean }) {
  return render(
    <IdentityPanel
      identity={null}
      connected={true}
      onLogin={vi.fn()}
      onCreateIdentity={vi.fn()}
      onLogout={vi.fn()}
      oauthProviders={oauthProviders}
    />,
  );
}

function openLoginForm() {
  fireEvent.click(screen.getByRole("button", { name: /sign in/i }));
}

describe("IdentityPanel OAuth buttons", () => {
  it("shows only the GitHub link when only GitHub is configured", () => {
    renderSignedOut({ github: true, google: false });
    openLoginForm();
    expect(screen.getByRole("link", { name: "GitHub" })).toBeTruthy();
    expect(screen.queryByRole("link", { name: "Google" })).toBeNull();
  });

  it("shows only the Google link when only Google is configured", () => {
    renderSignedOut({ github: false, google: true });
    openLoginForm();
    expect(screen.getByRole("link", { name: "Google" })).toBeTruthy();
    expect(screen.queryByRole("link", { name: "GitHub" })).toBeNull();
  });

  it("shows no OAuth section when nothing is configured", () => {
    renderSignedOut();
    openLoginForm();
    expect(screen.queryByRole("link", { name: "GitHub" })).toBeNull();
    expect(screen.queryByRole("link", { name: "Google" })).toBeNull();
  });

  it("links to the server OAuth routes", () => {
    renderSignedOut({ github: true, google: true });
    openLoginForm();
    expect(screen.getByRole("link", { name: "GitHub" }).getAttribute("href")).toBe("/auth/github");
    expect(screen.getByRole("link", { name: "Google" }).getAttribute("href")).toBe("/auth/google");
  });
});
