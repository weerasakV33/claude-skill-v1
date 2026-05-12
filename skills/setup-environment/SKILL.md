---
name: setup-environment
description: Activates after planning (techs/tools chosen) but before any code is written. You set up the development environment appropriate to the planned work — opening every tab you need to see the system while you work. This is not a checklist; it is what you do because you cannot work blind. Covers the visibility surfaces relevant to the task: source, runtime, data, browser, external services, build/deploy, knowledge, test, cost, security. Replaces the older environment-setup that only covered local dev. Triggers after greenfield-project planning, after debugging hypothesis-forming when more visibility is needed, and as the first step of any production work.
---

# When you set up your environment

A senior engineer doesn't write code blind. Before the first keystroke, they have already opened every tab they need to see the system: the repo, the logs, the live browser, the database, the deploy dashboard, the issue tracker. They can answer any question about the state of the system in seconds because they're already looking at it.

That's not optional discipline. It's what separates seniors from juniors. **You see everything always. You know what to do at all times.** Skipping this step means writing fiction — code that assumes facts you didn't verify. That's how juniors ship "fixes" that don't fix anything.

You don't need to memorize every MCP command, every CLI flag, every config option. You need to know **which reference to reach for given what you're trying to see.** That's what this skill is — a map of references organized by what you need to look at.

# The visibility surfaces and where to look

Every task touches some subset of these. You don't open all of them every time — you open the ones this task actually needs. But you don't *skip* a surface without thinking about whether it matters.

**Source — to see the code as it really is**
When you need to: read the file, find who changed it, search for callers, see open PRs.
Where to look: GitHub MCP for repo-level operations, Filesystem MCP for local files, `git log`/`git blame` for history, ripgrep for fast text search.

**Runtime — to see what's actually running**
When you need to: read logs, check service status, watch a worker, inspect a container.
Where to look: local dev server in a background shell (output streams natively to you), production logs via Cloud Logging MCP / Sentry MCP / Datadog MCP, Docker MCP for containers, `gcloud run services` / `kubectl get pods` for service status.

**Data — to see the actual data, not your assumption of it**
When you need to: check the schema, see a sample row, verify migration state, inspect the cache.
Where to look: Postgres MCP / Supabase MCP (use read-only mode against prod), database client for ad-hoc queries, Redis MCP for cache, queue admin UIs for queue state.

**Browser — to see what the user sees**
When you need to: check the DOM, inspect network calls, read console errors, see Cache-Control headers, measure performance.
Where to look: **Chrome DevTools MCP** for live browser inspection (the single highest-leverage MCP for UI work), Playwright MCP for scripted flows.

**External services — to see things you don't control**
When you need to: check vendor status, verify webhook delivery, inspect OAuth tokens, look at rate limits.
Where to look: Stripe MCP / Auth0 / vendor-specific MCPs where they exist, vendor status pages, curl/httpie for ad-hoc API checks, webhook log tools (Stripe Dashboard, Svix, ngrok inspect).

**Build/deploy — to see the pipeline state**
When you need to: check CI status, find the deployed revision, read a failed build log.
Where to look: GitHub MCP for Actions logs, stack-specific CLI (`gcloud`, `vercel`, `flyctl`).

**Knowledge — to see the current truth**
When you need to: check current API of a library, look up an option, read a spec, find a past decision.
Where to look: **Context7 MCP** for live version-specific docs (don't trust your training data for current APIs), issue tracker MCPs (Linear, Jira, Notion), the project's own docs folder.

**Test — to see what's covered**
When you need to: confirm a green baseline, run the test suite, check coverage on code you're changing.
Where to look: local test runner (`npm test`, `pytest`, `go test`), CI test reports.

**Cost / scale — to see what this costs**
When you need to: estimate impact of a change on the cloud bill or LLM token usage.
Where to look: cloud billing dashboards (GCP Billing, AWS Cost Explorer), LLM provider consoles, per-query cost calculators.

**Security — to see the attack surface**
When you need to: check for dependency vulnerabilities, scan for secrets, audit IAM.
Where to look: `npm audit` / `pip-audit`, `git secrets` / `trufflehog`, IAM consoles.

# Stack-specific recommendations

You don't ask the user what they want installed. You recommend based on the stack already chosen in planning, then verify and report.

**GCP stack** (Cloud Run + Cloud SQL + Firebase + Cloud Logging):
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
claude mcp add context7 -- npx -y @upstash/context7-mcp
claude mcp add gcp-observability -- npx -y @google-cloud/observability-mcp
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres <read-only-conn-string>
claude mcp add sentry -- npx -y @sentry/mcp-server@latest
```

**Vercel + Supabase**:
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
claude mcp add context7 -- npx -y @upstash/context7-mcp
claude mcp add supabase -- npx -y @supabase/mcp-server-supabase
claude mcp add sentry -- npx -y @sentry/mcp-server@latest
```

**AWS** (Lambda + RDS + CloudWatch):
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
claude mcp add context7 -- npx -y @upstash/context7-mcp
# AWS official MCP servers — check https://github.com/awslabs for current ones
claude mcp add sentry -- npx -y @sentry/mcp-server@latest
```

**Always-add baseline (any stack):** GitHub, Chrome DevTools, Context7. These are universal.

# Verifying you can actually see

Configuring an MCP isn't the same as it working. Before you proceed to code, you do one read per critical surface:

- GitHub MCP — list issues in the target repo, or list files
- Cloud Logging — query the last few ERROR entries for the affected service
- Postgres — `SELECT count(*) FROM <known-table>`
- Chrome DevTools — navigate to localhost or staging, get the page title
- Context7 — fetch one current doc page for the framework in use

If a read fails (401, connection refused, empty results when there should be data), you surface it. You don't silently degrade to "I'll figure it out without that surface" — you say what's not working and ask the user to fix it or give you another way to see.

# How this plays out in real situations

These are concrete cases. They show the difference between working with full visibility and without.

### "หน้านี้มันชอบหายจังวะ" — page disappearing after deploys

Without visibility: an hour of theorizing about whether the deploy went through, whether the route changed, whether Firebase is caching weirdly. Each theory needs a separate test.

With Chrome DevTools MCP: open the page, look at the Network panel, see `Cache-Control: public, s-maxage=31536000` (one year) on the HTML. Five seconds to diagnose. Fix is the rewrite rule, not the deploy.

The lesson isn't "Cache-Control bugs are common." It's that **you cannot diagnose what you cannot see.** When the user reports a UI bug, the first move is opening the live browser, not reasoning about the code.

### "เอกสาร drop แล้วไม่ผ่านซักที" — PDFs stuck in classifying

Without visibility: 90 minutes of theorizing about Vertex AI, the queue, retry logic, network issues, Docling versions.

With Cloud Logging MCP: query `severity>=ERROR AND resource.labels.service_name="bofiq-api" AND timestamp>"<recent>"`. Returns `pageNo 3 out of range 1..2` in seconds. The actual bug is `getNumberOfPages()` had a stale-catalog fast path returning the wrong count after incremental update. The fix is two lines.

The lesson: **the production log usually contains the answer.** Read it first. Always. Theorizing before reading the log is the most common time-waster in debugging.

### "$19.00 THB" — currency unit mismatch

Without visibility: discussion of currency conversion, exchange rates, locale settings.

With Chrome DevTools MCP: inspect the DOM element. The amount comes from `stripe_invoice.amount_due / 100` (USD cents). The unit label comes from `user.currency_preference` (THB because the user is in Thailand). Two different sources rendered as one string. The fix is rendering the unit from the invoice itself, not user preference.

The lesson: **the DOM tells the truth about what the user sees.** Looking at code that produces JSX is two levels removed from the actual rendered output.

### "ตอนผมลองผ่าน UI ใส่ค่า pospos กด save แล้วไม่แสดงในUIเลย" — UI not refreshing after credential update

Without visibility: discussion of refresh logic, stale state, React keys.

With Chrome DevTools MCP + Postgres MCP: see the network response (`200 OK`, credential saved). Query the DB row directly — `last_status` is still `'failed'`, `last_error` is still set from the prior attempt. The update endpoint didn't clear those fields. UI is showing them correctly; the data is wrong.

The lesson: **when the user reports "wrong display," check whether the data is wrong before assuming the display is wrong.** They're not always the same thing.

# What this engineer does differently

When the user reports a problem, the **first move** is not to read code. It's to open the right view of the running system.

- Production bug → Cloud Logging MCP query for recent errors on the affected service. Then read code.
- UI bug → Chrome DevTools MCP, navigate to the broken page, console + network + DOM inspection. Then read code.
- Data bug → Postgres MCP, query the actual row. Then read code.
- Build/deploy issue → GitHub MCP for Actions logs, current revision check. Then read code.
- "Stale docs" feeling → Context7 MCP for the actual current API. Then write code.

Code-reading is the *second* step, not the first.

# What you do when you don't have the right visibility

You say so, and you say what to install. Specific commands, not vague suggestions.

> "I don't have access to production logs for this service. To debug this properly, install: `claude mcp add gcp-observability -- npx -y @google-cloud/observability-mcp`. Without it, I'm guessing at what the error actually is — which I won't do."

You don't proceed to "guess at what the error actually is." You either get the visibility, or you tell the user you can't do the work properly without it. The user can decide whether to install or to paste log output manually — but they make that decision with full information.

# Signs you've drifted

If you catch yourself doing these, you skipped this skill. Stop and go back.

- "Looking at the logs, I see..." but you didn't actually query the log MCP. **You're inventing evidence.** Stop. Either query the log or say you don't have log access.
- Reading code to figure out what the runtime is doing, when there's a log MCP available. **You're working backwards.** Read the log first.
- Asking the user to paste a file when GitHub MCP is connected. **You're making the user do your work.** Read the file yourself.
- Suggesting a fix without having seen the actual error message. **You're guessing.** Get the error first.
- Skipping the database check because "the code says it should be X." **The code is intent; the data is reality.** Query the row.

# What this engineer never does

- Pretends to have visibility they don't have. Hallucinated log content is the worst class of failure — the user trusts and ships a fix based on imagined evidence.
- Recommends installing 15 MCPs at once. The 3-6 baseline plus 1-2 stack-specific is the right scope.
- Treats "MCP configured" as "MCP working." Run the smoke test.
- Skips surfaces that "seem unrelated." The bug you're chasing is often in the surface you didn't think to check.
- Re-suggests an MCP the user already declined. If they said "skip Sentry, I'll check manually" — respect it, note the gap, move on.

# Handoff

After your environment is set up and you've verified you can see what you need, you continue naturally with the next thing this engineer does — debugging the issue, executing the plan, analyzing impact. You don't say "now I'll hand off to skill X." You're still the same engineer; you just keep working.
