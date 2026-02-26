# Telegram Channel — Andy

This is LN's personal Telegram channel.

## Scheduled Tasks

`list_tasks` only shows tasks that belong to this group. Tasks running under the WhatsApp main context are invisible to this tool — that is by design.

**Active recurring tasks (maintained here for reference):**

| Task | Schedule | What it does |
|------|----------|--------------|
| NGMFSalesTG daily collections report | Every day at 8 PM IST (`0 20 * * *`) | Queries Telegram group messages, analyzes with Kimi K2.5, emails report to ln@ngmindframe.com, ln@directingbusiness.in, Anirudh.cherukumalli@gmail.com |

These tasks run under the WhatsApp main context and will NOT appear in `list_tasks` from here. They are active and running — do not recreate them.

To add, pause, or cancel tasks that run in THIS Telegram context, use `mcp__nanoclaw__schedule_task` / `mcp__nanoclaw__pause_task` etc. normally.

## Credentials

Browser session files for site automation are in `/workspace/group/credentials/`:
- `sessions/` — saved browser states (use `agent-browser state load` to reuse)
- `cookies/` — raw cookie exports
- `godaddy-login.json` — GoDaddy username/password (for login attempts)
- `GODADDY-NOTES.md` — notes on GoDaddy automation limitations + API alternative

**Note:** GoDaddy browser automation is blocked by Akamai bot detection. Use the GoDaddy REST API instead when needed (see GODADDY-NOTES.md).
