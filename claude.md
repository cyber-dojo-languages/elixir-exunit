# elixir-exunit session notes

## Repo relationships

This repo (`cyber-dojo-languages/elixir-exunit`) builds the Docker image.
The start-point files (source, tests, manifest) live in the partner repo:
`../../cyber-dojo-start-points/elixir-exunit`

Development loop:
1. Edit `docker/Dockerfile.base` here
2. Run `./pipe_build_up_test.sh` — builds image, prints new tag at the end
3. Update `image_name` in `../../cyber-dojo-start-points/elixir-exunit/start_point/manifest.json`
4. Edit start-point files in `../../cyber-dojo-start-points/elixir-exunit/start_point/`
5. Run `../../cyber-dojo-start-points/elixir-exunit/run_tests.sh` — verifies red/amber/green

**Important:** never run docker commands directly. Only test via `run_tests.sh`.
The runner containers have no internet access.

## What was done this session

### Problem
After upgrading the base image from `cyberdojofoundation/elixir:a5ab1a0` to
`ghcr.io/cyber-dojo-languages/elixir:69da6cc` (Elixir 1.19 / OTP 28), the
red/amber/green runs all timed out.

### Root cause 1 — outdated start-point files
The start-point files were written for Elixir ~1.2. Two breaking changes in
Elixir 1.18:
- `use Mix.Config` in `config/config.exs` was removed → replaced with `import Config`
- Old `mix.exs` format (separate `deps/0` function, deprecated keys) → modernised

### Root cause 2 — Mix overhead
`cyber-dojo.sh` was `mix test`. Mix adds ~1-2s overhead (startup, dep checking,
writing `_build/`). Replaced with:
```
elixir -r 'lib/**/*.ex' -r test/test_helper.exs -r 'test/**/*_test.exs'
```
This skips Mix entirely — in-memory compilation, no `_build/` I/O.
`mix.exs` and `config/config.exs` removed from `visible_filenames`.

### Root cause 3 — Alpine/musl startup time
Even with `elixir -e "IO.puts 'hello'"` (no compilation at all), startup takes
~5.5s. The entire duration is OTP VM boot. The base image uses `elixir:otp-28-alpine`
which has a musl-compiled BEAM. musl is slower than glibc for OTP's memory/threading
patterns.

Installing glibc on Alpine does NOT help — the BEAM binary itself is musl-compiled.
The fix is to switch the base to a Debian image in `cyber-dojo-languages/elixir`.

## Current state

- `docker/Dockerfile.base` — now uses `ghcr.io/cyber-dojo-languages/elixir:9aace7d` which is Debian based
- `start_point/cyber-dojo.sh` — `elixir -r 'lib/**/*.ex' -r test/test_helper.exs -r 'test/**/*_test.exs'`
- `start_point/mix.exs` — (removed)
- `start_point/config/config.exs` — `import Config` (removed)
- `start_point/manifest.json` — visible_filenames: `lib/hiker.ex`, `test/hiker_test.exs`,
  `test/test_helper.exs`, `cyber-dojo.sh`
