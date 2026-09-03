# groan.specs.list.cmd.sh
#
# Lists tools under groan/ that have a `specs/` or `tests/` directory.
# Default action of `./groan specs` is this.

me "$BASH_SOURCE" #tradition

command="list"
s_description="list tools with spec/test suites"
s_usage=\
"$breadcrumbs           # list suites"

$METADATAONLY && return

groan_root="${my_path%/*/*/*}"

found=0
while IFS= read -r suite_dir; do
  found=1
  tool=${suite_dir%/*}
  tool=${tool##*/}
  subdir=${suite_dir##*/}
  count=$(find "$suite_dir" -type f \( -name '*spec*.sh' -o -name '*test*.sh' \) | wc -l | tr -d ' ')
  printf "  %-20s %s/ (%s file%s)\n" "$tool" "$subdir" "$count" "$([[ "$count" == 1 ]] && echo '' || echo s)"
done < <(find "$groan_root" -mindepth 2 -maxdepth 2 -type d \( -name specs -o -name tests \) 2>/dev/null | sort)

if [[ $found -eq 0 ]]; then
  echo "no tool sub-dirs under $groan_root contain a specs/ or tests/ directory"
fi
