#!/usr/bin/env bash
set -euo pipefail

ms=""
in=""
out=""
force=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") --ms <milliseconds> --file <input.mp4> --out <output.mp4> [--force]

Creates a slideshow MP4 by sampling 1 video frame every <milliseconds> (t=0, t+=ms, ...).
Audio is kept unchanged.

Examples:
  $(basename "$0") --ms 250 --file temp.mp4 --out slideshow_250ms.mp4
  $(basename "$0") --ms 3000 --file big_buck_bunny.mp4 --out slideshow.mp4
USAGE
}

if [[ ${#@} -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --ms)
      [[ $# -ge 2 ]] || { echo "Error: --ms requires a value" >&2; exit 2; }
      ms="$2"
      shift 2
      ;;
    --file)
      [[ $# -ge 2 ]] || { echo "Error: --file requires a value" >&2; exit 2; }
      in="$2"
      shift 2
      ;;
    --out|--output)
      [[ $# -ge 2 ]] || { echo "Error: --out requires a value" >&2; exit 2; }
      out="$2"
      shift 2
      ;;
    --force)
      force=1
      shift 1
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: missing dependency: $1" >&2; exit 5; }
}

need_cmd ffmpeg
need_cmd ffprobe

# Ensure ffmpeg has the encoder we rely on (avoid pipefail/SIGPIPE by capturing output).
encoders_out=$(ffmpeg -hide_banner -encoders 2>/dev/null || true)
if ! grep -q ' libx264 ' <<<"$encoders_out"; then
  echo "Error: ffmpeg is missing the libx264 encoder" >&2
  exit 5
fi

if [[ -z "$ms" || -z "$in" || -z "$out" ]]; then
  echo "Error: required flags: --ms, --file, --out" >&2
  usage >&2
  exit 2
fi

if ! [[ "$ms" =~ ^[0-9]+$ ]] || [[ "$ms" -le 0 ]]; then
  echo "Error: --ms must be a positive integer; got '$ms'" >&2
  exit 2
fi

if [[ ! -f "$in" ]]; then
  echo "Error: input not found: $in" >&2
  exit 3
fi

# Quick sanity check that the input has a video stream.
if ! ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$in" | grep -q '^video$'; then
  echo "Error: input has no video stream: $in" >&2
  exit 3
fi

if [[ -e "$out" && "$force" -ne 1 ]]; then
  echo "Error: output already exists: $out (use --force to overwrite)" >&2
  exit 4
fi

out_dir=$(dirname -- "$out")
if [[ ! -d "$out_dir" ]]; then
  echo "Error: output directory does not exist: $out_dir" >&2
  exit 4
fi
if [[ ! -w "$out_dir" ]]; then
  echo "Error: output directory not writable: $out_dir" >&2
  exit 4
fi

fps_expr="1000/${ms}"

# Slideshow by time-sampling: take 1 frame every <ms> milliseconds (t=0, t+=ms, ...).
# This keeps overall duration ~the same as the input (so audio can remain unchanged).
ffmpeg_overwrite_args=()
if [[ "$force" -eq 1 ]]; then
  ffmpeg_overwrite_args=(-y)
fi

ffmpeg -hide_banner -loglevel error \
  "${ffmpeg_overwrite_args[@]}" \
  -i "$in" \
  -map 0:v:0 -map 0:a? \
  -vf "fps=${fps_expr}" \
  -vsync cfr -r "$fps_expr" \
  -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p \
  -c:a copy -shortest \
  -movflags +faststart \
  "$out"

echo "Wrote: $out"
