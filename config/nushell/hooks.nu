use std/config *

export def main []: nothing -> record {
  {
    env_change: {
      PWD: [
        {
            condition: {|_, after| $after | path join toolkit.nu | path exists }
            code: "overlay use --prefix toolkit.nu as tk"
        }
        {||
          if (which direnv | is-empty) {
            # If direnv isn't installed, do nothing
            return
          }

          try { direnv export json err> /dev/null | from json } | | default {} | load-env
          # If direnv changes the PATH, it will become a string and we need to re-convert it to a list
          $env.PATH = do (env-conversions).path.from_string $env.PATH
        }
      ]
    }
    display_output: {||
      if (term size).columns >= 100 { table --expand } else { table }
    }
  }
}
