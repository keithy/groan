#g_locations to search for configuration *.conf files

g_config_options=("local" "user" "global")

g_config_file_locations=(
	"$g_working_dir/$c_name.conf"  # --local
	"$HOME/.$c_name.conf"       # --user
	"$c_dir/$c_name.conf"  # --global
)

g_config_preset_locations=(
    "$c_dir"
)

g_locations=(
	  "${c_dir}/commands"                
	  "${c_dir}/topics"                  
  )


g_default_dispatch="_dispatch.sh"
g_default_subcommand="_default"
 
g_markdown_viewer="mdv -t 715.1331"

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."