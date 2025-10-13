# rust_env.nu
#
# Nushell overlay for configuring Rust build environment
# Provides options for:
# - Native CPU optimizations
# - Baseline / generic targets
# - Custom cargo/rustup paths
#
# Usage:
# overlay use ./rust_env.nu as rust
# rust set-native
# rust set-baseline

module rust_env {

  # === Internal helper for setting env vars ===
  def --env set_rust_env [opt_level: string, target_cpu: string] {
    load-env {
      # Optimize for performance or portability
      RUSTFLAGS: "-C opt-level=${opt_level} -C target-cpu=${target_cpu}"
    }
  }

  # === Public commands ===

  # Set RUSTFLAGS to optimize for current CPU
  export def --env set-native [] {
    set_rust_env "3" "native"
  }

  # Set RUSTFLAGS to a safe baseline (portable builds)
  export def --env set-baseline [] {
    set_rust_env "2" "baseline"
  }

  # Show current Rust-related env vars
  export def show [] {
    {
      RUSTFLAGS: $env.RUSTFLAGS?,
      CARGO_HOME: $env.CARGO_HOME?,
      RUSTUP_HOME: $env.RUSTUP_HOME?,
      PATH: $env.PATH
    }
  }

  # Clear Rust environment (reset RUSTFLAGS)
  export def --env clear [] {
    load-env {
      RUSTFLAGS: ""
    }
  }
}
