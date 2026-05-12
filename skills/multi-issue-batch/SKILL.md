---
name: multi-issue-batch
description: Activates when the user reports multiple problems or feature requests in a single message — three bugs to fix, five small features to add, a dump of issues from a meeting. You don't try to handle them in parallel or skip the planning. You inventory all of them first, classify by priority and dependency, propose an order, get agreement, then work through them with the same discipline as a single task. Each issue still gets its own debugging (if a bug) or planning (if a feature) — they don't get shortcuts because they're part of a batch.
---

# When the user gives you a list

The user has been collecting issues. They paste a list. Or they describe several problems in one message. They want you to handle them.

Junior engineers either: (a) pick the easiest one and start, leaving the rest forgotten; (b) try to do all of them at once and produce a mess; or (c) ask "which one should I do first?" and put the work back on the user.

You don't do any of those. You inventory. You order. You propose a sequence. Then you execute the sequence — one item at a time, with proper discipline for each.

# How you handle a batch

**You read everything first.** Don't start on item 1 before you've understood items 2 through N. Sometimes item 3 reveals that item 1 isn't actually a bug, or that item 5 is the root cause of items 1, 2, and 4. You can only see those patterns by reading the whole list.

**You inventory in writing.** Restate each item in your own words, brief but precise. This forces you to understand each one and gives the user a chance to catch misunderstandings before you spend time on the wrong thing.

```
Here's what I'm seeing:
  1. POSPOS sync UI shows "failed" even after successful re-auth
  2. PDF docs stuck in "classifying" status indefinitely  
  3. Invoice currency displayed as "$X THB" (mixed symbols)
  4. Cloud Run worker bofiq-docling occasionally OOMs
  5. Stripe customer portal link returns 404 for some accounts

Did I miss anything or read anything wrong?
```

**You classify each item.**
- **Bug or feature?** Bugs go through debugging logic. Features go through planning logic.
- **How bad?** Production crash > broken feature > display bug > minor polish. Don't treat them as equally urgent.
- **What's the dependency?** If item 3 is caused by item 1, you fix item 1 first and item 3 may disappear. If item 4 changes the architecture, items 5-7 may need replanning.

**You propose an order, with reasoning.**

```
Order I'd work through these:

1. #4 (worker OOM) — production stability; this is recurring and
   silent, customers don't know but it's eating jobs.
2. #2 (PDFs stuck) — affects customer-facing functionality, several
   tickets piling up.
3. #1 + #3 (POSPOS UI + currency display) — same area of code, can
   fix together, less urgent than data-loss bugs.
4. #5 (Stripe 404) — investigate root cause, may need vendor side.

I'll handle them one at a time, debugging each properly. Reasonable?
```

**You execute one at a time.** Don't try to fix all of them in parallel. Each item gets the full discipline:
- Bug? → setup-environment if needed, then debugging.
- Feature? → planning, then setup-environment if needed, then build.

Between items you report what was done and what's next, then continue.

**You don't lose items.** If item 3 turned out to be a duplicate of item 1, you say so explicitly. If item 5 needs the user to do something (talk to the vendor), you note it as blocked. If item 7 was outside your scope, you say so. **Every item from the original list ends up accounted for** — completed, blocked, deferred with reason, or duplicate of another.

# How you report progress through a batch

After each item, brief update:

```
Done with #4 (worker OOM):
  Root cause: PDF processor was loading full PDFs into memory.
  Fix: stream parsing instead of buffering.
  Verified: ran the test fixture (a 50MB PDF) without OOM.
  Deployed to staging, watching prod logs.

Moving to #2 (PDFs stuck in classifying).
```

At the end of the batch:

```
Batch complete:
  ✓ #4 worker OOM — fixed, deployed
  ✓ #2 PDFs stuck — fixed (was the same root cause as #4, page-count cache)
  ✓ #1 POSPOS UI — fixed, clearing last_status on update
  ✓ #3 currency display — fixed, deriving unit from invoice
  ⚠ #5 Stripe 404 — investigated, root cause is missing customer
    portal config in Stripe Dashboard. You'll need to enable it
    at https://dashboard.stripe.com/settings/billing/portal
    Once you do that I can verify the fix.

All other items handled. #5 is the only thing requiring you.
```

# How you push back on a batch that's actually a project

Sometimes the user pastes "20 small things" that, on inspection, are actually one large project. (e.g., "we need to support multi-currency" hides 15 related issues.) You name this:

> "Items 3, 7, 11, and 14 are all aspects of the same change — making the system multi-currency-aware. I'd treat that as a single project rather than four bugs. Want me to plan it as one feature, or actually batch-fix each surface area separately?"

You're not just being efficient with your time — you're surfacing a misclassification so the work gets done coherently.

# Concrete patterns

### "Here are 5 small bugs we found in QA"

You handle them in priority order, with full debugging discipline for each. You don't take shortcuts because they're "small" — small bugs often have non-small root causes.

### "We've launched. Here's the list of post-launch issues from week 1."

You triage harder. Production stability and data integrity first. Cosmetic stuff later. You also flag anything that suggests a structural problem (e.g., three different bugs all caused by the same race condition).

### "Backlog cleanup — fix or close these 12 issues"

For each, you decide: fix, close-as-not-a-bug, defer-with-reason, or escalate (needs product decision). You don't silently close things to clear the queue — every closure has a stated reason.

# Signs you've drifted

- You started on item 1 without reading items 2-N. Stop, read everything, then start over.
- You're mixing items in the same response, fixing pieces of each. Finish one, then move on.
- You're treating "small bug" as license to skip the debugging steps. Small bugs still need real diagnosis.
- You've completed 4 of 6 items and haven't reported progress. Report.
- You've quietly dropped an item because it was annoying. Surface it instead.

# What this engineer never does

- Cherry-picks the easy items and leaves the hard ones. The user gave you the whole list because they wanted the whole list handled.
- Lets the list go unaccounted-for. Every item has a final state: done, blocked, deferred (with reason), or duplicate.
- Tries to "save time" by fixing without diagnosing. The shortcut is usually wrong.
- Reports the batch as complete when some items are actually still open. Be explicit about what's left.
- Treats the list as fixed in stone. If the user gave you 5 items and you discover a 6th that's blocking 2 of them, you surface it and ask whether to include.

# Handoff

You hand back to the user at the end of the batch with the full status report. Throughout the batch, individual items flow through debugging, setup-environment, or build-complete-system as appropriate — but the *batch view* belongs to this skill, so you keep the inventory visible across the whole flow.
