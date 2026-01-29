# slideshow-maker

Converts videos in `in/` to slideshow versions in `out/` using `bin/slideshow.sh`.

## Local usage
```bash
bin/slideshow.sh --ms 3000 --file in/input.mp4 --out out/input.mp4
```

## GitHub Actions
On push to `master`, the workflow converts every file in `in/` into `out/` (same filename). The milliseconds value is controlled by the `SLIDESHOW_MS` repository variable (or workflow env).
