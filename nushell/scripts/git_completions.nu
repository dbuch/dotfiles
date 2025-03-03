def "nu-complete git branches" [] {
  ^git branch | lines | each { |line| $line | str replace '\* ' "" | str trim }
}

def parse_git_status_short [] {
  let file_status = ($in | parse -r '(?P<mode>..) (?P<file>[^\s]+)')

  let staged = ($file_status | get mode | first | str substring '0,1' | str trim)
  let unstaged = ($file_status | get mode | first | str substring '1,2' | str trim)

  { staged: $staged, unstaged: $unstaged, file: ($file_status.file | first) }
}

def "nu-complete git add" [] {
  ^git status -s | lines | each { |line| $line | parse_git_status_short } | where unstaged != "" | get file
}

def "nu-complete git remotes" [] {
  ^git remote | lines | each { |line| $line | str trim }
}

def "nu-complete git refspecs" [] {
  ^git for-each-ref --format='%(refname:short)' refs/heads/ | lines | each { |line| $line }
}

def "nu-complete git log" [] {
  ^git log --pretty=%h | lines | each { |line| $line | str trim }
}

# Check out git branches and files
export extern "git checkout" [
  ...targets: string@"nu-complete git branches"   # name of the branch or files to checkout
  --conflict: string                              # conflict style (merge or diff3)
  --detach(-d)                                    # detach HEAD at named commit
  --force(-f)                                     # force checkout (throw away local modifications)
  --guess                                         # second guess 'git checkout <no-such-branch>' (default)
  --ignore-other-worktrees                        # do not check if another worktree is holding the given ref
  --ignore-skip-worktree-bits                     # do not limit pathspecs to sparse entries only
  --merge(-m)                                     # perform a 3-way merge with the new branch
  --orphan: string                                # new unparented branch
  --ours(-2)                                      # checkout our version for unmerged files
  --overlay                                       # use overlay mode (default)
  --overwrite-ignore                              # update ignored files (default)
  --patch(-p)                                     # select hunks interactively
  --pathspec-from-file: string                    # read pathspec from file
  --progress                                      # force progress reporting
  --quiet(-q)                                     # suppress progress reporting
  --recurse-submodules: string                    # control recursive updating of submodules
  --theirs(-3)                                    # checkout their version for unmerged files
  --track(-t)                                     # set upstream info for new branch
  -b: string                                      # create and checkout a new branch
  -B: string                                      # create/reset and checkout a branch
  -l                                              # create reflog for new branch
]


# Shows a remote
export extern "git show" [
  commit?: string@"nu-complete git log"
  --abbrev                # Show only a partial prefix instead of the full 40-byte hexadecimal object name
  --binary			        		# Output a binary diff that can be applied with "git-apply
  --check				        	# Warn if changes introduce conflict markers or whitespace errors
  --color				        	# Show colored diff
  --color-moved 		 	# Moved lines of code are colored differently
  --color-words					# Equivalent to --word-diff=color plus --word-diff-regex=<regex>
  --compact-summary					# Output a condensed summary of extended header information
  --dst-prefix					# Show the given destination prefix instead of "b/
  --ext-diff					# Allow an external diff helper to be executed
  --find-copies-harder					# Inspect unmodified files as candidates for the source of copy
  --find-object					# Look for differences that change the number of occurrences of the object
  --full-index					# Show the full pre- and post-image blob object names on the "index" line
  --histogram					# Generate a diff using the "histogram diff" algorithm
  --ignore-blank-lines					# Ignore changes whose lines are all blank
  --ignore-cr-at-eol					# Ignore carrige-return at the end of line when doing a comparison
  --ignore-space-at-eol					# Ignore changes in whitespace at EOL
  --indent-heuristic					# Enable the heuristic that shift diff hunk boundaries
  --inter-hunk-context					# Show the context between diff hunks, up to the specified number of lines
  --ita-invisible-in-index					# Make the entry appear as a new file in "git diff" and non-existent in "git diff -l cached
  --line-prefix					# Prepend an additional prefix to every line of output
  --minimal					# Spend extra time to make sure the smallest possible diff is produced
  --name-only					# Show only names of changed files
  --name-status					# Show only names and status of changed files
  --no-color					# Turn off colored diff
  --no-ext-diff					# Disallow external diff drivers
  --no-indent-heuristic					# Disable the indent heuristic
  --no-prefix					# Do not show any source or destination prefix
  --no-renames					# Turn off rename detection
  --no-textconv					# Disallow external text conversion filters to be run when comparing binary files
  --numstat					# Shows number of added/deleted lines in decimal notation
  --patch-with-raw					# Synonym for -p --raw
  --patch-with-stat					# Synonym for -p --stat
  --patience					# Generate a diff using the "patience diff" algorithm
  --pickaxe-all					# When -S or -G finds a change, show all the changes in that changeset
  --pickaxe-regex					# Treat the <string> given to -S as an extended POSIX regular expression to match
  --relative					# Exclude changes outside the directory and show relative pathnames
  --shortstat					# Output only the last line of the --stat format containing total number of modified files
  --src-prefix					# Show the given source prefix instead of "a/
  --stat					# Generate a diffstat
  --stat					# Generate a diffstat
  --summary					# Output a condensed summary of extended header information
  --textconv					# Allow external text conversion filters to be run when comparing binary files
  --word-diff					# Show a word diff
  --word-diff-regex					# Use <regex> to decide what a word is
  --text(-a)					# Treat all files as text
  --break-rewrites(-B)					# Break complete rewrite changes into pairs of delete and create
  --ignore-space-change(-b)					# Ignore changes in amount of whitespace
  --find-copies(-C)					# Detect copies as well as renames
  --irreversible-delete(-D)					# Omit the preimage for deletes
  --find-renames(-M)					# Detect and report renames
  --function-context(-W)					# Show whole surrounding functions of changes
  --ignore-all-space(-w)					# Ignore whitespace when comparing lines
  --anchored					# Generate a diff using the "anchored diff" algorithm
  --abbrev-commit					# Show only a partial hexadecimal commit object name
  --no-abbrev-commit					# Show the full 40-byte hexadecimal commit object name
  --oneline					# Shorthand for "--pretty=oneline --abbrev-commit
  --encoding					# Re-code the commit log message in the encoding
  --expand-tabs					# Perform a tab expansion in the log message
  --no-expand-tabs					# Do not perform a tab expansion in the log message
  --no-notes					# Do not show notes
  --no-patch(-s)					# Suppress diff output
  --show-signature					# Check the validity of a signed commit object
  --remotes(-r)					# Shows the remote tracking branches
  --all(-a)					# Show both remote-tracking branches and local branches
  --current					# Includes the current branch to the list of revs to be shown
  --topo-order					# Makes commits appear in topological order
  --date-order					# Makes commits appear in date order
  --sparse					# Shows merges only reachable from one tip
  --no-name					# Do not show naming strings for each commit
  --sha1-name					# Name commits with unique prefix
  --no-color					# Turn off colored output
  ...args
]

# Fetch from and merge with another repository or a local branch
export extern "git pull" [
  remotes?: string@"nu-complete git remotes", # name of the branch to pull
  refspec?: string@"nu-complete git refspecs" # name of the ref to pull
  --unshallow					                        # Convert a shallow repository to a complete one
  --set-upstream					                    # Add upstream (tracking) reference
  --quiet(-q)					# Be quiet
  --verbose(-v)					# Be verbose
  --all					# Fetch all remotes
  --append(-a)					# Append ref names and object names
  --force(-f)					# Force update of local branches
  --keep(-k)					# Keep downloaded pack
  --no-tags					# Disable automatic tag following
  --prune(-p)					# Remove remote-tracking references that no longer exist on the remote
  --progress					# Force progress status
  --commit					# Autocommit the merge
  --no-commit					# Don't autocommit the merge
  --edit(-e)					# Edit auto-generated merge message
  --no-edit					# Don't edit auto-generated merge message
  --ff					# Don't generate a merge commit if merge is fast-forward
  --no-ff					# Generate a merge commit even if merge is fast-forward
  --ff-only					# Refuse to merge unless fast-forward possible
  --gpg-sign(-S)					# GPG-sign the merge commit
  --log					# Populate the log message with one-line descriptions
  --no-log					# Don't populate the log message with one-line descriptions
  --signoff					# Add Signed-off-by line at the end of the merge commit message
  --no-signoff					# Do not add a Signed-off-by line at the end of the merge commit message
  --stat					# Show diffstat of the merge
  --no-stat(-n)					# Don't show diffstat of the merge
  --squash					# Squash changes from upstream branch as a single commit
  --no-squash					# Don't squash changes
  --verify-signatures					# Abort merge if upstream branch tip commit is not signed with a valid key
  --no-verify-signatures					# Do not abort merge if upstream branch tip commit is not signed with a valid key
  --allow-unrelated-histories					# Allow merging even when branches do not share a common history
  --rebase(-r)					# Rebase the current branch on top of the upstream branch
  --no-rebase					# Do not rebase the current branch on top of the upstream branch
  --autostash					# Before starting rebase, stash local changes, and apply stash when done
  --no-autostash					# Do not stash local changes before starting rebase
  ...args
]

# Download objects and refs from another repository
export extern "git fetch" [
  repository?: string@"nu-complete git remotes" # name of the branch to fetch
  --all                                         # Fetch all remotes
  --append(-a)                                  # Append ref names and object names to .git/FETCH_HEAD
  --atomic                                      # Use an atomic transaction to update local refs.
  --depth: int                                  # Limit fetching to n commits from the tip
  --deepen: int                                 # Limit fetching to n commits from the current shallow boundary
  --shallow-since: string                       # Deepen or shorten the history by date
  --shallow-exclude: string                     # Deepen or shorten the history by branch/tag
  --unshallow                                   # Fetch all available history
  --update-shallow                              # Update .git/shallow to accept new refs
  --negotiation-tip: string                     # Specify which commit/glob to report while fetching
  --negotiate-only                              # Do not fetch, only print common ancestors
  --dry-run                                     # Show what would be done
  --write-fetch-head                            # Write fetched refs in FETCH_HEAD (default)
  --no-write-fetch-head                         # Do not write FETCH_HEAD
  --force(-f)                                   # Always update the local branch
  --keep(-k)                                    # Keep dowloaded pack
  --multiple                                    # Allow several arguments to be specified
  --auto-maintenance                            # Run 'git maintenance run --auto' at the end (default)
  --no-auto-maintenance                         # Don't run 'git maintenance' at the end
  --auto-gc                                     # Run 'git maintenance run --auto' at the end (default)
  --no-auto-gc                                  # Don't run 'git maintenance' at the end
  --write-commit-graph                          # Write a commit-graph after fetching
  --no-write-commit-graph                       # Don't write a commit-graph after fetching
  --prefetch                                    # Place all refs into the refs/prefetch/ namespace
  --prune(-p)                                   # Remove obsolete remote-tracking references
  --prune-tags(-P)                              # Remove any local tags that do not exist on the remote
  --no-tags(-n)                                 # Disable automatic tag following
  --refmap: string                              # Use this refspec to map the refs to remote-tracking branches
  --tags(-t)                                    # Fetch all tags
  --recurse-submodules: string                  # Fetch new commits of populated submodules (yes/on-demand/no)
  --jobs(-j): int                               # Number of parallel children
  --no-recurse-submodules                       # Disable recursive fetching of submodules
  --set-upstream                                # Add upstream (tracking) reference
  --submodule-prefix: string                    # Prepend to paths printed in informative messages
  --upload-pack: string                         # Non-default path for remote command
  --quiet(-q)                                   # Silence internally used git commands
  --verbose(-v)                                 # Be verbose
  --progress                                    # Report progress on stderr
  --server-option(-o): string                   # Pass options for the server to handle
  --show-forced-updates                         # Check if a branch is force-updated
  --no-show-forced-updates                      # Don't check if a branch is force-updated
  -4                                            # Use IPv4 addresses, ignore IPv6 addresses
  -6                                            # Use IPv6 addresses, ignore IPv4 addresses
  ]

# Push changes
export extern "git push" [
  remote?: string@"nu-complete git remotes",      # the name of the remote
  ...refs: string@"nu-complete git branches"      # the branch / refspec
  --all                                           # push all refs
  --atomic                                        # request atomic transaction on remote side
  --delete(-d)                                    # delete refs
  --dry-run(-n)                                   # dry run
  --exec: string                                  # receive pack program
  --follow-tags                                   # push missing but relevant tags
  --force-with-lease: string                      # require old value of ref to be at this value
  --force(-f)                                     # force updates
  --ipv4(-4)                                      # use IPv4 addresses only
  --ipv6(-6)                                      # use IPv6 addresses only
  --mirror                                        # mirror all refs
  --no-verify                                     # bypass pre-push hook
  --porcelain                                     # machine-readable output
  --progress                                      # force progress reporting
  --prune                                         # prune locally removed refs
  --push-option(-o): string                       # option to transmit
  --quiet(-q)                                     # be more quiet
  --receive-pack: string                          # receive pack program
  --recurse-submodules: string                    # control recursive pushing of submodules
  --repo: string                                  # repository
  --set-upstream(-u)                              # set upstream for git pull/status
  --signed: string                                # GPG sign the push
  --tags                                          # push tags (can't be used with --all or --mirror)
  --thin                                          # use thin pack
  --verbose(-v)                                   # be more verbose
]

# Switch between branches and commits
export extern "git switch" [
  switch?: string@"nu-complete git branches"      # name of branch to switch to
  --create(-c): string                            # create a new branch
  --detach(-d): string@"nu-complete git log"      # switch to a commit in a detatched state
  --force-create(-C): string                      # forces creation of new branch, if it exists then the existing branch will be reset to starting point
  --force(-f)                                     # alias for --discard-changes
  --guess                                         # if there is no local branch which matches then name but there is a remote one then this is checked out
  --ignore-other-worktrees                        # switch even if the ref is held by another worktree
  --merge(-m)                                     # attempts to merge changes when switching branches if there are local changes
  --no-guess                                      # do not attempt to match remote branch names
  --no-progress                                   # do not report progress
  --no-recurse-submodules                         # do not update the contents of sub-modules
  --no-track                                      # do not set "upstream" configuration
  --orphan: string                                # create a new orphaned branch
  --progress                                      # report progress status
  --quiet(-q)                                     # suppress feedback messages
  --recurse-submodules                            # update the contents of sub-modules
  --track(-t)                                     # set "upstream" configuration
]

export extern "git add" [
  --dry-run(-n)		# dry run
	--verbose(-v)		# be verbose
	--interactive(-i)		# interactive picking
	--patch(-p)		# select hunks interactively
	--edit(-e)		# edit current diff and apply
	--force(-f)		# allow adding otherwise ignored files
	--update(-u)		# update tracked files
	--renormalize		# renormalize EOL of tracked files (implies -u)
	--intent-to-add(-N)		# record only the fact that the path will be added later
	--all(-A)		# add changes from all tracked and untracked files
	--ignore-removal		# ignore paths removed in the working tree (same as --no-all)
	--refresh		# don't add, only refresh the index
	--ignore-errors		# just skip files which cannot be added because of errors
	--ignore-missing		# check if - even missing - files are ignored in dry run
	--sparse		# allow updating entries outside of the sparse-checkout cone
	--chmod		# (+|-)x        override the executable bit of the listed files
	--pathspec-from-file		# read pathspec from file
	--pathspec-file-nul		# with --pathspec-from-file, pathspec elements are separated with NUL character
  ...args: string@"nu-complete git add",
]
