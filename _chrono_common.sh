#!/usr/bin/env bash
# Shared helpers for ~/env/*.sh toolchain scripts. Sourced, never executed.

# _env_prepend VAR DIR — prepend DIR to colon-separated VAR if not already present.
_env_prepend() {
  local _var="$1" _dir="$2" _cur
  [ -d "$_dir" ] || return 0
  eval "_cur=\${$_var:-}"
  case ":${_cur}:" in
    *":$_dir:"*) ;;
    *)           export "$_var=$_dir${_cur:+:$_cur}" ;;
  esac
}

# _env_strip VAR SUBSTRING — remove every entry in VAR containing SUBSTRING.
# Used when switching toolchains so the previous flavor's libs cannot linger
# on LD_LIBRARY_PATH and get picked by the dynamic loader.
_env_strip() {
  local _var="$1" _needle="$2" _cur _out="" _entry
  eval "_cur=\${$_var:-}"
  [ -n "$_cur" ] || return 0
  local IFS=:
  for _entry in $_cur; do
    case "$_entry" in
      *"$_needle"*) ;;
      *) _out="${_out:+$_out:}$_entry" ;;
    esac
  done
  export "$_var=$_out"
}

# _chrono_reset — clear any previously-sourced Chrono flavor.
_chrono_reset() {
  local _p
  for _p in project-chrono_v10 project-chrono_sh project-chrono; do
    _env_strip CMAKE_PREFIX_PATH "$_p"
    _env_strip LD_LIBRARY_PATH   "$_p"
  done
  unset Chrono_DIR CHRONO_DATA_DIR CHRONO_ROOT CHRONO_PREFIX CHRONO_FLAVOR VSG_FILE_PATH

  # SEA-Stack is ABI-bound to one Chrono flavor; switching Chrono invalidates it.
  if [ -n "${SEAStack_DIR:-}" ]; then
    echo "[chrono] NOTE: clearing SEA-Stack env (was pinned to a different Chrono)." >&2
    _env_strip CMAKE_PREFIX_PATH "SEA-Stack"
    _env_strip LD_LIBRARY_PATH   "SEA-Stack"
    unset SEAStack_DIR SEASTACK_ROOT SEASTACK_SOURCE_DIR
  fi
}

# _chrono_report — one-line summary.
_chrono_report() {
  echo "[chrono] ${CHRONO_FLAVOR} — ${Chrono_DIR}"
  [ -d "${Chrono_DIR:-/nonexistent}" ] || \
    echo "[chrono] WARN: Chrono_DIR does not exist: ${Chrono_DIR}" >&2
  [ -f "${VSG_FILE_PATH:-/nonexistent}/vsg/fonts/OpenSans-Bold.vsgb" ] || \
    echo "[chrono] WARN: VSG font missing under ${VSG_FILE_PATH} — visualization may crash." >&2
}
