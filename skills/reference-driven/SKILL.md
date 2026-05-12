---
name: reference-driven
description: Activates when the user points at an existing example and asks you to build something like it — "match the style of this other page", "do it the way we did for X", "follow the pattern in file Y". You read the reference comprehensively before building, understanding the actual patterns it uses rather than building from a surface impression. Common in projects with established conventions where consistency matters more than novelty.
---

# When the user points at an example

The user shows you something and says "do it like this." Maybe it's another page in the same app, another service that solved a similar problem, an open-source repo to mimic, or a design they want matched.

Junior engineers glance at the example, form a surface impression, and build something that *looks* similar but doesn't match the deeper patterns. The result is code that's inconsistent in subtle ways — different folder structures, different error handling, different naming conventions, different test patterns. Each inconsistency makes the codebase harder to maintain.

You don't do that. You read the reference carefully. You understand *why* it's built that way. Then you build the new thing using the same patterns — not just the surface look.

# How you read a reference

**You read it completely before writing anything new.** Not skim it. Read it. If it's a file, read every line. If it's a feature, look at every file involved (the route, the component, the data layer, the test, the migration if any). The patterns are in the details.

**You identify the structural patterns:**
- **Folder layout**: where do related files live? Are they colocated? Separated by layer?
- **Naming**: how are files/functions/types named? CamelCase? kebab-case? Specific suffixes (`*-service.ts`, `*.action.ts`)?
- **Boundaries**: what's a "page" vs a "component" vs a "view" in this codebase? Where does data fetching live?
- **Error handling**: try/catch with specific error types? Result types? Just letting errors bubble?
- **Auth**: how is the current user obtained in this codebase? Per-page, via context, via middleware?
- **Data access**: ORM? Raw SQL? Through a service layer?
- **Validation**: at the API boundary? In the form? Both?
- **Testing**: what gets tested? At what layer? Using which framework?

**You identify the conventions that aren't obvious:**
- Sometimes a codebase consistently uses a certain pattern that isn't in any style guide. Logging always goes through a specific helper. Errors always include a specific shape. Database calls always go through a repository. **The reference shows you what to copy, even if nobody wrote down a rule.**
- Inconsistencies in the reference are also signal — maybe the codebase is mid-migration from one pattern to another. Ask which is the target pattern.

**You ask if anything is unclear, *before* writing.** "I see the reference uses `getUser()` in two ways — sometimes returning a promise, sometimes synchronous. Which is the current pattern?" Better to clarify upfront than to build a thing using the wrong half of the pattern.

# How you build to match

**You match the structure, not just the surface.** If the reference puts the data fetch in a server component and uses Suspense, you do that. If the reference uses TanStack Query in a client component, you do that. Picking the same approach matters more than picking the "best" approach.

**You name things using the codebase's vocabulary.** If the codebase calls them "organizations," don't introduce "tenants." If routes use `/api/billing/invoices`, don't add `/api/invoices/billing`. Consistency reduces cognitive load for everyone who reads the code later.

**You match the level of testing.** If similar features in the codebase have integration tests but no unit tests, you write integration tests but no unit tests. If they have both, you write both. **You don't unilaterally raise or lower the bar** — you match it. (If you think the bar is wrong, you raise that as a separate conversation, not by silently changing this one feature.)

**You use the same helpers.** If the codebase has a `formatCurrency()` utility, you use it. You don't write your own ad-hoc version. If you can't find the helper but think it should exist, search harder before writing a new one.

**You match the error and logging patterns.** Each codebase has a way it handles errors and emits logs. Use that way. Don't introduce a new way for your feature.

# When the reference is bad

Sometimes the reference uses a pattern you can see is broken, slow, or unsafe. Two options:

1. **Match it and flag it.** If the broken pattern is consistent across the codebase, fixing it in one place creates inconsistency. Match the pattern for now, but in your final report, name the issue: "The reference uses pattern X for error handling, which silently swallows the underlying error. I followed it for consistency, but suggest fixing all uses in a separate task."

2. **Deviate carefully.** If the reference's pattern would cause a real bug in your case (e.g., the reference's auth check is correct for a public route but you're adding an admin route), deviate — and explain why in the code and in your report.

**You don't silently "improve" the codebase's patterns** while implementing a feature. That mixes refactoring and feature work, makes review harder, and frustrates the user who asked for matching, not refactoring.

# Concrete patterns

### "Make this new page match the style of [existing page]"

You read the existing page's component, its data fetching, its imports, its CSS approach. You note: this codebase uses server components for data, Tailwind for styling, lucide-react for icons, and a custom `<PageHeader>` component. You build the new page using all of those, in the same arrangement.

### "Add a new API endpoint like the /api/X one"

You read the existing endpoint completely: route definition, request validation, auth check, business logic location, response shape, error handling, tests. You build your new endpoint with the same architecture — same validation library, same auth pattern, same response wrapper, same test structure.

### "Match the test style of this file"

You don't reinvent. Same imports, same test framework (Vitest? Jest? pytest?), same fixture pattern, same assertion style, same describe/it nesting depth. Match it.

### "Internationalize the new pages the way we did for X"

You read how X was internationalized. What library? Where do strings live? What's the key naming convention? Are there interpolation patterns? RTL handling? You apply the exact same approach to the new pages.

### "Build this feature like the [reference repo] does"

You read the reference repo's relevant files. You note the architectural patterns. You implement the feature using those patterns in your codebase — adapted to your stack, but structurally consistent with the reference.

# Concrete past failures encoded here

**i18n inconsistency.** Past pattern: when internationalizing pages, sometimes the same string was extracted to a key in one place and inlined in another. Sometimes plurals were handled, sometimes not. Sometimes date formatting used the locale, sometimes used a hardcoded format. The reference work existed, but it wasn't read carefully — each new page got internationalized by surface impression.

The lesson: **internationalization patterns are detailed.** Skimming isn't enough; read every key, every helper, every formatter.

**Component variations.** Past pattern: `<Button>` was used inconsistently — some places used the local primitive, some used the shadcn/ui version, some used a custom inline button. New code kept introducing the next variation. The lesson: **when you see multiple patterns in the codebase, ask which one is current before adding a third.**

# Signs you've drifted

- You started building the new thing before reading the reference fully. Stop. Read it.
- You're writing your own version of a helper that probably exists. Search the codebase before writing.
- You're using a different test framework than the rest of the codebase. Match.
- You're naming things differently than the codebase's existing names. Match.
- You're "improving" the reference's patterns while implementing the new feature. Separate the work or don't do the refactor.

# What this engineer never does

- Builds from a quick glance at the reference instead of a careful read.
- Introduces a new pattern without asking whether the existing pattern is the target.
- Mixes "make it look like the reference" with "improve the reference's approach." Those are two different tasks.
- Skips reading the reference's tests, then can't figure out how to test the new thing.
- Says "I followed the reference" without specifically explaining how — which patterns, which conventions, which helpers.

# Handoff

After you've understood the reference and planned the new build, you continue into building it. Throughout the build, you keep referring back to the reference whenever ambiguity arises. The reference *is* part of the spec.
