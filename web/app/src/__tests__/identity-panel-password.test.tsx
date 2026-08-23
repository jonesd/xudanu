import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { IdentityPanel } from "../components/IdentityPanel";
import type { WhoAmIEntry } from "../api/crdt_sync";

const identity: WhoAmIEntry = {
  club_id: 1021,
  display_name: "Test User",
  verifying_key: "aa" + "bb".repeat(31),
  clubs: [[1021, "Test User"]],
};

function renderSignedIn(onChangePassword?: (cur: string, next: string) => Promise<void>) {
  return render(
    <IdentityPanel
      identity={identity}
      connected={true}
      onLogin={vi.fn()}
      onCreateIdentity={vi.fn()}
      onChangePassword={onChangePassword ?? vi.fn()}
      onLogout={vi.fn()}
    />,
  );
}

describe("IdentityPanel change password", () => {
  it("shows the change-password button when signed in and handler provided", () => {
    renderSignedIn();
    expect(screen.getByRole("button", { name: /change password/i })).toBeTruthy();
  });

  it("hides the button when no handler is wired", () => {
    render(
      <IdentityPanel
        identity={identity}
        connected={true}
        onLogin={vi.fn()}
        onCreateIdentity={vi.fn()}
        onLogout={vi.fn()}
      />,
    );
    expect(screen.queryByRole("button", { name: /change password/i })).toBeNull();
  });

  it("validates the new password before calling the handler", async () => {
    const onChange = vi.fn().mockResolvedValue(undefined);
    renderSignedIn(onChange);
    fireEvent.click(screen.getByRole("button", { name: /change password/i }));
    fireEvent.change(screen.getByPlaceholderText("Current password"), { target: { value: "oldpassword1A" } });
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "short" } });
    fireEvent.click(screen.getByRole("button", { name: "Update" }));
    await waitFor(() => {
      expect(screen.getByText(/at least 10 characters/i)).toBeTruthy();
    });
    expect(onChange).not.toHaveBeenCalled();
  });

  it("submits current and new password on success", async () => {
    const onChange = vi.fn().mockResolvedValue(undefined);
    renderSignedIn(onChange);
    fireEvent.click(screen.getByRole("button", { name: /change password/i }));
    fireEvent.change(screen.getByPlaceholderText("Current password"), { target: { value: "oldpassword1A" } });
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "NewPassword1!" } });
    fireEvent.click(screen.getByRole("button", { name: "Update" }));
    await waitFor(() => {
      expect(onChange).toHaveBeenCalledWith("oldpassword1A", "NewPassword1!");
    });
    await waitFor(() => {
      expect(screen.getByText(/password updated/i)).toBeTruthy();
    });
  });

  it("maps wrong-current-password failures to a friendly message", async () => {
    const onChange = vi.fn().mockRejectedValue(new Error("lock failed: match lock"));
    renderSignedIn(onChange);
    fireEvent.click(screen.getByRole("button", { name: /change password/i }));
    fireEvent.change(screen.getByPlaceholderText("Current password"), { target: { value: "wrongpassword" } });
    fireEvent.change(screen.getByPlaceholderText("New password"), { target: { value: "NewPassword1!" } });
    fireEvent.click(screen.getByRole("button", { name: "Update" }));
    await waitFor(() => {
      expect(screen.getByText(/current password is incorrect/i)).toBeTruthy();
    });
  });
});
