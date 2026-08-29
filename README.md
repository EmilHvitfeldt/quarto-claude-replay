# quarto-claude-replay

A Quarto extension for embedding [claude-replay](https://github.com/es617/claude-replay) session replays in HTML documents and revealjs presentations, with fragment-driven turn stepping in slides.

claude-replay converts AI coding agent sessions (Claude Code, Cursor, Codex CLI, Gemini CLI, and more) into self-contained interactive HTML replays. This extension makes it easy to embed those replays in Quarto output, and in revealjs decks it lets you step through session turns with the arrow keys, just like fragments.

## Installation

```bash
quarto add emilhvitfeldt/quarto-claude-replay
```

This will install the extension under the `_extensions` subdirectory. If you're using version control, you will want to check in this directory.

## Generating a replay

Use claude-replay to turn a session transcript into a replay file:

```bash
npx claude-replay <session-id> -o replay.html
```

See the [claude-replay documentation](https://github.com/es617/claude-replay#quick-start) for all the ways to locate, trim, and theme a session. Note that replay files embed the full transcript (code, paths, tool output); review them before publishing.

## Usage

### Embedding a replay

```markdown
{{< claude-replay replay.html >}}
```

The replay file path is relative to the document. The file is automatically copied to the output directory as a resource.

Options:

| Option   | Default                                | Description                              |
| -------- | -------------------------------------- | ---------------------------------------- |
| `height` | `600px` (documents), `100%` (revealjs) | Height of the embed                       |
| `width`  | `100%`                                  | Width of the embed                        |
| `turn`   | `0` (splash screen)                     | Turn to show initially                    |
| `title`  | `Claude Code session replay`            | Iframe `title` attribute (accessibility)  |
| `class`  |                                         | Extra CSS classes on the wrapper          |
| `scrollbar` | `true`                               | `false` hides the replay's scrollbar      |

```markdown
{{< claude-replay replay.html height=400 turn=2 >}}
```

In non-HTML formats the shortcode degrades to a link to the replay file.

### Stepping through turns in revealjs

Add invisible fragment steps after the embed. Each step advances the replay to the given turn when shown, and stepping backwards rewinds it:

```markdown
## My debugging session

{{< claude-replay replay.html >}}

{{< claude-replay-step 1 >}}
{{< claude-replay-step 2 >}}
{{< claude-replay-step 5 >}}
```

You can skip turns (e.g. jump straight from turn 2 to turn 5) and combine steps with regular fragments on the same slide. Jumping into a slide mid-deck restores the replay to the state matching the visible fragments. In revealjs the iframe is lazy-loaded (`data-src`), so large replay files don't slow down deck startup.

Notes:

- The embed fills the slide via `r-stretch` by default; pass an explicit `height` to opt out of stretching.
- Only turn seeking is exposed by the claude-replay player; play/pause/speed can't be driven from fragments.
- Viewers can still interact with the replay directly (scroll, play, expand tool calls). If they click inside the iframe, keyboard focus moves there; clicking outside returns arrow-key control to the deck.

### Matching the slide background

A replay carries its own theme background, so by default it reads as a panel sitting on the slide. To make it blend in, set the slide background to the replay theme's `--bg` (look it up at the top of the generated replay file, e.g. `#1a1b26` for tokyo-night, `#f0f2f5` for bubbles) and drop the iframe border:

```markdown
## My session {background-color="#1a1b26"}

{{< claude-replay replay.html class=seamless scrollbar=false >}}
```

```css
.reveal .claude-replay-embed.seamless iframe {
  border: none;
  border-radius: 0;
}
```

Remember to set a matching slide text color for the heading and body copy. See [slides.css](slides.css) for the version used in the example deck.

### Full-screen replays

An embedded replay is confined to the slide rectangle, which reveal.js letterboxes inside the browser window. To have a replay cover the entire screen, put it on the slide heading instead:

```markdown
---
filters:
  - claude-replay
---

## {claude-replay="replay.html"}

{{< claude-replay-step 1 >}}
{{< claude-replay-step 2 >}}
```

This expands to reveal.js's own `background-iframe`, whose layer sits outside the scaled slide container and so fills the window edge to edge. Fragment steps on the slide drive it exactly like an embedded replay.

| Attribute      | Default | Description                            |
| -------------- | ------- | -------------------------------------- |
| `claude-replay`|         | Path to the replay file                 |
| `turn`         | `0`     | Turn to show initially                  |
| `scrollbar`    | `false` | `true` keeps the replay's scrollbar     |

The `filters: - claude-replay` entry is required: Quarto loads shortcodes from an extension automatically, but filters only on request. Use a title-less heading (`##` with just the attributes) so nothing is drawn over the replay, and pick a replay theme whose background suits your deck, since the replay covers the slide background entirely.

## Example

[index.qmd](index.qmd) is a revealjs deck covering every feature above, published at <https://emilhvitfeldt.github.io/quarto-claude-replay/>. [example.qmd](example.qmd) is the plain HTML equivalent.

The demo replays under `docs/` are generated from claude-replay's public demo session, in two themes:

```bash
npx claude-replay docs/demo-session.jsonl --title "Replay — docs" -o docs/demo-replay.html
npx claude-replay docs/demo-session.jsonl --title "Replay — docs" --theme bubbles -o docs/demo-replay-bubbles.html
```

## License

MIT. claude-replay itself is a separate MIT-licensed project by [es617](https://github.com/es617) and is not bundled with this extension.
