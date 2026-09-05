# groan-coding-tools update.sub.sh
#
# by Keith Hodges 2020
#
me "$BASH_SOURCE" #tradition

command="sync"
s_description="synchronize identical framework copies across project fixtures

Scans the repository for duplicate framework files (identified by code signatures)
and checks whether copies are up to date or modified relative to the latest file.

Supports updating older files via copy or consolidating copies into hardlinks."

s_opts=\
"
--scan [dir]         inspect status of core framework signatures ;
--update [dir]       copy newest code version over older copies ; (requires --confirm)
--hardlink [dir]     hardlink all duplicate copies to the latest file ; (requires --confirm)
"

s_usage=\
"$breadcrumbs --scan [dir]         ; inspect status of framework copies
$breadcrumbs --update --confirm   ; copy latest files over out-of-date copies
$breadcrumbs --hardlink --confirm ; hardlink duplicate copies to the latest file"

$METADATAONLY && return

[[ $# -eq 0 ]] && g_displayHelp && exit 0
 
# Options processing pattern - search through the arguments for the command and flags
declare -A signature

#The signatures below must have ^ otherwise this file will be a false positive
signature['Main executable']="^function g_readConfig "
signature['Dispatcher']="^# Dispatcher alias"
signature['Subcommand alias']="^# Subcommand [Aa]lias"
signature['bash-spec']="^## BDD-style testing framework"

SHOW_GROANS=true
UPDATE=false
HARDLINK=false
scan_dir="${g_dir}"

for arg in "$@"
do
    case "$arg" in
      --scan | --groans | -g*)
            SHOW_GROANS=true
      ;;
      --update)
            UPDATE=true
      ;;
      --hardlink | --hardlinks | -l)
            HARDLINK=true
            UPDATE=true
      ;;
      --all|--a*|-a)
            SHOW_GROANS=true
      ;;
      -*)
        :
      ;;
      *)
        if [[ -d "$arg" ]]; then
            scan_dir="$arg"
        fi
      ;;
    esac
done

if $CONFIRM; then
    UPDATE=true
fi

if $SHOW_GROANS; then 
      $LOUD && echo "${bold}Key:${reset} up to date,${dim}older${reset},${underline}${dim}needs update${reset}"
fi

loc=0
all_up_to_date=true
for name in "${!signature[@]}"; do
      files=()
      latest=""
      for file in $(grep -rl "${signature[$name]}" "${scan_dir}"); do
            files+=("$file")
            [[ -z "$latest" || "$file" -nt "$latest" ]] && latest="$file"
      done

      count=${#files[@]}
      [[ $count -eq 1 ]] && copy_str="copy" || copy_str="copies"
      $LOUD && echo "${bold}${name}${reset} (${count} ${copy_str} found): /${signature[$name]}/"

      [[ $count -eq 0 ]] && continue

      read -r latest_ino _ <<< $(ls -ldi "$latest" 2>/dev/null || echo "0")

      for file in "${files[@]}"; do
            
            if [[ "$latest" == "$file" ]]; then
                   line_count=$(wc -l < "$latest" || echo 0 )
                  (( loc = loc + line_count ))
            fi

            [[ $latest -nt $file ]] && older=true || older=false
            diff $latest $file > /dev/null && different=false || different=true

            read -r ino mode nlink _ <<< $(ls -ldi "$file" 2>/dev/null || echo "0 - 1")
            is_same_inode=false
            [[ "$ino" == "$latest_ino" && "$ino" != "0" ]] && is_same_inode=true

            if $SHOW_GROANS; then      
                  $older && style=$dim || style=$reset
                  $different && style="$underline$dim" || style="$reset"
                  echo "${style}$file${reset}"      
                  if $different && $is_same_inode; then
                        echo "  ${bold}Warning:${reset} $file is hardlinked to $latest ($nlink links). Edits directly modify shared inode."
                  elif $different && [[ "${nlink:-1}" -gt 1 ]]; then
                        echo "  ${bold}Warning:${reset} $file is hardlinked ($nlink links). Copying with cp will affect all linked files or break hardlinks."
                  fi
            fi

            if $HARDLINK; then
                  if ! $is_same_inode; then
                        all_up_to_date=false
                        $LOUD && echo ln -f "$latest" "$file"
                        $CONFIRM && ln -f "$latest" "$file"
                  fi
            elif $UPDATE; then
                  if $different; then
                        all_up_to_date=false
                        if $older; then
                              if [[ "${nlink:-1}" -gt 1 ]]; then
                                    echo "  ${bold}Warning:${reset} $file is hardlinked ($nlink links). 'cp' will modify shared inode or break hardlinks."
                              fi
                              $LOUD && echo cp "$latest" "$file"
                              $CONFIRM && cp "$latest" "$file"
                        fi
                  fi
            fi
      done     
done

if $all_up_to_date; then
      echo "${bold}All up to date${reset}"
else
      $UPDATE && $DRYRUN && echo "DRY RUN --confirm required to update code"
fi

$LOUD && echo "Lines Of Code: $loc"
exit 0
