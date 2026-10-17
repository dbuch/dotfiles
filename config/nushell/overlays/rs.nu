# Nushell overlay for configuring Rust build environment
# Provides options for:
# - Native CPU optimizations
# - Baseline / generic targets
#
# Usage: `overlay use ./overlays/rs.nu` activates these as bare top-level
# commands (the overlay layer itself has no name prefix in Nushell, so
# `set-native`/`set-baseline`/etc. are called directly, not as `rust ...`).
#   overlay use ./overlays/rs.nu
#   set-native
#   set-baseline
#   overlay hide rs

# === Internal helper for setting env vars ===
def --env set-rust-env [opt_level: string, target_cpu: string] {
  load-env {
    # Optimize for performance or portability
    RUSTFLAGS: $"-C opt-level=($opt_level) -C target-cpu=($target_cpu)"
  }
}

# === Public commands ===

# Set RUSTFLAGS to optimize for current CPU
export def --env set-native []: nothing -> nothing {
  set-rust-env "3" "native"
}

# Set RUSTFLAGS to a safe baseline (portable builds)
export def --env set-baseline []: nothing -> nothing {
  set-rust-env "2" "baseline"
}

# Show current Rust-related env vars
export def rust-status []: nothing -> record {
  {
    RUSTFLAGS: $env.RUSTFLAGS?
    CARGO_HOME: $env.CARGO_HOME?
    RUSTUP_HOME: $env.RUSTUP_HOME?
    PATH: $env.PATH
  }
}

# Clear Rust environment (reset RUSTFLAGS)
export def --env rust-reset []: nothing -> nothing {
  load-env {
    RUSTFLAGS: ""
  }
}
