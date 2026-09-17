#!/usr/bin/env bash
# Chrono upstream main (rolling) — build tree, never installed.
# NOT SEA-Stack-compatible: SEA-Stack is built against the v10 ABI (chrono10).

if [ -z "${_CHRONO_COMMON_LOADED:-}" ]; then
  . "$HOME/env/_chrono_common.sh" || return 1
  _CHRONO_COMMON_LOADED=1
fi

_chrono_reset

export CHRONO_ROOT=$HOME/project-chrono/build
export CHRONO_FLAVOR=main
export Chrono_DIR=$CHRONO_ROOT/cmake
export CHRONO_DATA_DIR=$CHRONO_ROOT/data/
export VSG_FILE_PATH=${CHRONO_DATA_DIR%/}

_env_prepend CMAKE_PREFIX_PATH "$Chrono_DIR"
_env_prepend LD_LIBRARY_PATH   "$CHRONO_ROOT/lib"

_chrono_report
