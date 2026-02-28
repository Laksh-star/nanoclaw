---
name: setup-movie-concierge
description: Set up a personal movie concierge in a Telegram or WhatsApp group. Andy tracks your watchlist, remembers ratings and preferences, searches TMDB for movie info, and gives personalised recommendations. Use when a user wants a movie assistant in their personal chat.
---

# Setup Movie Concierge

Sets up Andy as a personal movie assistant in a Telegram or WhatsApp group. Uses the TMDB MCP for structured movie data (search, trending, recommendations) and maintains a local watchlist and ratings file that Andy remembers across sessions.

## Prerequisites

- `TMDB_API_KEY` must be set in `.env` and synced to `data/env/env`
- Container must be rebuilt with `./container/build.sh` to include the TMDB MCP

Verify:
```bash
grep TMDB_API_KEY .env
```

---

## Phase 1: Gather Configuration

Ask the user (use `AskUserQuestion`):

1. **Which group?** — Which Telegram or WhatsApp group should become the movie concierge? (usually personal DM / self-chat)
   - Look up folder name from registered groups:
     ```bash
     sqlite3 store/messages.db "SELECT name, folder FROM registered_groups"
     ```

2. **Preferred genres?** — What genres do you enjoy most? (e.g. Thriller, Sci-Fi, Drama, Comedy — pick top 3)

3. **Languages?** — English only, or include other languages? (e.g. Hindi, Tamil, Spanish)

4. **Trending digest?** — Do you want a weekly "What's trending" message? (Yes/No — if yes, which day and time?)

---

## Phase 2: Initialize Watchlist Data

Create the movie data directory in the group folder:

```bash
mkdir -p groups/<FOLDER>/movies
```

Create `groups/<FOLDER>/movies/watchlist.json`:
```json
{
  "to_watch": [],
  "watched": [],
  "updated_at": "<ISO timestamp>"
}
```

`to_watch` entry format:
```json
{
  "tmdb_id": 550,
  "title": "Fight Club",
  "year": 1999,
  "added_at": "<ISO timestamp>",
  "note": "optional note from user"
}
```

`watched` entry format:
```json
{
  "tmdb_id": 550,
  "title": "Fight Club",
  "year": 1999,
  "watched_at": "<ISO timestamp>",
  "rating": 9,
  "review": "optional short note"
}
```

Create `groups/<FOLDER>/movies/preferences.json`:
```json
{
  "genres": ["<genre1>", "<genre2>", "<genre3>"],
  "languages": ["English"],
  "disliked": [],
  "updated_at": "<ISO timestamp>"
}
```

---

## Phase 3: Inject CLAUDE.md

Append the movie concierge section to `groups/<FOLDER>/CLAUDE.md` (create if it doesn't exist):

```markdown
---

## Movie Concierge

You are also a personal movie assistant. Your movie data lives in `/workspace/group/movies/`.

### What You Can Do

- **Search movies** — use `mcp__tmdb__search_movies` for any title or keyword
- **Movie details** — use the TMDB resource `tmdb:///movie/<id>` for full details (cast, director, rating, genres, reviews)
- **Trending** — use `mcp__tmdb__get_trending` with `timeWindow: "week"` or `"day"`
- **Recommendations** — use `mcp__tmdb__get_recommendations` with a TMDB movie ID
- **Watchlist** — read/write `/workspace/group/movies/watchlist.json`
- **Preferences** — read `/workspace/group/movies/preferences.json` for genre/language preferences

### Natural Language Commands

| User says | What to do |
|-----------|-----------|
| "Add [movie] to my watchlist" | Search TMDB for the movie, get its ID, add to `watchlist.json` to_watch |
| "What should I watch tonight?" | Read preferences + watchlist, call `get_recommendations` based on a recent watched film, filter by genre preference, suggest 3 options |
| "Tell me about [movie]" | `search_movies` to get ID, then fetch `tmdb:///movie/<id>` resource for full details |
| "What's trending?" | `get_trending` with timeWindow "week", format nicely |
| "I just watched [movie], rate it [X]/10" | Move from to_watch → watched with rating, optionally ask for a short review |
| "Show my watchlist" | List to_watch entries with title, year |
| "Show what I've watched" | List watched entries with title, year, rating |
| "Recommend something like [movie]" | Search for movie ID, then `get_recommendations` |
| "Remove [movie] from watchlist" | Remove from to_watch array |

### Tone & Format

- Keep movie info conversational — don't dump raw JSON
- For recommendations, explain *why* you're suggesting each one based on their preferences
- After they mark a movie as watched, ask for a quick rating if they haven't given one
- Use their preference file to filter recommendations — don't suggest genres they dislike
```

---

## Phase 4: Optional — Weekly Trending Digest

If the user wants a weekly trending message, create a scheduled task:

1. Convert their preferred day/time to cron (e.g. "Sunday 10 AM IST" → `0 4 * * 0` in UTC, but scheduler uses local — `0 10 * * 0`)
2. Write IPC task file to `data/ipc/telegram/tasks/` (or main for WhatsApp):

```json
{
  "type": "schedule_task",
  "prompt": "Fetch this week's trending movies using mcp__tmdb__get_trending with timeWindow='week'. Format the top 5 as a friendly digest — title, year, rating, one-line overview. Send via mcp__nanoclaw__send_message. Keep it casual and fun.",
  "schedule_type": "cron",
  "schedule_value": "0 10 * * 0",
  "context_mode": "isolated",
  "targetJid": "<GROUP_JID>",
  "createdBy": "<FOLDER>",
  "timestamp": "<ISO_NOW>"
}
```

---

## Phase 5: Confirm and Test

1. Confirm setup with user:
   > "Movie concierge is set up in [group]. Try: 'What's trending this week?' or 'Add Interstellar to my watchlist'."

2. Do a quick live test — ask Andy (via the group) to fetch today's trending movies to verify the TMDB MCP is wired correctly.

---

## Troubleshooting

**TMDB MCP not available (Andy says tool not found):**
- Check `TMDB_API_KEY` in `.env` and `data/env/env`
- Rebuild container: `./container/build.sh`
- Restart service: `launchctl kickstart -k gui/$(id -u)/com.nanoclaw`

**Wrong movie found:**
- Ask Andy to confirm the TMDB ID before adding to watchlist
- User can say "yes that's the one" or "no, the 2014 version"

**Watchlist not persisting:**
- Check `/workspace/group/movies/watchlist.json` exists in the container mount
- The `groups/<FOLDER>/` directory is mounted at `/workspace/group/` — files written there persist on the host
