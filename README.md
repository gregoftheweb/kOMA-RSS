# kOMA RSS

A Plasma 6 panel widget that shows articles from all your RSS/Atom feeds as one
newest-first list. Each entry has a title, date, feed name, a short summary and a
picture when the feed provides one. Click an entry to open the article in your
default browser.

Add or remove feeds under right-click → **Configure kOMA RSS…**. The same page
sets how often feeds refresh (default 30 min), how many articles to keep
(default 100) and whether pictures are shown. The popup header has Refresh and
Configure buttons. Feeds that fail to load are listed in the header tooltip.

Pictures come from `media:thumbnail`/`media:content`, image enclosures,
`itunes:image`, or the first `<img>` in the article body. Only http(s) feeds
are fetched.

Requires Plasma 6 and Python 3 (standard library only).

```sh
bin/install             # install, link CLI, add to the first panel
bin/install --no-place  # install and link CLI only
komarss --max 20 https://example.com/feed.xml ...  # print combined articles as JSON
make check
make package           # build dist/com.columbiafoundry.komarss-0.4.0.plasmoid
```

Widget ID: `com.columbiafoundry.komarss`. Version: 0.4.0.
MIT © 2026 Columbia Foundry.
