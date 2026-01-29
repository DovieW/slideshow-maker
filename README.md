# slideshow-maker

Converts videos in `in/` to slideshow versions in `out/` using `bin/slideshow.sh`.

## Local usage
```bash
bin/slideshow.sh --ms 3000 --file in/input.mp4 --out out/input.mp4
```

## GitHub Actions
On push to `master`, the workflow converts every file in `in/` into `out/` (same filename).

Set the milliseconds value as a **repository variable**:
- Settings → Secrets and variables → Actions → **Variables** → New repository variable
- Name: `SLIDESHOW_MS`
- Value: e.g. `3000`
