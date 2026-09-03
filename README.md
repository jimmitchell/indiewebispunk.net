# The IndieWeb Is Punk Manifesto

> [!NOTE]
> Some have questioned the fact that Claude is listed as a contributor to this repo and it's a fair question. The simple answer is that I used Claude to initialize and push the repo to Github, nothing more. To me a tool is a tool. Judge me how you like, though I would encourage you to review this issue thread (which will remain open): https://github.com/jimmitchell/indiewebispunk.net/issues/1

## Three chords and a domain name.

Live at **[indiewebispunk.net](https://indiewebispunk.net/)**.

One hand-written HTML file. No build step, no framework, no bundler, no
package manager, no trackers, no analytics, no cookies, and no fonts from
anybody else's server. If that sounds like a constraint, read the manifesto.

## What's in here

| Path | |
|---|---|
| `index.html` | The whole site — markup, styles and script in one file |
| `indieweb-is-punk-manifesto.md` | The manifesto as plain Markdown, served at `/` and linked from the page |
| `fonts/` | Courier Prime, self-hosted (see [Fonts](#fonts)) |
| `indieweb-is-punk.png` | The header logo, background flood-filled to transparency |
| `IndieWeb.png` | Original source art, kept for reference — not served |
| `og-image.png` | 1200×630 social card |
| `favicon.ico`, `icon-*.png`, `apple-touch-icon.png` | Icons, cut from the magenta "P" |
| `deploy/` | nginx server block, security-headers snippet, traffic.sh — not served |

## Running it locally

```bash
python3 -m http.server 8000
```

That's the entire toolchain. Open <http://localhost:8000>.

Note that the "Copy the manifesto" buttons need a secure context, so they
stay inert over plain `http://` and only work once it's on HTTPS.

## Deploying

nginx on a Hetzner box, alongside [jimmitchell.org](https://jimmitchell.org).
The web root *is* this repo, so deploying is:

```bash
git pull
```

`deploy/` holds the nginx server block, the security-headers snippet, and
`traffic.sh`. All of it gets denied by nginx along with `.git`, since it lives
inside the web root but isn't part of the site.

Since nothing here tracks visitors, traffic means reading the access log.
The server block writes its own — `/var/log/nginx/indiewebispunk.net.access.log`,
kept separate from jimmitchell.org's on the same box — and `deploy/traffic.sh`
summarises the last N days of it:

```bash
sudo sh deploy/traffic.sh 7
```

Per day: requests, human vs bot, unique IPs, pageviews. Then top pages,
external referrers, and user agents. It reads rotated and gzipped logs too, so
N can reach back past today's file.

## Fonts

[Courier Prime](https://quoteunquoteapps.com/courierprime/), self-hosted as
four woff2 files (~49 KB total), latin subset. Licensed under the
[SIL Open Font License 1.1](fonts/OFL.txt), which permits redistribution.

Self-hosted rather than pulled from a font CDN, because a page whose footer
says "no fonts from anybody else's server" ought to mean it.

## Microformats

The page is marked up as an [h-entry](https://microformats.org/wiki/h-entry)
with `p-name`, `p-summary`, `e-content`, `dt-published`, `u-url` and a nested
`p-author h-card`. The title is carried by the logo's `alt` text, so the
image *is* the `p-name` rather than duplicating it in a hidden element.

## Credits

Inspired by Jamie Thingelstad's original
"[IndieWeb is Punk](https://www.thingelstad.com/2025/06/19/indieweb-is-punk.html)"
post, Jim Mitchell's
[response and t-shirt tribute](https://jimmitchell.org/2025/06/19/indieweb-is-punk/),
and the IndieWeb community's guiding principles at
[indieweb.org/principles](https://indieweb.org/principles).

There's [a shirt](https://cottonbureau.com/p/ZX5246/shirt/indieweb-is-punk-black)
and [a sticker](https://cottonbureau.com/p/2JSSYE/sticker/indieweb-is-punk-the-sticker).

## License

[MIT](LICENSE) © 2026 Jim Mitchell. Take it, fork it, put it on your own site.

One carve-out: the bundled fonts are **not** covered by the MIT grant.
Courier Prime is licensed separately under the
[SIL Open Font License 1.1](fonts/OFL.txt) and stays under the OFL wherever
it travels — including in forks of this repo.
