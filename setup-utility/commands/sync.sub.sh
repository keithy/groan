# groan-coding-tools update.sub.sh
#
# by Keith Hodges 2020
#
me "$BASH_SOURCE" #tradition

command="$s_sub_cmd"
brief="update code files that should be identical
The framework has many code files that should be identical: 
- find those files based on a signature text snippet
- highlight latest vs out of date code
- --update brings all files up to date
"
s_options=\
"
--groans              # show all groan code (default)
--update [--confirm]  # update older files to latest code
"

s_usage=\
"$breadcrumbs --groans        # show all check endpoints"

$METADATAONLY && return
 
# Options processing pattern - search through the arguments for the command and flags
declare -A signature

#The signatures below must have ^ otherwise this file will be a false positive
signature['Main executable']="^function g_readLocations"
signature['Dispatcher']="^# This g_dispatcher"
signature['List commands']="^# groan single command list"
signature['Test all suites runner']="^# groan test.sub.sh"
signature['Subcommand alias']="^# Subcommand Alias"
signature['Test suite runner']="^# Script for running"
signature['bash-spec']="^## BDD-style testing framework"
signature['version.sub.sh']="^# groan version.sub.sh"
signature['api.sub.sh']="^s_description=\"\$app raw api calls\""
signature['utils.sh']="^function json_pretty_print"

SHOW_GROANS=true
SHOW_LATEST=false
SHOW_FILES=false
UPDATE=false

for arg in "$@"
do
    case "$arg" in
      --gr*|-g*)
            SHOW_GROANS=true
      ;;
      --update)
            UPDATE=true
      ;;
      --all|--a*|-a)
            SHOW_GROANS=true
      ;;
      *)
        :
      ;;
    esac
done

if $SHOW_GROANS; then 
      $LOUD && echo "${bold}Key:${reset} up to date,${dim}older${reset},${underline}${dim}needs update${reset}"
fi

loc=0
all_up_to_date=true
for name in "${!signature[@]}"; do
      $LOUD && echo "${bold}${name}${reset}: /${signature[$name]}/"

      latest=""
      for file in $(grep -rl "${signature[$name]}" "${g_dir}"); do
            [[ "$file" -nt "$latest" ]] && latest="$file"
      done

      for file in $(grep -rl "${signature[$name]}" "${g_dir}"); do
            
            if [[ "$latest" == "$file" ]]; then
                   line_count=$(wc -l < "$latest" || echo 0 )
                  (( loc = loc + line_count ))
            fi

            [[ $latest -nt $file ]] && older=true || older=false
            diff $latest $file > /dev/null && different=false || different=true

            if $SHOW_GROANS; then      
                  $older && style=$dim || style=$reset
                  $different && style="$underline$dim" || style="$reset"
                  echo "${style}$file${reset}"      
            fi

            $different && all_up_to_date=false
            $older && $different && $UPDATE && $LOUD && echo cp "$latest" "$file"
            $older && $different && $UPDATE && $CONFIRM &&   cp "$latest" "$file"
      done     
done

if $all_up_to_date; then
      echo "${bold}All up to date${reset}"
else
      $UPDATE && $DRYRUN && echo "DRY RUN --confirm required to update code"
fi

$LOUD && echo "Lines Of Code: $loc"
exit 0
