# Repository Guidelines

## Project Structure & Module Organization
This repository is a GitHub Pages-compatible Jekyll blog.
- `_posts/`: article source files grouped by category (`_posts/<category>/YYYY-MM-DD-slug.md`).
- `_layouts/`: Liquid templates (`default`, `post`, `category`, `search`).
- `categories/` and root `*.md` pages: landing pages and navigation content.
- `assets/css/` and `assets/js/`: site styling and client-side behavior (including search).
- `scripts/`: local runtime helpers (`dev-server.sh`, `static-server.js`).
- `_config.yml`: global site configuration and permalink rules.

## Build, Test, and Development Commands
- `docker compose up --build`: build image and run local blog at `http://localhost:4000`.
- `docker compose down`: stop and remove local containers.
- `docker compose logs -f blog`: follow local build/server logs.
- `docker compose run --rm blog jekyll build`: run a one-off production-style build (good pre-PR check).

## Coding Style & Naming Conventions
- Use Markdown with YAML front matter for all posts/pages.
- Post filenames must follow `YYYY-MM-DD-slug.md`; keep slug lowercase and hyphenated.
- Keep one category per post by placing it in the matching `_posts/<category>/` folder.
- Follow existing style in frontend assets: 2-space indentation, `const`/`let`, and semicolons in JS.
- Prefer descriptive, stable page names (for example, `categories/devops.md`).

## Testing Guidelines
There is no formal unit-test suite in this repository. Validate changes with build and smoke tests:
- Run `docker compose run --rm blog jekyll build` and confirm it exits successfully.
- Start local server and verify changed pages render correctly.
- If search-related files changed, verify `/search/` returns expected results for known post keywords.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit pattern seen in history: `feat(blog): ...`, `docs(blog): ...`.
- Keep commit messages imperative and scoped when useful (`feat(layout): improve breadcrumb spacing`).
- PRs should include: concise summary, key files changed, manual verification steps, and screenshots for UI/layout updates.
- Do not commit generated `_site/` output or cache directories.

## Configuration Notes
Before deploying, set `_config.yml` values for `url` and `baseurl` to match the target GitHub Pages site.
