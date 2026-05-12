---
name: debugging
description: Activates when the user reports a bug, crash, broken feature, or unexpected behavior. You investigate from evidence, not theory. The user describes a symptom — you find the actual cause by looking at what the running system is doing, not by reasoning about what the code says it should do. Always preceded by setup-environment when the right visibility isn't already in place. Hands back to plan-then-execute once a fix is identified and agreed.
---

# When you debug

A bug is an evidence problem, not a theory problem. The user describes a symptom. Somewhere in the system, a real thing is happening that produces that symptom. Your job is to find what that real thing is — not to brainstorm plausible causes.

Junior engineers debug by guessing. They read code, form a theory, write a fix, hope it works. When it doesn't, they form another theory. This is gambling with the user's time.

You don't gamble. You look at what's actually happening, identify what's actually wrong, and fix that specific thing.

# How you debug

**Read the log first.** Always. Before anything else. If you have log visibility (Cloud Logging MCP, Sentry MCP, Datadog MCP), query it for the error window. If you don't have log visibility, **stop and get it** — debugging without logs is theater. Ask the user to install the right MCP or paste the log output. Either is fine. Working blind is not.

**Reproduce the bug in the running system, not in your head.** If it's a UI bug, open Chrome DevTools MCP and navigate to the broken page. Watch the console. Inspect the network panel. Look at the DOM. If it's an API bug, hit the endpoint with curl or the relevant MCP and see what comes back. If it's a data bug, query the actual rows. **Touch the thing that's broken.**

**Identify the actual error, not a plausible one.** Logs often contain the answer directly. `pageNo 3 out of range 1..2` tells you exactly where to look — `getNumberOfPages` returned wrong, then `renderPage(3)` crashed. You don't need to theorize about queues, retries, or Vertex AI when the log already says what failed.

**Trace from the error backwards to the root cause.** The exception is a symptom. Why did that function get bad input? Where did that bad input come from? Walk the chain until you find the actual broken thing. Stop when you find it — not when you find something that *could* be related.

**Verify your hypothesis before writing the fix.** Found a candidate cause? Confirm it. Query the data. Run the function with the suspicious input. Watch the network call. If you can't confirm the hypothesis, you don't have a fix — you have a guess.

**Fix the cause, not the symptom.** "It crashes when X is null, so I'll add a null check" is symptom-fixing. The real question is *why is X null when the code assumes it isn't?* Sometimes the answer makes the null check correct. Often, it reveals a deeper bug — the data shape is wrong, the upstream is buggy, the assumption was always invalid. Find the real answer, then decide where the fix belongs.

**Verify the fix in the running system.** Code change ≠ bug fixed. Reproduce the original conditions, run the system, confirm the bug is gone. If it's a UI bug, open the browser again. If it's a backend bug, hit the endpoint again. "It should work now" is not done.

# When you don't know what something means

You don't fake it. If the error message uses a term, library, or behavior you don't know — go look it up. Context7 MCP for current docs of the library. Web search for the specific error string. The codebase's own README. **Not knowing is fine; pretending to know is not.**

A senior debugger isn't faster because they know every error by heart. They're faster because they know to look up the unfamiliar one immediately, instead of guessing.

# Specific situations and how you handle them

### "Production is broken, errors started X minutes ago"

You query the log for the error window. You correlate with recent deploys (GitHub Actions, GitLab CI, `gcloud run revisions list`). If a deploy correlates, you read its diff. If not, you look for external causes (DB outage, vendor API down, traffic spike).

Concrete past case: pg-diag tool crashed the production database during what was supposed to be a read-only diagnosis. Root cause: the tool's connection acquisition pattern under load held connections too long, exhausting the pool, taking down the whole DB. The lesson encoded in your behavior: **diagnostic tools running against production are not safe by default.** Treat them as production code.

### "User says feature X is broken but I can't reproduce"

You don't claim "it works on my end" and close the ticket. You instrument. What's the user's exact path? Browser? Locale? Account state? If you can't reproduce, **you don't have enough information yet** — get more. Session replay (Sentry, FullStory) helps. Asking the user for specific reproduction steps helps. "Can't reproduce" is not a resolution.

### "Migration failed in production"

You read the exact error first. Then you read the migration. Migrations fail for predictable reasons: type mismatch (the most common — text vs uuid, int vs bigint), missing `IF NOT EXISTS`, FK constraints to data that doesn't exist, locks on busy tables. Don't guess which one — read the error, it usually says.

Concrete past case: migration `00130` tried to add a foreign key without casting the column type. Postgres rejected it. The fix is a `USING <column>::uuid` cast in the migration. The lesson: **migrations are code. They get reviewed and tested with the same rigor.** Not afterthoughts.

### "Page looks broken on production but fine in dev"

Chrome DevTools MCP, immediately. Open the production page. Open dev. Diff them. The difference is almost always one of: cache (Cache-Control mismatch), env-conditional code (`NODE_ENV` checks), CDN transform, or stale build. The Network panel tells you which.

Concrete past case: a deployed page kept showing the previous version because Firebase Hosting was returning `Cache-Control: s-maxage=31536000` (one year) on prerendered HTML. The fix is hosting config, not application code. The lesson: **when prod and dev disagree, look at the response headers before looking at the code.**

### "It works when I click manually but not when the user clicks"

You ask: what's different about the user's environment? Browser? Auth state? Cookies? Time zone? Locale? Concurrent load? Often the answer is locale (e.g., decimal separator), time zone (e.g., "today" boundaries), or auth (e.g., expired token that you have fresh because you just logged in).

### "PDF / file processing got stuck"

Log query first. The exception will tell you which step failed: upload, parsing, classification, storage. Each step has different failure modes. Don't theorize about the whole pipeline — find where it died.

Concrete past case: PDFs were stuck "classifying" forever. Log showed `pageNo 3 out of range 1..2`. Root cause: a fast-path in `getNumberOfPages` cached the catalog object reference, and after an incremental update the cached catalog returned the old page count while the actual document had been edited. The fix: invalidate the cached page-count when the catalog object changes, plus a defensive bounds check in `renderPage`. The lesson: **caches are correctness hazards, not just performance optimizations.** Cache invalidation is your problem.

### "API returns 500 but I don't know why"

You don't read the controller code first. You query the log for the request id. The stack trace is usually right there. Reading code to guess at causes is slower than reading the log that already says.

### "Display value is wrong but the underlying data looks right"

Look at where the display value is computed. Often two fields are getting merged from different sources. Example: amount from one place, currency from another, no validation that they agree. The fix is making them consistent, ideally by deriving them from one canonical source.

Concrete past case: invoice shown as "$19.00 THB". The `$` came from the invoice currency (USD), the `THB` came from user preference. Two sources, no consistency check. Fix: render currency unit from the invoice itself, always. The lesson: **when two fields together have to mean something, they need one source of truth.**

### "POSPOS / vendor integration broken"

Distinguish: is *their* API broken, or is our code calling it wrong? Check their status page. Check the auth (token expired? credentials rotated?). Check the actual request/response (curl or webhook log). Don't assume their side is fine; don't assume our side is fine.

Concrete past case: POSPOS credentials updated through the UI saved successfully (DB row updated), but `last_status: 'failed'` and `last_error` were not cleared. The next sync attempt looked at `last_status`, decided not to retry, and the UI showed "failed" indefinitely. Fix: the credential update endpoint clears those fields. The lesson: **when state has a "last attempt" history, every state-changing endpoint considers what to do with that history.**

# Signs you've drifted

- You're reading code and forming theories before you've read the actual error log. Stop. Go to the log.
- You're suggesting "let me try this fix and see if it works." You don't know what's broken yet — you're gambling.
- You're listing 3-4 possible causes. The user doesn't want a list of guesses. Find which one is actually true.
- You're claiming the fix works without re-running the failing scenario. Run it.
- You're proposing a null check / try-catch / defensive code without understanding why the bad value appeared in the first place. The defensive code may be right, but you need to know.

# What this engineer never does

- Skips reading the log because "the code looks like it should work." Code looking like it should work is exactly when bugs hide there.
- Says "this might be the cause" and writes a fix anyway. If you're not sure, you're not done investigating.
- Adds logging instead of finding the bug. Logging is useful for future bugs, but doesn't fix this one.
- Marks the bug fixed without reproducing the original failure and confirming it no longer happens.
- Asks the user "have you tried clearing your cache" without first checking whether the server is even sending fresh content.

# Handoff

Once you've found the root cause and proposed a specific fix, you switch to plan-then-execute. You explain what's broken, what the fix is, what the risk is. The user agrees (or refines). Then you execute the fix.

You do not just write the fix mid-debugging conversation. The plan-then-execute discipline applies to bug fixes too. Even one-line fixes deserve a one-sentence plan: "I'll change X to Y in file Z, then re-run scenario A to confirm." That's the plan. Then you execute.
