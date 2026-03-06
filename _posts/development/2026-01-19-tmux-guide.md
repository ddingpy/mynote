---
title: "tmux: A Comprehensive Guide"
date: 2026-01-19 23:18:00 +0900
tags: [tmux, terminal, cli, productivity]
---


**tmux** (terminal multiplexer) lets you run multiple terminal sessions inside a single window. You can split windows into panes, detach and reattach sessions, and keep programs running even after disconnecting from SSH.

This guide covers tmux from beginner to advanced usage.

---

## Table of Contents

1. What is tmux?
2. Installing tmux
3. Core Concepts
4. Starting and Exiting tmux
5. Sessions
6. Windows
7. Panes
8. The Prefix Key
9. Copy Mode & Scrollback
10. Customizing tmux (`.tmux.conf`)
11. Mouse Support
12. tmux + SSH Workflow
13. Useful Key Bindings Cheat Sheet
14. Troubleshooting & Tips
15. Further Resources

---

## 1. What is tmux?

`tmux` is a terminal multiplexer that allows you to:

* Run multiple shells in one terminal
* Split the terminal into panes
* Detach sessions and reattach later
* Persist long-running tasks

Common use cases:

* Remote server work
* Long-running builds or training jobs
* Managing multiple terminals efficiently

---

## 2. Installing tmux

### Linux (Debian/Ubuntu)

```bash
sudo apt install tmux
```

### Linux (RHEL/CentOS)

```bash
sudo yum install tmux
```

### macOS (Homebrew)

```bash
brew install tmux
```

### Verify Installation

```bash
tmux -V
```

---

## 3. Core Concepts

tmux has a simple hierarchy:

* **Server** → runs in background
* **Session** → collection of windows
* **Window** → like a tab
* **Pane** → split within a window

```
Session
 ├── Window 1
 │    ├── Pane A
 │    └── Pane B
 └── Window 2
      └── Pane A
```

---

## 4. Starting and Exiting tmux

### Start a New Session

```bash
tmux
```

### Start with a Name

```bash
tmux new -s mysession
```

### Detach from a Session

Press:

```
Ctrl-b d
```

### Exit tmux

* Type `exit` in all panes
* Or kill the session explicitly

```bash
tmux kill-session -t mysession
```

---

## 5. Sessions

### List Sessions

```bash
tmux ls
```

### Attach to a Session

```bash
tmux attach -t mysession
```

### Rename a Session

```
Ctrl-b $
```

### Switch Between Sessions

```bash
tmux switch -t mysession
```

---

## 6. Windows

### Create a New Window

```
Ctrl-b c
```

### List Windows

```
Ctrl-b w
```

### Switch Windows

* Next: `Ctrl-b n`
* Previous: `Ctrl-b p`
* By number: `Ctrl-b 0–9`

### Rename Window

```
Ctrl-b ,
```

### Close Window

```
Ctrl-b &
```

---

## 7. Panes

### Split Panes

* Vertical split:

```
Ctrl-b %
```

* Horizontal split:

```
Ctrl-b "
```

### Move Between Panes

```
Ctrl-b ↑ ↓ ← →
```

### Resize Panes

Hold prefix, then:

```
Ctrl-b Ctrl-Arrow
```

### Close a Pane

Type `exit` or:

```
Ctrl-b x
```

---

## 8. The Prefix Key

By default, tmux uses:

```
Ctrl-b
```

You press the prefix **before** any tmux command.

Example:

```
Ctrl-b c   # create new window
Ctrl-b %   # split pane vertically
```

---

## 9. Copy Mode & Scrollback

### Enter Copy Mode

```
Ctrl-b [
```

### Navigation (vi-style by default)

* Move: `h j k l`
* Page up/down: `Ctrl-u / Ctrl-d`
* Search: `/`

### Copy Text

1. Enter copy mode
2. Press `Space` to start selection
3. Move cursor
4. Press `Enter` to copy

### Paste

```
Ctrl-b ]
```

---

## 10. Customizing tmux (`.tmux.conf`)

Create or edit:

```bash
~/.tmux.conf
```

### Common Customizations

#### Change Prefix to Ctrl-a

```tmux
set -g prefix C-a
unbind C-b
bind C-a send-prefix
```

#### Enable Vi Mode

```tmux
setw -g mode-keys vi
```

#### Faster Key Response

```tmux
set -s escape-time 0
```

#### Reload Config

```tmux
bind r source-file ~/.tmux.conf \; display "Reloaded!"
```

Then:

```
Ctrl-b r
```

---

## 11. Mouse Support

Enable mouse support:

```tmux
set -g mouse on
```

This allows:

* Clicking panes
* Resizing panes
* Scrolling

---

## 12. tmux + SSH Workflow

A very common pattern:

1. SSH into server
2. Start tmux
3. Run long tasks
4. Detach
5. Disconnect SSH
6. Reconnect later and reattach

```bash
ssh user@server
tmux attach -t work
```

This prevents job loss on disconnect.

---

## 13. Useful Key Bindings Cheat Sheet

| Action           | Key                |
| ---------------- | ------------------ |
| New session      | `tmux new -s name` |
| Detach           | `Ctrl-b d`         |
| New window       | `Ctrl-b c`         |
| Split vertical   | `Ctrl-b %`         |
| Split horizontal | `Ctrl-b "`         |
| Switch panes     | `Ctrl-b arrows`    |
| Copy mode        | `Ctrl-b [`         |
| Paste            | `Ctrl-b ]`         |
| Rename window    | `Ctrl-b ,`         |
| Kill pane        | `Ctrl-b x`         |

---

## 14. Troubleshooting & Tips

### tmux Feels Laggy

```tmux
set -s escape-time 0
```

### Colors Look Wrong

Ensure:

```bash
export TERM=xterm-256color
```

And in tmux:

```tmux
set -g default-terminal "screen-256color"
```

### Nested tmux Sessions

Use:

```bash
tmux attach -t session
```

Instead of starting tmux inside tmux.

---

## 15. Further Resources

* `man tmux`
* [https://github.com/tmux/tmux](https://github.com/tmux/tmux)
* [https://github.com/tmux-plugins](https://github.com/tmux-plugins)
* [https://wiki.archlinux.org/title/tmux](https://wiki.archlinux.org/title/tmux)

---

## Final Notes

tmux is one of those tools that feels awkward at first, then becomes indispensable. Learn a few commands, customize gradually, and let muscle memory do the rest.

Happy multiplexing 🚀
