---
name: agent-design
description: Design framework for new BizClaw/NanoClaw capabilities. Run before building any new tool, skill, MCP tool, or agent behavior. Uses principles from "Lessons from Building Claude Code: Seeing like an Agent" to make principled, documented design decisions. Triggers on "design a capability", "should I build a tool", "how should I add this", "agent design".
---

# Agent Design Framework

Run this skill before building any new BizClaw capability — tool, skill, MCP server entry, or agent behavior change. Walks through the key design decisions to avoid common mistakes and produce a principled, documented output.

## When to Use

- Before creating a new skill (`.claude/skills/`)
- Before adding a new MCP tool to `ipc-mcp-stdio.ts`
- Before adding something to `CLAUDE.md`
- Before adding a new IPC type or core code change
- When an existing capability isn't working as expected and you're considering a redesign

---

## Phase 1: Define the Capability

Ask the user (use `AskUserQuestion`):

1. **What is the user trying to do?** Describe the end behavior — not the implementation.
2. **Who triggers it?** User in chat → Andy? Claude Code CLI? Scheduled task? Another agent?
3. **What's the current workaround?** How is it done today, and what's painful about it?

---

## Phase 2: Decision Framework

Work through each question. Record the answer and rationale.

---

### Q1: Tool or Instruction?

> "Does this need a structural guarantee, or is best-effort good enough?"

| Need | Approach |
|------|----------|
| Output must always have a specific format or trigger a reliable action | **Dedicated tool** (MCP tool or Claude Code tool) |
| Occasional variation is acceptable, no downstream system depends on it | **Prompt instruction** or CLAUDE.md entry |

**Signs you need a tool:** scheduling tasks, sending messages, registering groups, anything where failures have consequences or format matters to a downstream system.

**Signs an instruction is enough:** formatting preferences, tone, language, soft behavioral nudges.

> **Principle:** Prompt-only constraints break. Claude will add sentences, change format, omit options. If you need reliability, build a tool with a schema.

---

### Q2: Knowledge or Action?

> "Is this adding knowledge (facts, docs, how-to), or adding a new action?"

| Type | Approach |
|------|----------|
| Knowledge (documentation, how-to, reference) | **Progressive disclosure** — a guide file or `call_model` subagent Andy queries on demand |
| Action (do something new in the world) | Tool, new IPC type, or skill |

**Anti-pattern:** Dumping documentation into `CLAUDE.md`. Every paragraph added is loaded every session for every group, whether relevant or not.

**Better:** A dedicated guide file that Andy queries via `call_model` only when asked a capability question.

> **Principle:** Ask — does Andy need this every session, or only when specifically asked? If the latter, keep it out of CLAUDE.md.

---

### Q3: Cognitive Load Check

> "Does this justify a new top-level tool in the agent?"

Current tools in `ipc-mcp-stdio.ts`: `send_message`, `schedule_task`, `list_tasks`, `pause_task`, `resume_task`, `cancel_task`, `register_group`, `call_model`

Ask:
- Can existing tools + a well-crafted prompt handle this?
- Can a `call_model` subagent handle it instead of a new tool?
- Will this be used frequently enough to justify the decision burden on Andy every session?

> **Principle:** Each top-level tool adds cognitive load to every agent invocation. Prefer composition — subagents and skills — over adding new tools.

---

### Q4: Skill or Core Change?

> "Where does this live?"

| Location | Use for |
|----------|---------|
| `.claude/skills/` | Setup workflows, one-time configurations, guided processes (Claude Code level) |
| `container/agent-runner/src/ipc-mcp-stdio.ts` | New action Andy takes from inside a container |
| `src/` or `container/` | New channel, new IPC type, runtime behavior (core change) |
| `groups/global/CLAUDE.md` | Persistent instruction or context Andy always needs |
| `groups/{folder}/CLAUDE.md` | Group-specific persistent instruction |

**Default to skill.** Core changes are harder to maintain, test, and keep in sync with upstream NanoClaw. Skills are self-contained, versionable, and easy to share across deployments.

> **Principle:** Skills over features. New capability = new skill until proven it needs to be core.

---

### Q5: Evolution Check

> "Does this replace or extend something existing?"

- Audit current tools and skills — is there overlap?
- If replacing: plan migration, remove dead code
- If extending: can the existing tool/skill be updated rather than creating a new one?
- **Future-proof question:** Is this designed for current model capabilities, or is it a workaround that a better model won't need?

> **Principle:** Tools designed for older model capabilities become constraints for better models. Note any assumptions that should be revisited as capabilities grow.

---

## Phase 3: Design Output

Produce a design doc and confirm with the user before implementing:

```markdown
## Capability: [Name]

**What it does:** [One sentence]
**Triggered by:** [User in chat / Claude Code CLI / Scheduled task / Another agent]

### Design Decisions

| Question | Answer | Rationale |
|----------|--------|-----------|
| Tool or Instruction? | [Tool / Instruction] | [Why] |
| Knowledge or Action? | [Knowledge / Action] | [Why] |
| New tool justified? | [Yes / No / Use existing X] | [Why] |
| Where does it live? | [Skill / Core / CLAUDE.md / MCP tool] | [Why] |

### What NOT to do

- [Anti-pattern and why it fails here]

### Implementation Plan

1. [Step 1]
2. [Step 2]

### Revisit When

- [Assumption that should be revisited as model capabilities grow]
```

---

## Phase 4: Document the Decision

After design is agreed and implementation is done:

1. Add an entry to `bizclaw-updates.md` under the current version
2. If it changes Andy's behavior → update `groups/global/CLAUDE.md`
3. If it's a new skill → the SKILL.md is the documentation
4. If it defers something → log the deferral decision with rationale in `bizclaw-updates.md`

Deferred decisions are as important to document as built ones — they prevent re-litigating the same question next month.

---

## Reference: Core Design Principles

From *"Lessons from Building Claude Code: Seeing like an Agent"* (Anthropic, 2026):

1. **Dedicated tools beat prompt formatting** — Use schemas, not instructions, for guaranteed structure
2. **Tools evolve with model capability** — Audit periodically; yesterday's helpful constraint is tomorrow's bloat
3. **Self-directed search beats pre-injected context** — Give agents tools to find context, not pre-computed dumps
4. **Progressive disclosure** — Add knowledge via subagents and guide files, not system prompt bloat
5. **High bar for top-level tools** — Each adds cognitive load to every session; justify every addition
6. **Composition over addition** — Subagents and skills before new top-level tools
7. **See like an agent** — Read outputs carefully. Experiment. Match tools to what the model can actually do.

---

## BizClaw Design Decisions Log

| Date | Capability | Decision | Rationale |
|------|-----------|----------|-----------|
| 2026-02-28 | `/andy-guide` (progressive disclosure guide for Andy) | **Deferred** | CLAUDE.md not at painful scale yet. Revisit at first client deployment or when 10+ skills exist. |
| 2026-02-28 | `/agent-design` (this skill) | **Built** | Immediately useful for every future capability decision. Low effort, high leverage. Encodes design principles as a reusable process. |
