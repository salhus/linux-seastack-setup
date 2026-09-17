# Toolchain environments — `~/env/`

Chrono and SEA-Stack are sourced per-shell, like a ROS distro. One flavor at a
time; switching cleans up after the previous one.

## Quick reference

| Command | What it gives you |
|---------|-------------------|
| `chrono10` | Chrono v10, **install** tree — the SEA-Stack-compatible ABI |
| `chrono-dev` | Personal dev branch (`project-chrono_sh`), **build** tree |
| `chrono-main` | Upstream main, rolling (`project-chrono`), **build** tree |
| `seastack` | SEA-Stack install tree — **requires `chrono10` first** |

```bash
chrono10 && seastack     # the normal working combo
```

Each prints a one-line confirmation. If you see nothing, something failed —
see Troubleshooting.

> **Verified 2026-09-17:** `chrono10`, `chrono-dev`, and `seastack` were tested
> in both directions, including a deliberate mismatch and recovery.
> `chrono-main` has not been exercised.

## Why this exists

Two failure modes, both of which link cleanly and then misbehave at runtime:

1. **Two Chrono copies on `LD_LIBRARY_PATH`.** The dynamic loader takes whichever
   comes first, which may not be the one you configured against.
2. **SEA-Stack paired with the wrong Chrono.** SEA-Stack is compiled against one
   Chrono ABI. A mismatched pairing links fine, loads fine, and then fails at
   dynamic symbol resolution:

   ```
   symbol lookup error: ./build/bin/Release/run_seastack:
   undefined symbol: _ZNK6chrono7parsers12ChParserYAML6OutputEv
   ```

   Note what happened there: the SONAME matched and the library *loaded*. The
   break only surfaced when a specific symbol was needed. You get a clean error
   only because that symbol is genuinely absent from the other build — had a
   same-named symbol existed with different semantics, the binary would have run
   and produced wrong numbers with no warning. **That** is the case these guards
   exist to prevent, and it is the one you would never catch by reading output.

Every flavor switch calls `_chrono_reset`, which strips all known Chrono
prefixes *and* clears SEA-Stack.

## Files

```
~/env/
├── _chrono_common.sh   # shared helpers — sourced by all four, not aliased
├── chrono10.sh         # chrono10
├── chrono-dev.sh       # chrono-dev
├── chrono-main.sh      # chrono-main
└── seastack.sh         # seastack
```

All five are **sourced, never executed** — they modify the current shell.

## Required `~/.bashrc` lines

The scripts do nothing on their own. `~/.bashrc` must define the aliases and set
up VSG:

```bash
# Vulkan Scene Graph SDK (Chrono-independent)
export CMAKE_PREFIX_PATH=$HOME/Packages/vsg:$CMAKE_PREFIX_PATH
export LD_LIBRARY_PATH=$HOME/Packages/vsg/lib:$LD_LIBRARY_PATH

# ── Toolchain environments — source one per shell (like a ROS distro) ────────
# Switching flavors clears the previous one; only one Chrono is ever active.
alias chrono-main='source ~/env/chrono-main.sh'   # upstream main, rolling
alias chrono-dev='source ~/env/chrono-dev.sh'     # personal dev branch
alias chrono10='source ~/env/chrono10.sh'         # v10 install — SEA-Stack ABI
alias seastack='source ~/env/seastack.sh'         # SEA-Stack (needs chrono10)
```

**VSG is global, not per-flavor.** It is Chrono-independent and shared by every
flavor, so it lives here rather than in any `~/env/` script, and `_chrono_reset`
does not touch it. That is why VSG survives flavor switches — and why a broken
VSG path breaks all flavors at once.

**Every alias uses `source`.** Running a script as a subprocess would change the
subprocess's environment and then discard it. If invoking by path, use
`source ~/env/chrono10.sh`.

After editing, `exec bash` (on its own line — see Troubleshooting) or open a new
shell. Verify with `type chrono10`, which should report an alias rather than
`not found`.

### `_chrono_common.sh` helpers

| Helper | Purpose |
|--------|---------|
| `_env_prepend VAR DIR` | Prepend `DIR` to `VAR` only if absent (no duplicates on re-source) |
| `_env_strip VAR SUBSTR` | Remove every entry in `VAR` containing `SUBSTR` |
| `_chrono_reset` | Clear the active Chrono flavor **and** SEA-Stack |
| `_chrono_report` | Print the one-line summary; warn if `Chrono_DIR` or the VSG font is missing |

## Behavior worth knowing

**Switching Chrono clears SEA-Stack**, with a visible note:

```
$ chrono10 && seastack
[chrono] v10 — /home/shusain/project-chrono_v10/install/lib/cmake/Chrono
[seastack] /home/shusain/SEA-Stack/install/lib/cmake/SEAStack

$ chrono-dev
[chrono] NOTE: clearing SEA-Stack env (was pinned to a different Chrono).
[chrono] dev — /home/shusain/project-chrono_sh/build/cmake
```

This is deliberate: `chrono-dev` invalidates the SEA-Stack you had loaded, so it
is removed rather than left to fail at runtime. Re-run `seastack` after returning
to `chrono10`.

**`seastack` without `chrono10` warns but proceeds:**

```
[seastack] WARN: CHRONO_FLAVOR='dev', expected 'v10'.
[seastack]       Run 'chrono10' first, or rebuild SEA-Stack against this Chrono.
```

Warn-and-proceed rather than refuse, because "rebuild SEA-Stack against this
Chrono" is a legitimate workflow. But be clear on what the warning does *not*
do: running `seastack` while `CHRONO_FLAVOR=dev` will not make an existing
v10-linked binary work. Linkage is fixed at build time; no amount of environment
fixes it. Only `chrono10` — or a rebuild — will.

**Flavor switching is genuinely isolating.** Verified by inspection:
`chrono-dev` leaves exactly one Chrono path on `LD_LIBRARY_PATH`, with no v10
remnant and no SEA-Stack. `chrono10` reverses it just as cleanly.

**Re-sourcing is safe.** `-march=native` is added to `CXXFLAGS` only once, and
path entries are never duplicated.

## Flavor layouts differ

`chrono10` points at an **install** tree; the other two point at **build** trees:

```
v10   → ~/project-chrono_v10/install/lib/cmake/Chrono
dev   → ~/project-chrono_sh/build/cmake
main  → ~/project-chrono/build/cmake
```

For the build flavors, the CMake package layout is not the same as an install
tree, and anything built against them is pinned to that build directory
continuing to exist. Fine for development; not something to build a release
against.

## Variables set

| Variable | Notes |
|----------|-------|
| `CHRONO_FLAVOR` | `v10` / `dev` / `main` — check this to see what's active |
| `Chrono_DIR` | Where `find_package(Chrono)` looks |
| `CHRONO_ROOT` | Install or build root |
| `CHRONO_DATA_DIR` | Chrono data folder |
| `VSG_FILE_PATH` | **Must be the data dir itself, not `data/vsg`** — VSG resolves `vsg/fonts/...` relative to this. One level too deep → segfault on frame 1. |
| `CXXFLAGS` | `-march=native` (v10 only) |
| `SEAStack_DIR`, `SEASTACK_ROOT`, `SEASTACK_SOURCE_DIR` | SEA-Stack only |

### The `-march=native` requirement (v10)

Chrono v10 exports `-march=native` to consumers, giving them
`EIGEN_MAX_ALIGN_BYTES=32`. Anything sharing Eigen objects with Chrono-linked
code **must match**, or Eigen allocates with `malloc` and frees with
`handmade_aligned_free` → heap-buffer-overflow. This surfaced via
`HydroData::GetInfAddedMassMatrix` crossing into `cpp-vgoswec`.

## Rebuild cascade

The stack is layered, and a rebuild at any level invalidates everything below it:

```
Chrono v10  →  SEA-Stack  →  { cpp-vgoswec, Marine_Robotics_HIL_SEA-Stack }
```

Rebuilding Chrono into the same prefix changes the ABI under every consumer, so
SEA-Stack must be rebuilt, then both downstream projects. Check ordering by
timestamp when in doubt:

```bash
ls -la ~/project-chrono_v10/install/lib/libChrono_core.so
ls -la ~/SEA-Stack/install/lib/libseastack_hydro.a
```

SEA-Stack's install should be **newer** than Chrono's. If it isn't, the cascade
is stale.

## Troubleshooting

**`symbol lookup error: ... undefined symbol: _ZNK6chrono...`**
The binary is paired with a Chrono it was not built against. Confirm with
`echo $CHRONO_FLAVOR`, then:
```bash
chrono10 && seastack
```
Running `seastack` *without* switching Chrono back does not help — see the note
under the mismatch warning above.

**No output at all from `chrono10`.**
The helper file failed to load and the script aborted. Check it exists with the
leading underscore:
```bash
ls ~/env/_chrono_common.sh
```

**`_chrono_reset: command not found`** (or `_env_prepend`).
Same cause. Note the damage pattern: plain `export` lines still run, so
`Chrono_DIR` looks correct while `LD_LIBRARY_PATH` is missing every Chrono
entry — a build in that shell half-works and fails confusingly. Fix the file,
then `exec bash`.

**`chrono10: command not found`.**
The aliases are missing from `~/.bashrc`, or it hasn't been re-sourced. See
Required `~/.bashrc` lines.

**Wrong flavor reported.**
A script may contain another's contents. Check the header:
```bash
head -3 ~/env/chrono-dev.sh
```

**Verify what's actually active:**
```bash
echo "$CHRONO_FLAVOR"
echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -iE 'chrono|seastack'
```
Expect exactly one Chrono path, matching the reported flavor.

**`exec bash` eats the rest of a pasted block.** It replaces the shell process,
so anything after it on the same paste is discarded. Run follow-up commands
separately.

## Per-project note: `cpp-vgoswec`

`chrono10 && seastack` alone is sufficient — configure, build, and run all
succeed without `scripts/setup_env.sh`. The same is true for
`Marine_Robotics_HIL_SEA-Stack` under colcon.

**Do not use both in one shell.** `setup_env.sh` sets the same variables
independently and does not call `_chrono_reset`, so `chrono-dev` followed by
`source scripts/setup_env.sh` can leave two Chrono installs on the path.

## Open questions

**`CH_USE_SIMD`.** Several older comments claimed SEA-Stack requires Chrono built
with `CH_USE_SIMD=OFF`. The current v10 build has **SIMD ON** with
`-march=native`, and the full stack — Chrono, SEA-Stack (226 targets),
`cpp-vgoswec`, and the HIL workspace — builds and runs. The comments now reflect
that. If the `OFF` requirement was ever real, this is wrong; confirm against
SEA-Stack's own build config.

**`chrono-main` is untested.** Configured by analogy with `chrono-dev`, never
sourced. Run it once and check `CHRONO_FLAVOR` and `LD_LIBRARY_PATH` before
relying on it.