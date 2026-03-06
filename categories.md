---
layout: default
title: Categories
permalink: /categories/
---
# Categories

Browse posts by topic.

{% capture category_csv %}{% for post in site.posts %}{% assign post_path_parts = post.path | split: '/' %}{% assign category_name = post_path_parts[1] %}{% if category_name and category_name != "" %}|{{ category_name }}{% endif %}{% endfor %}{% endcapture %}
{% assign category_list = category_csv | split: '|' | uniq | sort %}

## Category Index

{% for category_name in category_list %}
{% if category_name != "" %}
{% assign category_prefix = '_posts/' | append: category_name | append: '/' %}
{% assign posts = site.posts | where_exp: "p", "p.path contains category_prefix" %}
- [{{ category_name }}](#{{ category_name | slugify }}) ({{ posts | size }})
{% endif %}
{% endfor %}

{% for category_name in category_list %}
{% if category_name != "" %}
{% assign category_prefix = '_posts/' | append: category_name | append: '/' %}
{% assign posts = site.posts | where_exp: "p", "p.path contains category_prefix" %}
## {{ category_name }}

{% for post in posts %}
- [{{ post.title }}]({{ post.url | relative_url }}) - {{ post.date | date: "%Y-%m-%d" }}{% if post.tags.size > 0 %} - Tags: {{ post.tags | join: ", " }}{% endif %}
{% endfor %}

{% endif %}
{% endfor %}
