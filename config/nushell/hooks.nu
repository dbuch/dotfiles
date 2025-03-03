{
  pre_prompt: [
    (pre_prompt_hook)
  ]
  pre_execution: [{||
    null # replace with source code to run before the repl input is run
  }]
  env_change: {
    PWD: [
      {
          condition: {|_, after| $after | path join 'toolkit.nu' | path exists }
          code: "overlay use --prefix toolkit.nu as tk"
      },
    ]
  }
  display_output: {||
    if (term size).columns >= 100 { table -e } else { table }
  }
}
