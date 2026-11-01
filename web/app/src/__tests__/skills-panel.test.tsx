import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";
import {
  SkillsPanel,
  hexWorkId,
  parseWorkHex,
  canEndorse,
  iHaveEndorsed,
} from "../components/SkillsPanel";
import type { CrdtSyncClient, SkillClaimEntry, WorkListEntry } from "../api/crdt_sync";

const MY_CLUB = 1004;
const identity = { club_id: MY_CLUB, display_name: "maya" };

const claimed: SkillClaimEntry = {
  claim: "a".repeat(64),
  subject: MY_CLUB,
  skill: "rust",
  grade: "claimed",
  summary: "systems work",
  evidence: [{ work_id: "3ee", note: "wrote the engine" }],
  endorsements: 0,
  endorsers: [],
  created_at: 1774000000,
};

const peerVerified: SkillClaimEntry = {
  claim: "b".repeat(64),
  subject: 1005,
  skill: "rust",
  grade: "verified",
  summary: "",
  evidence: [{ work_id: "3ef", note: "" }],
  endorsements: 2,
  endorsers: [MY_CLUB, 1006],
  created_at: 1774000001,
};

const works: WorkListEntry[] = [
  {
    work_id: 0x3ee,
    owner: null,
    revision_count: 1,
    is_grabbed: false,
    title: "Pipeline notes",
    read_club: null,
  },
];

const peerClaimed: SkillClaimEntry = {
  claim: "c".repeat(64),
  subject: 1005,
  skill: "rust",
  grade: "claimed",
  summary: "",
  evidence: [{ work_id: "3ef", note: "" }],
  endorsements: 0,
  endorsers: [],
  created_at: 1774000002,
};

function makeClient(claims: SkillClaimEntry[]) {
  return {
    skillListByClub: vi.fn().mockResolvedValue({ club: MY_CLUB, claims }),
    skillListBySkill: vi.fn().mockResolvedValue({ skill: "rust", claims }),
    skillClaimSubmit: vi.fn().mockResolvedValue(claimed),
    skillEndorse: vi.fn().mockResolvedValue(peerVerified),
    skillUnendorse: vi.fn().mockResolvedValue(claimed),
  } as unknown as CrdtSyncClient;
}

describe("SkillsPanel helpers", () => {
  it("hex/parsing round-trips", () => {
    expect(hexWorkId(1006)).toBe("3ee");
    expect(parseWorkHex("3ee")).toBe(1006);
    expect(parseWorkHex("nothex")).toBeNull();
  });

  it("two-person rule: your own claim is not endorsable", () => {
    expect(canEndorse(claimed, MY_CLUB)).toBe(false);
    expect(canEndorse(peerVerified, MY_CLUB)).toBe(true);
    expect(canEndorse(claimed, null)).toBe(false);
  });

  it("tracks whether I already endorsed", () => {
    expect(iHaveEndorsed(peerVerified, MY_CLUB)).toBe(true);
    expect(iHaveEndorsed(claimed, MY_CLUB)).toBe(false);
  });
});

describe("SkillsPanel", () => {
  it("renders my claims with grade badges and endorsement counts", async () => {
    render(
      <SkillsPanel
        client={makeClient([claimed, peerVerified])}
        identity={identity}
        currentWorkId={0x3ee}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    expect((await screen.findAllByText("rust")).length).toBe(2);
    expect(screen.getByText("claimed")).toBeInTheDocument();
    expect(screen.getByText("verified")).toBeInTheDocument();
    expect(screen.getByText(/no endorsements yet/)).toBeInTheDocument();
    expect(screen.getByText(/2 endorsements: club 1004, club 1006/)).toBeInTheDocument();
  });

  it("own claims show 'your claim', not an endorse button", async () => {
    render(
      <SkillsPanel
        client={makeClient([claimed])}
        identity={identity}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    expect(await screen.findByText("your claim")).toBeInTheDocument();
    expect(screen.queryByText("Endorse")).not.toBeInTheDocument();
  });

  it("endorsing a peer claim calls skill_endorse and refreshes", async () => {
    const user = userEvent.setup();
    const client = makeClient([peerClaimed]);
    render(
      <SkillsPanel
        client={client}
        identity={identity}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    await user.click(await screen.findByText("Endorse"));
    await waitFor(() =>
      expect(client.skillEndorse).toHaveBeenCalledWith(peerClaimed.claim),
    );
    // refresh after the mutation: the list is re-fetched.
    await waitFor(() => expect(client.skillListByClub).toHaveBeenCalledTimes(2));
  });

  it("retract replaces endorse once I have endorsed", async () => {
    render(
      <SkillsPanel
        client={makeClient([peerVerified])}
        identity={identity}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    expect(await screen.findByText("Retract endorsement")).toBeInTheDocument();
    expect(screen.queryByText("Endorse")).not.toBeInTheDocument();
  });

  it("clicking retract calls skill_unendorse", async () => {
    const user = userEvent.setup();
    const client = makeClient([peerVerified]);
    render(
      <SkillsPanel
        client={client}
        identity={identity}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    await user.click(await screen.findByText("Retract endorsement"));
    await waitFor(() =>
      expect(client.skillUnendorse).toHaveBeenCalledWith(peerVerified.claim),
    );
  });

  it("search by skill works without an identity and lists claims", async () => {
    const user = userEvent.setup();
    const client = makeClient([peerVerified]);
    render(
      <SkillsPanel
        client={client}
        identity={null}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    await user.click(screen.getByText("Find by skill"));
    await user.type(screen.getByPlaceholderText(/skill tag/), "RUST");
    await user.click(screen.getByText("Search"));
    expect(await screen.findByText(/1 claim for "rust"/)).toBeInTheDocument();
    expect(client.skillListBySkill).toHaveBeenCalledWith("RUST");
  });

  it("evidence chips resolve titles and open the work", async () => {
    const user = userEvent.setup();
    const onSelectWork = vi.fn();
    render(
      <SkillsPanel
        client={makeClient([claimed])}
        identity={identity}
        currentWorkId={0x3ee}
        works={works}
        onSelectWork={onSelectWork}
      />,
    );
    const chip = await screen.findByText("0x3ee Pipeline notes");
    await user.click(chip);
    expect(onSelectWork).toHaveBeenCalledWith(0x3ee);
  });

  it("submitting a claim cites the open work as evidence", async () => {
    const user = userEvent.setup();
    const client = makeClient([]);
    render(
      <SkillsPanel
        client={client}
        identity={identity}
        currentWorkId={0x3ee}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    await user.click(await screen.findByText("Claim a skill"));
    await user.type(screen.getByPlaceholderText(/skill \(e\.g\./), "Rust");
    await user.type(screen.getByPlaceholderText(/summary \(optional/), "systems work");
    await user.type(
      screen.getByPlaceholderText(/what about the evidence/),
      "wrote the engine",
    );
    await user.click(screen.getByText("Submit claim"));
    await waitFor(() => expect(client.skillClaimSubmit).toHaveBeenCalled());
    expect(client.skillClaimSubmit).toHaveBeenCalledWith(
      MY_CLUB,
      "Rust",
      "systems work",
      [{ work_id: "3ee", note: "wrote the engine" }],
    );
  });

  it("submit is disabled with no work open to cite", async () => {
    const user = userEvent.setup();
    render(
      <SkillsPanel
        client={makeClient([])}
        identity={identity}
        currentWorkId={null}
        works={works}
        onSelectWork={() => {}}
      />,
    );
    await user.click(await screen.findByText("Claim a skill"));
    await user.type(screen.getByPlaceholderText(/skill \(e\.g\./), "Rust");
    expect(screen.getByText("Submit claim")).toBeDisabled();
  });
});
