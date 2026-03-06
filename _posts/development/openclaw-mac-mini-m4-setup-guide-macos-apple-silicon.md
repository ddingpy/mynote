# OpenClaw on Mac mini (M4) Setup Guide (macOS / Apple Silicon)

> This guide is written for a **Mac mini with Apple Silicon (M4)**. It focuses on an install that’s **always-on**, reasonably **secure by default**, and easy to maintain.

---

## What you’re installing (mental model)

OpenClaw is a **self-hosted “Gateway”** that connects your chat surfaces (WhatsApp, Telegram, Discord, iMessage, etc.) to one or more AI agents. You manage it with the `openclaw` CLI and (optionally) a **native macOS menu bar app** that owns macOS permissions and exposes macOS-only capabilities. ([GitHub][1])

Key components:

* **Gateway**: always-on process; serves WebSocket + Control UI (default port **18789**) ([OpenClaw][2])
* **Control UI (“dashboard”)**: browser UI served from the same port ([OpenClaw][3])
* **macOS companion app (optional)**: menu bar UI, permission prompts, exec approvals, Canvas, etc. ([OpenClaw][4])
* **Onboarding wizard**: guided setup that configures gateway + model + channels ([OpenClaw][5])

---

## Choose your install approach

### Option A — Recommended: **Sandboxed macOS VM on your Mac mini (Lume)**

Use this if you want **strong isolation** from your daily host macOS, or you want “resettable” OpenClaw environments (clone/throw away). OpenClaw docs explicitly recommend macOS VMs for isolation and macOS-only capabilities. ([OpenClaw][6])

### Option B — Direct install on the Mac mini host

Fastest path, fewer moving parts. Use this if your Mac mini is already a dedicated “home server” and you’re comfortable hardening permissions and access.

I’ll cover both.

---

## Security notes you should read first (seriously)

OpenClaw is designed to **take actions** and can interact with files, credentials, and your messaging accounts. Recent reporting has highlighted risks around running agent runtimes on personal workstations and around malicious/unsafe extensions (“skills”). ([TechRadar][7])

Minimum recommended safety posture for a home Mac mini:

* Keep the Gateway **bound to loopback** unless you intentionally set up secure remote access. ([OpenClaw][8])
* Use **DM pairing / allowlists** so random people can’t message your agent. ([OpenClaw][9])
* Be extremely conservative with third-party **skills** (treat like running code from the internet). ([The Verge][10])
* Prefer running OpenClaw in a **VM** (Option A) if you’ll grant broad macOS permissions (Accessibility/Screen Recording/etc.). ([OpenClaw][6])

---

## Prerequisites (both options)

* **Node.js 22+** is required. ([GitHub][1])
* A model provider credential (API key or OAuth), configured in onboarding. ([OpenClaw][5])
* (Optional) **Docker** if you plan to use sandboxing features that rely on it (doctor will warn you if enabled but unavailable). ([OpenClaw][11])

---

# Option A: Install OpenClaw inside a sandboxed macOS VM (Lume) on Apple Silicon

This is the most “defensive” approach on a Mac mini that you care about.

## A1) Host requirements

According to the OpenClaw macOS VM guide:

* Apple Silicon Mac (M1/M2/M3/**M4**)
* Host macOS: **Sequoia or later**
* ~**60 GB free disk per VM** ([OpenClaw][6])

## A2) Install Lume on the Mac mini host

Run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
```

If `~/.local/bin` isn’t on your PATH:

```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

Verify:

```bash
lume --version
```

These steps match the OpenClaw macOS VM (Lume) instructions. ([OpenClaw][6])

## A3) Create the macOS VM

```bash
lume create openclaw --os macos --ipsw latest
```

Lume will download macOS and create the VM. ([OpenClaw][6])

## A4) Complete Setup Assistant + enable SSH (inside the VM)

In the VM’s UI:

1. Complete setup (create a user you’ll remember).
2. Enable **Remote Login (SSH)**:

   * System Settings → General → Sharing → enable “Remote Login” ([OpenClaw][6])

## A5) Get the VM IP and SSH in (from the host)

```bash
lume get openclaw
```

Then:

```bash
ssh youruser@192.168.64.X
```

(Replace with your VM username and the VM IP.) ([OpenClaw][6])

## A6) Install OpenClaw in the VM

Inside the VM:

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

This is the official recommended CLI onboarding flow (install + wizard + daemon). ([OpenClaw][6])

## A7) Access the Control UI from your Mac mini host (easy way)

The Control UI is served from the Gateway port (default **18789**). ([OpenClaw][12])

Because your Gateway is inside the VM, the cleanest approach is an SSH tunnel **from the host to the VM**:

On the Mac mini host (in a new Terminal tab):

```bash
ssh -N -L 18789:127.0.0.1:18789 youruser@192.168.64.X
```

Then open in your host browser:

* `http://127.0.0.1:18789/` ([OpenClaw][3])

## A8) Run the VM headless (so it’s always-on)

From the host:

```bash
lume run openclaw --no-display
```

This is the documented headless run mode. ([OpenClaw][6])

---

# Option B: Install OpenClaw directly on the Mac mini host (Apple Silicon)

## B1) Install OpenClaw (recommended installer script)

OpenClaw docs state the **installer script is the recommended way** because it handles Node detection/installation and launches onboarding. ([OpenClaw][13])

Run:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

That should leave you with a working `openclaw` CLI and guide you through setup. ([OpenClaw][13])

## B2) If you prefer manual install (npm / pnpm)

You can also install directly via npm/pnpm once Node 22+ is present:

```bash
npm install -g openclaw@latest
# or:
pnpm add -g openclaw@latest
```

Then run:

```bash
openclaw onboard --install-daemon
```

The `--install-daemon` path is the standard “keep it running” option. ([GitHub][1])

## B3) Verify the Gateway is running

If you installed the service, it should already be running:

```bash
openclaw gateway status
```

Open the Control UI:

```bash
openclaw dashboard
```

These checks are part of the Getting Started flow. ([OpenClaw][3])

---

# Optional (but very useful): Install the macOS companion app

## What the macOS app does

The OpenClaw macOS app is a **menu-bar companion** that:

* shows status/notifications
* owns macOS permission prompts (Notifications, Accessibility, Screen Recording, Microphone, Speech Recognition, Automation/AppleScript)
* runs locally or connects to a remote Gateway
* exposes macOS-only capabilities and manages exec approvals ([OpenClaw][4])

Important: **the macOS app does not bundle the Gateway runtime anymore**. It expects an external `openclaw` CLI install and manages/attaches to a launchd service. ([OpenClaw][14])

## How to get it

Common approaches:

* Download from the official project release artifacts (GitHub releases), or
* Build it from source (developer workflow below). ([OpenClaw][15])

## Developer build (from source)

Prereqs per docs:

* **Xcode 26.2+**
* Node.js 22+ and **pnpm** ([OpenClaw][15])

Build + package:

```bash
./scripts/package-mac-app.sh
```

It will output `dist/OpenClaw.app`. ([OpenClaw][15])

## macOS permissions stability tip (important)

macOS permission grants (TCC) are tied to **signature + bundle id + on-disk path**. If you move the app or rebuild it differently, macOS may treat it like a new app and drop/hide prompts. Keep it in a stable location (like `dist/OpenClaw.app` or `/Applications/OpenClaw.app`). ([OpenClaw][16])

---

# Day-2 operations (running it like a server)

## Core “is it healthy?” command ladder

OpenClaw’s troubleshooting docs recommend running these in order:

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

Expected healthy signals are documented (gateway running + RPC probe ok, doctor clean, channels connected/ready). ([OpenClaw][17])

## Starting / stopping the Gateway service

You can manage the service via CLI:

```bash
openclaw gateway install
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
```

These commands are part of the CLI surface. ([OpenClaw][18])

If you’re using the macOS app, it manages a per-user LaunchAgent like `ai.openclaw.gateway`. ([OpenClaw][4])

## Remote access (don’t expose the port publicly)

The Gateway generally binds to loopback by default; for remote use, OpenClaw’s remote access docs recommend SSH tunneling / tailnet approaches rather than exposing the port. ([OpenClaw][8])

Example SSH tunnel (from your laptop to your Mac mini at home):

```bash
ssh -N -L 18789:127.0.0.1:18789 youruser@your-mac-mini
```

Then browse locally at `http://127.0.0.1:18789/`. ([OpenClaw][8])

## Updating

OpenClaw changes quickly; the docs recommend re-running the installer, and update tooling runs `openclaw doctor` as a safety check. ([OpenClaw][19])

Recommended upgrade:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw doctor
```

---

# Hardening checklist (highly recommended)

## 1) DM pairing (control who can message your bot)

OpenClaw supports DM pairing: unknown senders receive a short code and **their message is not processed until you approve**. Pairing codes are 8 chars and expire after 1 hour. ([OpenClaw][9])

Useful commands:

```bash
openclaw pairing list --channel telegram
openclaw pairing approve --channel telegram <CODE>
```

CLI pairing syntax is documented. ([OpenClaw][20])

## 2) Exec approvals for macOS command execution

The macOS app controls `system.run` through an approvals policy stored at:

* `~/.openclaw/exec-approvals.json` ([OpenClaw][4])

Default approach you should aim for:

* deny by default, ask on misses, allowlist safe binaries.

The docs also note shell control syntax (`&&`, `|`, redirects, etc.) is treated as an allowlist miss and requires explicit approval unless you allowlist the shell itself. ([OpenClaw][4])

## 3) Don’t leave secrets lying around

OpenClaw has evolving secrets/auth patterns; stick to the official onboarding/auth flows and periodically audit. ([OpenClaw][21])

## 4) Be cautious with skills/extensions

There has been reporting on malicious OpenClaw skills in the wild; treat third-party skills as potentially hostile and prefer audited/known-good ones. ([The Verge][10])

---

# Troubleshooting (common issues)

## Node version mismatch

OpenClaw requires Node 22+. The install script can handle Node detection/installation; otherwise upgrade Node and rerun install/onboard. ([OpenClaw][13])

## “Gateway not running” / dashboard won’t load

Run:

```bash
openclaw gateway status
openclaw logs --follow
openclaw doctor
```

This is the official “get unstuck” flow. ([OpenClaw][22])

## Port already in use (EADDRINUSE)

The Gateway runbook calls out port conflicts and provides `--force` and other operator controls. ([OpenClaw][2])

## “Unauthorized” that won’t go away on macOS

`openclaw doctor` notes that **launchctl environment overrides** (like `OPENCLAW_GATEWAY_TOKEN`) can override config file values and cause persistent auth issues. ([OpenClaw][11])

Run doctor, and check/unset the env overrides if needed.

## macOS permissions prompts missing / flaky

macOS permission grants are fragile across changes in signature, bundle id, and app path—keep the app in a stable location and avoid moving/rebuilding it casually. ([OpenClaw][16])

---

# Appendix: Important paths & environment variables

## Default state/config locations

* OpenClaw state is typically under `~/.openclaw/…`
* Exec approvals: `~/.openclaw/exec-approvals.json` ([OpenClaw][4])

## Useful environment variables

If you need custom paths (service accounts, multiple instances, etc.):

* `OPENCLAW_HOME`
* `OPENCLAW_STATE_DIR`
* `OPENCLAW_CONFIG_PATH` ([OpenClaw][3])

---

## Recent security reporting worth skimming

* [TechRadar](https://www.techradar.com/pro/security/microsoft-says-openclaw-is-unsuited-to-run-on-standard-personal-or-enterprise-workstation-so-should-you-be-worried?utm_source=chatgpt.com)
* [The Verge](https://www.theverge.com/news/874011/openclaw-ai-skill-clawhub-extensions-security-nightmare?utm_source=chatgpt.com)
* [Business Insider](https://www.businessinsider.com/meta-ai-alignment-director-openclaw-email-deletion-2026-2?utm_source=chatgpt.com)
* [wired.com](https://www.wired.com/story/openclaw-users-bypass-anti-bot-systems-cloudflare-scrapling?utm_source=chatgpt.com)

[1]: https://github.com/openclaw/openclaw "GitHub - openclaw/openclaw: Your own personal AI assistant. Any OS. Any Platform. The lobster way. "
[2]: https://docs.openclaw.ai/gateway?utm_source=chatgpt.com "Gateway Runbook - OpenClaw"
[3]: https://docs.openclaw.ai/start/getting-started?utm_source=chatgpt.com "Getting Started - OpenClaw"
[4]: https://docs.openclaw.ai/platforms/macos "macOS App - OpenClaw"
[5]: https://docs.openclaw.ai/start/wizard?utm_source=chatgpt.com "Onboarding Wizard (CLI) - OpenClaw"
[6]: https://docs.openclaw.ai/install/macos-vm "macOS VMs - OpenClaw"
[7]: https://www.techradar.com/pro/security/microsoft-says-openclaw-is-unsuited-to-run-on-standard-personal-or-enterprise-workstation-so-should-you-be-worried?utm_source=chatgpt.com "Microsoft says OpenClaw is \"not appropriate to run on a standard personal or enterprise workstation\" - so should you be worried?"
[8]: https://docs.openclaw.ai/gateway/remote?utm_source=chatgpt.com "Remote Access - OpenClaw"
[9]: https://docs.openclaw.ai/channels/pairing?utm_source=chatgpt.com "Pairing - docs.openclaw.ai"
[10]: https://www.theverge.com/news/874011/openclaw-ai-skill-clawhub-extensions-security-nightmare?utm_source=chatgpt.com "OpenClaw's AI 'skill' extensions are a security nightmare"
[11]: https://docs.openclaw.ai/cli/doctor?utm_source=chatgpt.com "doctor - OpenClaw"
[12]: https://docs.openclaw.ai/web?utm_source=chatgpt.com "Web - OpenClaw"
[13]: https://docs.openclaw.ai/install?utm_source=chatgpt.com "Install - OpenClaw"
[14]: https://docs.openclaw.ai/platforms/mac/bundled-gateway?utm_source=chatgpt.com "Gateway on macOS - OpenClaw"
[15]: https://docs.openclaw.ai/platforms/mac/dev-setup "macOS Dev Setup - OpenClaw"
[16]: https://docs.openclaw.ai/platforms/mac/permissions?utm_source=chatgpt.com "macOS Permissions - OpenClaw"
[17]: https://docs.openclaw.ai/gateway/troubleshooting?utm_source=chatgpt.com "Troubleshooting - OpenClaw"
[18]: https://docs.openclaw.ai/cli?utm_source=chatgpt.com "CLI Reference - OpenClaw"
[19]: https://docs.openclaw.ai/install/updating?utm_source=chatgpt.com "Updating - OpenClaw"
[20]: https://docs.openclaw.ai/cli/pairing?utm_source=chatgpt.com "pairing - OpenClaw"
[21]: https://docs.openclaw.ai/gateway/authentication?utm_source=chatgpt.com "Authentication - OpenClaw"
[22]: https://docs.openclaw.ai/help/troubleshooting?utm_source=chatgpt.com "Troubleshooting - OpenClaw"
