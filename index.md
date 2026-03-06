---
layout: default
title: Home
---
# Latest Posts

Welcome to my blog. I share technical articles, tutorials, and practical tips.

{% if site.posts.size > 0 %}
{% for post in site.posts %}
## [{{ post.title }}]({{ post.url | relative_url }})

- Date: {{ post.date | date: "%Y-%m-%d" }}
{% assign post_path_parts = post.path | split: '/' %}
{% assign post_category = post_path_parts[1] %}
{% if post_category %}
{% assign post_category_slug = post_category | slugify %}
- Category: [{{ post_category }}]({{ '/categories/#' | append: post_category_slug | relative_url }})
{% endif %}
{% if post.tags.size > 0 %}
- Tags: {{ post.tags | join: ", " }}
{% endif %}

{{ post.excerpt | strip_html | truncate: 180 }}

---
{% endfor %}
{% else %}
No posts yet. Add markdown files under `_posts/` to publish articles.
{% endif %}
