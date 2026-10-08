import { describe, expect, test } from "vitest";
import { Doc, Id } from "./_generated/dataModel";
import { oneSignalTags } from "./recovery";

function user(fields: Partial<Doc<"users">>): Doc<"users"> {
  return { _id: "u1" as Id<"users">, _creationTime: 0, email: "a@b.co", ...fields } as Doc<"users">;
}

describe("oneSignalTags", () => {
  test("eligible after consent, before any purchase", () => {
    const tags = oneSignalTags(user({ recovery: { step: "complete", paywallSeenAt: 1_700_000_000_000, goal: "sleep", offersOptIn: true, updatedAt: 1 } }));
    expect(tags.email_recovery_eligible).toBe("true");
    expect(tags.recovery_segment).toBe("B");
    expect(tags.paywall_seen_at).toBe("1700000000");
    expect(tags.selected_goal).toBe("sleep better");
    expect(tags.main_symptom).toBe("poor sleep");
  });

  test("never eligible without consent, when subscribed, in the holdout or without email", () => {
    const base = { step: "loading", goal: "focus", offersOptIn: true, updatedAt: 1 };
    expect(oneSignalTags(user({ recovery: { ...base, offersOptIn: false } })).email_recovery_eligible).toBe("false");
    expect(oneSignalTags(user({ recovery: base, subscription: { isPaid: true, updatedAt: 1 } })).email_recovery_eligible).toBe("false");
    expect(oneSignalTags(user({ recovery: { ...base, holdout: true } })).email_recovery_eligible).toBe("false");
    expect(oneSignalTags(user({ recovery: base, email: undefined })).email_recovery_eligible).toBe("false");
    expect(oneSignalTags(user({ recovery: base, onboardingCompleted: true })).email_recovery_eligible).toBe("false");
  });

  test("segments follow the onboarding step and fall back to stress copy", () => {
    expect(oneSignalTags(user({ recovery: { step: "habitsQuiz", updatedAt: 1 } })).recovery_segment).toBe("A1");
    const planReady = oneSignalTags(user({ recovery: { step: "weekProgress", updatedAt: 1 } }));
    expect(planReady.recovery_segment).toBe("A2");
    expect(planReady.selected_goal).toBe("feel calmer");
  });
});
