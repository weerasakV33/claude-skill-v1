---
name: impact-analysis
description: Activates when you're about to change code that other parts of the system depend on — a shared utility, a database column used in many places, an API endpoint with multiple callers, a component used across pages, a config value referenced widely. You trace the dependencies first to understand the blast radius, then plan the change so it doesn't break callers. The goal is to avoid the "fixed one thing, broke five things" pattern. Triggers before build-complete-system when the planned change touches shared surfaces; can be invoked by debugging when you need to know who else depends on the broken thing.
---

# When you change shared things

Some changes are local — a one-page UI tweak, a typo fix, a function only called from one place. You can make those changes without worry.

Other changes are systemic. The function you're about to modify is called from 12 files. The database column you want to rename is read by three services. The API response shape you're tightening is consumed by a frontend, a mobile app, and three webhooks. Change those carelessly and you break things in places you forgot existed.

The discipline of this skill is: **before you change a shared thing, find everywhere that depends on it, and plan the change to not break them.**

Junior engineers change shared things and discover the breakage later — via test failures, error logs, or angry users. You discover the breakage first, by looking.

# How you analyze impact

**You list every caller, comprehensively.** Search the codebase. `grep -r` is the floor; better is your IDE's "find references" or a real semantic search. For database columns, you check every file that mentions the column name. For API endpoints, you find every callsite — including frontend, mobile, scheduled jobs, webhooks. **The list isn't done until you've actually looked, not until you remember what calls it.** Memory lies; the code doesn't.

**You distinguish "direct caller" from "transitive consumer."** If you change function X, function Y calls it directly — but A, B, C also break because they call Y. The full impact includes the transitive set, not just the directly visible callers.

**You think about external consumers, not just internal code.**
- API endpoints: third-party integrations, mobile apps, webhooks pointing in
- Database tables: downstream BI/analytics queries, exports, replication
- Public types/interfaces: anyone who imported them from a published package
- Event payloads: queue consumers in other services
- Environment variables: deploy configs, terraform, secrets management

**You categorize the changes you're about to make:**
- **Additive** (e.g., new optional column, new optional API field): safe, doesn't break callers.
- **Behavioral** (e.g., function returns same shape but different value): callers don't break syntactically, but logic may be wrong. Audit needed.
- **Breaking** (e.g., removing a column, changing required types, renaming a function): every caller needs to be updated.

**You plan the change to minimize breakage.**

For breaking changes, the senior pattern is **expand → migrate → contract**:
1. **Expand**: add the new thing alongside the old thing (new column, new function, new API field) — non-breaking
2. **Migrate**: update all callers to use the new thing
3. **Contract**: remove the old thing after all callers are migrated

This converts one big breaking change into a series of non-breaking ones. It's slower but actually safe in production.

For purely additive changes, you can just add — but you still document the new contract.

For behavioral changes, you audit every caller for whether the new behavior is correct for them. Sometimes it isn't, and you discover that calling site C was relying on the old behavior in a way nobody documented.

# When you don't know all the consumers

You go find them. You don't guess "it's probably only called from a few places." You look:

- Search the codebase comprehensively (not just files you remember opening)
- Check external systems that might consume the surface (mobile apps, webhooks, downstream services)
- Ask the user about consumers outside the visible codebase — but only after you've done your own search

**Asking "who calls this?" without having searched first is lazy.** Search first; ask only about things outside what you can see.

# Specific situations and how you handle them

### "Rename a database column"

You don't rename. You add the new column, copy data, switch reads to the new column, switch writes to the new column, then drop the old column in a separate migration after some bake time. Each step is independently safe to deploy.

### "Change a function signature"

You list every callsite. Categorize: are they updateable by you, or do they have external dependencies? If purely internal, update them all in one PR. If external (e.g., the function is exported as part of a package), add an overload or deprecation path.

### "Change an API response shape"

External consumers may be on different deploy schedules than you. Add the new fields, keep the old ones, mark old ones deprecated in docs, give consumers time to migrate, then remove.

### "Refactor a shared component"

Find every place that imports it. For each, check whether the new component behavior matches the old expectation. Often "shared component" has accumulated subtle variations that callers rely on — visit each one.

### "Update a critical dependency"

Read the changelog between current and target versions. Note every breaking change. Search your code for usages of the breaking APIs. Plan the migration for each. **Don't just bump the version and run tests** — tests don't catch silent semantic changes.

### "Change a config value (e.g., default timeout)"

Find every place that reads the config. Check whether the new default is correct for each. The old default may have been wrong, but some callsite may have been specifically relying on it.

# Concrete past failures encoded here

**pg-diag crashed the production DB.** Past pattern: a diagnostic tool was added to inspect Postgres performance. On the surface it was read-only. But its connection pool was configured assuming low concurrency. In production, under real load, it acquired connections faster than it released them, starved the application's connection pool, and brought down the database. The impact analysis that wasn't done: "this tool will share the connection pool with production traffic; what happens at the 99th percentile of load?"

The lesson: **"read-only" doesn't mean "safe in production."** Operational tools touching production share its resources. Analyze that.

**Migration 00130 missing uuid cast.** Past pattern: an FK constraint migration that worked on a clean test DB failed in production because the column types didn't match (text vs uuid). The impact analysis that wasn't done: "what's the actual type of this column in production right now, including historical data?"

The lesson: **migrations are changes to a system with existing state.** The state is part of the impact surface.

**Currency display "$X THB."** Past pattern: two fields (amount and currency-unit-label) were assumed to always agree because they used to come from the same place. Later, they were sourced from different places (invoice currency vs user preference). The impact analysis that wasn't done: "if these two come from different sources, what's the contract that they should agree?"

The lesson: **when two fields together have to mean something, splitting their sources requires re-establishing the contract.**

# How you communicate impact

When you've done the analysis, you produce a summary like this:

```
Change: rename `subscriptions.status` to `subscriptions.lifecycle_status`

Direct callers found (12):
  - api/billing/routes.ts (2 reads, 1 write)
  - api/webhooks/stripe.ts (1 write)
  - workers/subscription-reaper.ts (1 read)
  - admin/views/subscription-list.tsx (1 read)
  - ... (8 more)

Transitive impact:
  - Any frontend page that fetches subscription data uses the field name in the response → mobile app team needs to know
  - The analytics warehouse syncs this column directly → data team needs to know

Plan (expand → migrate → contract):
  1. Migration adds `lifecycle_status` column, copies values from `status`
  2. Backend: writes go to both columns; reads switch to new column
  3. Notify mobile + data team of the new field; give them 2 weeks
  4. Backend: stop writing old column
  5. Migration drops `status` column

That's 5 deploys over ~2 weeks. Want me to start, or is the
2-week timeline a problem?
```

The user can see the full picture and decide.

# Signs you've drifted

- You're about to change a shared thing without checking who else uses it. Stop. Check.
- You found "a few" callers and decided that's probably all of them. "Probably" is how you ship breakage. Be exhaustive.
- You're planning a one-shot breaking change to something with multiple consumers. That's a recipe for production incidents. Use expand-migrate-contract instead.
- You're treating external consumers (mobile apps, third parties) as "their problem." It's a coordination problem; coordinate.

# What this engineer never does

- Renames public API surfaces without a deprecation path.
- Drops database columns in the same migration that adds the replacement.
- Assumes that because tests pass, no callers are broken — tests cover what they cover, not the full callsite graph.
- Treats the changelog of a library upgrade as optional reading.
- Ships a breaking change late on Friday.

# Handoff

After the impact analysis is done and the plan is agreed, you continue into building it. If the analysis revealed the change is way bigger than initially scoped, you surface that to the user and revisit the original plan — sometimes the right answer is "don't make this change, find a different solution."
