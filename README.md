# AI Agentic Tools for Students

Welcome! This container gives you access to powerful AI coding assistants. Pick the one that fits your workflow, or switch between them as you work.

---

## Quick Start

Your container comes pre-loaded with:
- **[Claude Code](https://code.claude.com/docs/en/overview)** — AI agentic coding tool from Anthropic
- **[OpenCode](https://github.com/opencode-ai/opencode)** — Open source code-focused AI tool
- **[Copilot](https://github.com/features/copilot)** — GitHub's AI pair programmer
- **[Crush](https://github.com/charmbracelet/crush)** — A beautifully themed assistant for command-line work
- **[Codex](https://github.com/openai/codex)** — OpenAI's agentic tool
- **[Gemini](https://github.com/google-gemini/gemini-cli)** — Google's AI coding assistant

---

## The Agents and Best Subscriptions

### Claude Code
- Claude Pro or Max subscription

### OpenCode
- Github Copilot subscription
- OpenAI Pro subscription
- OpenRouter API Key (pay per API call)

### Copilot
- Github Copilot subscription

### Crush
- Github Copilot subscription

### Codex
- OpenAI Pro subscription

### Gemini
- Google One AI Premium subscription

---

## Sign up for GitHub Education

If you're a student, the single best thing you can do before anything else is sign up for [GitHub Education](https://education.github.com/students). It's free and gives you access to the [GitHub Student Developer Pack](https://education.github.com/pack), which includes a free GitHub Copilot subscription.

**Why this matters for this container:**

- You get **300 free Copilot premium requests per month** — enough to do serious work without paying anything
- Copilot powers not just the Copilot agent, but also **OpenCode** and **Crush**, which both support GitHub Copilot as a backend
- In a **GitHub Codespace**, you're already authenticated as your GitHub account — so OpenCode and Copilot start working immediately with no login steps required

If you're working in Codespaces, start here. Sign up for GitHub Education, then come back and everything will just work.

---

## Starting the Agents

Each agent can be launched directly by name. The launcher scripts in `permissions/` start each tool with the right flags for a sandboxed environment — no permission prompts interrupting your workflow.

### Claude Code

```
% ./permissions/claude.sh
```

Runs `claude` with `IS_SANDBOX=1` and `--dangerously-skip-permissions`. Without these, Claude stops and asks before almost every file operation. In a dev container this is safe and makes the experience much smoother.

### OpenCode

```
% ./permissions/opencode.sh
```

Runs `opencode`. Permissions are handled by `.opencode/opencode.json` in the project, which is already configured with `read`, `write`, and `execute` all set to `allow`.

### Copilot

```
% ./permissions/copilot.sh
```

Runs `copilot --allow-all`, which allows all file and shell operations without prompting.

### Crush

```
% ./permissions/crush.sh
```

Runs `crush --yolo` — Charmbracelet's flag for skipping all permission prompts.

### Codex

```
% ./permissions/codex.sh
```

Runs `codex`. Codex handles its own permission model via `.codex/config.toml`, which is already configured for a sandbox environment.

---

## MCPs (Model Context Protocol servers)

MCP servers extend AI tools with access to external data and services. All MCP configuration flows from a single file:

```
configs/mcp-servers.conf
```

### Conf file format

```
# No-auth SSE MCP:
name=https://example.com/mcp/sse

# Authenticated HTTP MCP (value read from environment variable):
name=https://example.com/mcp|http|X-Api-Key:$MY_API_KEY_VAR
```

The dolt database MCP is enabled by default as a working example. The stitch MCP is included as a commented example of authenticated HTTP transport.

### Installing MCPs

After editing `configs/mcp-servers.conf`, run:

```
% install-mcps.sh
```

This reads the conf file and registers each MCP in all AI tools — Claude, OpenCode, Gemini, Crush, Copilot, and Codex. MCPs are written to each tool's home directory config. Safe to re-run; existing entries are replaced with current values.

### Uninstalling MCPs

```
% uninstall-mcps.sh
```

Removes all MCP registrations listed in the conf file from every tool's config.

### Adding an authenticated MCP

1. Add the entry to `configs/mcp-servers.conf`:
   ```
   stitch=https://stitch.googleapis.com/mcp|http|X-Goog-Api-Key:$STITCH_API_KEY
   ```
2. Add the secret value at [github.com/settings/codespaces](https://github.com/settings/codespaces)
3. Declare the variable in `.devcontainer/devcontainer.json` under `"secrets"` so Codespaces injects it
4. Run `install-mcps.sh`

---

## Need More Tools? (Optional)

### Data Science Additions

Installs Python data science libraries, Jupyter, Quarto, and TinyTeX:

```
% install-datascience.sh
```

Includes: numpy, pandas, matplotlib, seaborn, requests, Jupyter, Quarto, TinyTeX.

### Dolt Database Executable

Installs Dolt, a version-controlled SQL database:

```
% install-dolt.sh
```

---

## Skills (Custom slash commands)

Skills are shared slash commands (`/skill-name`) available across all AI tools. They live in `.skillshare/skills/` and are synced via the [skillshare CLI](https://github.com/runkids/skillshare).

### Setup

```
% setup-skills.sh
```

Run once. Creates the `.skillshare/` directory, installs the skillshare CLI, and adds a sample `hello-world` skill.

### Syncing skills

```
% sync-skills.sh
```

Pushes all skills in `.skillshare/skills/` to every AI tool listed in `.skillshare/config.yaml`.

### Adding a skill

1. Create `.skillshare/skills/<skill-name>/SKILL.md`
2. Run `sync-skills.sh`

The skill is now available as `/<skill-name>` in all configured tools.

---

## Using This as a Base for Your Own Course Repo

The scripts and tools are baked into the Docker image — your course repo only needs two files:

**.devcontainer/devcontainer.json**
```json
{
  "image": "ghcr.io/calvinw/ai-course-devcontainer:latest",
  "postCreateCommand": "setup-env.sh && install-mcps.sh || true"
}
```

**configs/mcp-servers.conf**
```
# Add your MCP entries here
dolt=https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse
```

When a Codespace is created from that repo, the image is pulled, the tools are available on PATH, and `install-mcps.sh` configures MCPs from the conf file. No `scripts/` or `permissions/` folders needed in the course repo.

### Syncing upstream changes

To pull the latest devcontainer setup and configs from this repo into your course repo:

```bash
bash scripts/sync-from-upstream.sh
git diff        # review changes
git add . && git commit -m "Sync from ai-agentic-tools upstream" && git push
```

---

## Advanced: Local Development & Testing

### Container image

The Dockerfile defines everything installed in the image. Scripts and permissions are baked in at `/usr/local/lib/ai-tools/` and placed on `PATH` — course repos don't need to carry them.

GitHub Actions builds and pushes to `ghcr.io/calvinw/ai-course-devcontainer:latest` whenever the Dockerfile changes.

### Make targets

| Target | Description |
|--------|-------------|
| `make up` | Pull published image, start container, run setup, open shell |
| `make shell` | Reattach to running container |
| `make stop` | Stop and remove container |
| `make build-test` | Build image locally as `ai-container-test` |
| `make up-test` | Build local image, start container, run setup, open shell |
| `make build` | Build and tag as published image |
| `make push` | Push to ghcr.io |

### Testing locally with VS Code

```
make build-test
code .
```

Then `Cmd+Shift+P` → **Dev Containers: Reopen in Container**.

### Testing the end-user experience

To simulate what a student sees in their own course repo (no scripts or permissions folders visible):

```bash
mkdir -p ~/my-test-course/configs
# add entries to ~/my-test-course/configs/mcp-servers.conf
# add ~/my-test-course/.devcontainer/devcontainer.json pointing to ai-container-test
code ~/my-test-course
```

Then **Dev Containers: Reopen in Container** — the workspace will only show course files, while all tools are available from the image.
