#!/usr/bin/env bash
# SEA-Stack — install tree. Source a Chrono first:  chrono10 && seastack
#
# SEA-Stack is compiled against one Chrono ABI (v10). Pairing it with a
# different Chrono links cleanly and then segfaults on first use.

if [ -z "${_CHRONO_COMMON_LOADED:-}" ]; then
  . "$HOME/env/_chrono_common.sh" || return 1
  _CHRONO_COMMON_LOADED=1
fi

if [ "${CHRONO_FLAVOR:-}" != "v10" ]; then
  echo "[seastack] WARN: CHRONO_FLAVOR='${CHRONO_FLAVOR:-<none>}', expected 'v10'." >&2
  echo "[seastack]       Run 'chrono10' first, or rebuild SEA-Stack against this Chrono." >&2
fi

export SEASTACK_ROOT=$HOME/SEA-Stack/install
export SEASTACK_SOURCE_DIR=$HOME/SEA-Stack     # for seastack_app_lib + guihelper
export SEAStack_DIR=$SEASTACK_ROOT/lib/cmake/SEAStack

_env_prepend CMAKE_PREFIX_PATH "$SEASTACK_ROOT"
_env_prepend LD_LIBRARY_PATH   "$SEASTACK_ROOT/lib"
_env_prepend LD_LIBRARY_PATH   "/usr/lib/x86_64-linux-gnu/hdf5/serial"

# A stray /usr/local yaml-cpp alongside Chrono's bundled copy makes
# `cmake --install` fail with "Multiple conflicting paths found". Renaming it
# in place is not enough — ldconfig re-creates the SONAME symlink.
if [ -e /usr/local/lib/libyaml-cpp.so.0.8 ]; then
  echo "[seastack] WARN: /usr/local/lib/libyaml-cpp.so.0.8 may conflict with Chrono's copy." >&2
fi

[ -d "$SEAStack_DIR" ] || \
  echo "[seastack] WARN: $SEAStack_DIR not found — run: cmake --install \$HOME/SEA-Stack/build --prefix $SEASTACK_ROOT" >&2

echo "[seastack] $SEAStack_DIR"
