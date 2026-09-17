#!/usr/bin/env bash
# Chrono v10 — install tree. The SEA-Stack-compatible flavor.
#
# Source, do not execute:  chrono10
# Pair with SEA-Stack:     chrono10 && seastack

if [ -z "${_CHRONO_COMMON_LOADED:-}" ]; then
  . "$HOME/env/_chrono_common.sh" || return 1
  _CHRONO_COMMON_LOADED=1
fi

_chrono_reset

export CHRONO_ROOT=$HOME/project-chrono_v10/install
export CHRONO_PREFIX=$CHRONO_ROOT          # back-compat alias
export CHRONO_FLAVOR=v10
export Chrono_DIR=$CHRONO_ROOT/lib/cmake/Chrono
export CHRONO_DATA_DIR=$CHRONO_ROOT/share/chrono/data/

# VSG resolves assets as "vsg/fonts/..." relative to this root, so it must be
# the data dir itself, not data/vsg. One level too deep => font lookup fails
# and the renderer segfaults on frame 1.
export VSG_FILE_PATH=${CHRONO_DATA_DIR%/}

# REQUIRED. Chrono v10 exports -march=native to consumers, giving them
# EIGEN_MAX_ALIGN_BYTES=32. Anything sharing Eigen objects with Chrono-linked
# code must match, or Eigen allocates with malloc and frees with
# handmade_aligned_free -> heap-buffer-overflow. Bit us via
# HydroData::GetInfAddedMassMatrix crossing into cpp-vgoswec.
# Guarded so repeated sourcing does not append duplicates.
case " ${CXXFLAGS:-} " in
  *" -march=native "*) ;;
  *) export CXXFLAGS="-march=native${CXXFLAGS:+ $CXXFLAGS}" ;;
esac

_env_prepend CMAKE_PREFIX_PATH "$CHRONO_ROOT"
_env_prepend LD_LIBRARY_PATH   "$CHRONO_ROOT/lib"

_chrono_report
