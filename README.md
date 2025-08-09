# Gurjot Portfolio (Static, GitHub Pages-ready)

This is a simple, fast, single-page portfolio you can upload directly to GitHub Pages.

## Quick Start
1) Create a new GitHub repo (or use `gurjotmann.github.io`).
2) Upload **all files** from this folder to the repo root.
3) Turn on **Settings → Pages → Deploy from a branch** (main, root).
4) Visit your site, then wire up your custom domain in **Pages → Custom domain**.

## Customize
- Edit **index.html** hero text, email, and social links.
- Update **data/experience.json** and **data/projects.json** with your details.
- Colors: tweak CSS variables at the top of **styles.css**.
- Optional LinkedIn badge: in `index.html`, search for `LinkedIn Profile Badge` and follow the comment.

## LinkedIn Data (manual, safe)
1) Download your data from LinkedIn (Settings & Privacy → Data privacy → Get a copy of your data).
2) Copy your job history into **data/experience.json** and projects into **data/projects.json**.
3) Commit the changes; the site will read them automatically.

## Extras
- `404.html` added for GitHub Pages.
- `.nojekyll` included.
