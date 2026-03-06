---
layout: default
title: Journal
permalink: /journal/
---
# Journal

This is your dedicated space for journal entries, sketches, ideas, and story notes.

## Journal Space

Use this page as a calm index for your journal work. Keep entries small and consistent.

- What did I draw or imagine today?
- What character or scene felt strongest?
- What should I improve in the next session?

## Entries

{% assign journal_posts = site.posts | where_exp: "p", "p.path contains '_posts/journal/'" %}

{% if journal_posts and journal_posts.size > 0 %}
{% for post in journal_posts %}
### [{{ post.title }}]({{ post.url | relative_url }})

- Date: {{ post.date | date: "%Y-%m-%d" }}
{% if post.tags.size > 0 %}
- Tags: {{ post.tags | join: ", " }}
{% endif %}

{{ post.excerpt | strip_html | truncate: 180 }}

{% endfor %}
{% else %}
No journal entries yet. Add one in `_posts/journal/`.
{% endif %}
