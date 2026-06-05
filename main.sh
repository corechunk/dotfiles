#!/usr/bin/env bash


# key <--> type|link|folder|installer|live-ver-dest
declare -A components=(
	["hyprland"]="dotfile|https://github.com/corechunk/hyprland.git|hyprland|installer_hyprland_dots.sh|$HOME/.config/hypr"
    ["waybar"]="dotfile|https://github.com/corechunk/waybar.git|waybar|installer_waybar_dots.sh|$HOME/.config/waybar"
    ["quickshell"]="dotfile|https://github.com/corechunk/quickshell.git|quickshell|installer_quickshell_dots.sh|$HOME/.config/quickshell"
    ["wallust"]="dotfile|https://github.com/corechunk/wallust.git|wallust|installer_wallust_dots.sh|$HOME/.config/wallust"
    ["fastfetch"]="dotfile|https://github.com/corechunk/fastfetch.git|fastfetch|installer_fastfetch_dots.sh|$HOME/.config/fastfetch"
    ["neovim"]="dotfile|https://github.com/corechunk/Neovim.git|neovim|installer_nvim_dots.sh|$HOME/.config/nvim"
    ["kitty"]="dotfile|https://github.com/corechunk/Kitty.git|Kitty|installer_kitty_dots.sh|$HOME/.config/kitty"
    ["bash"]="dotfile|https://github.com/corechunk/Bash.git|Bash|installer_bash_dots.sh|$HOME"
    ["tmux"]="dotfile|https://github.com/corechunk/Tmux.git|tmux|installer_tmux_dots.sh|$HOME/.config/tmux"
    ["oh-my-posh"]="dotfile|https://github.com/corechunk/omp.git|oh-my-posh|installer_omp_dots.sh|$HOME/.config/omp"
    ["sddm"]="dotfile|https://github.com/corechunk/sddm.git|sddm|installer_sddm_dots.sh|/etc/sddm.conf.d"
    ["cava"]="dotfile|https://github.com/corechunk/cava.git|cava|installer_cava_dots.sh|$HOME/.config/cava"

	["wallpaper_minecraft"]="wallpaper|https://github.com/corechunk/wallpaper_minecraft.git|wallpaper_minecraft|installer_wm_dots.sh|"
	["wallpaper_os"]="wallpaper|https://github.com/corechunk/wallpaper_os.git|wallpaper_os|installer_wo_dots.sh|"
	["wallpaper_jakoolit"]="wallpaper|https://github.com/corechunk/wallpaper_jakoolit.git|wallpaper_jakoolit|installer_wj_dots.sh|"

	["sddm-themes-plus"]="theme|https://github.com/corechunk/sddm-themes-plus.git|sddm-themes-plus|installer_TsddmP_dots.sh|/usr/share/sddm/themes"
)

echo_bundle_versions() { # returns an array of bundles from the matrix file, later ill add a check for the latest version from github and add it on top of the list
	{
		read -r header # Read and ignore the header line
		while IFS= read -r line; do
			[[ -z "$line" || "$line" =~ ^# ]] && continue # Skip empty lines and comments
			id="${line%%|*}" # Extract the key (id)
			id="${id// /}" # Remove spaces from the key
			id="${id//[\[\]]/}" # Remove brackets from the key
			echo $id
		done
	} < "$matrix_file"
}

{ # ------------------------- Initialization and Variable Declarations -----------------------
	# Colors
	declare -g RED=$(tput setaf 1)
	declare -g GREEN=$(tput setaf 2)
	declare -g YELLOW=$(tput setaf 3)
	declare -g ORANGE=$(tput setaf 166)
	declare -g SKY_BLUE=$(tput setaf 6)
	declare -g RESET=$(tput sgr0)
	# Status Indicators
	declare -g ok="${GREEN}[ OK ]${RESET}"
	declare -g diff="${YELLOW}[DIFF]${RESET}"
	declare -g sync="${SKY_BLUE}[SYNC]${RESET}"
	declare -g minus="${RED}[ -- ]${RESET}"
	declare -g exclamation="${ORANGE}[!!]${RESET}"
	declare -g vault_sync="${SKY_BLUE}Vault Sync${RESET}"
	declare -g selected="${GREEN}[#]${RESET}"


	# Directories
	declare -g script_dir=$(pwd)
	declare -g processing_dir="$script_dir/processing"
	declare -g bundles_dir="$processing_dir/bundles"
	declare -g assets_dir="$processing_dir/assets"
	declare -g wallpapers_dir="$assets_dir/wallpapers"
	declare -g themes_dir="$assets_dir/themes"
	# Files
	declare -g matrixFileName="matrix.txt"
	declare -g matrix_file="$processing_dir/$matrixFileName"
	# Other variables
	declare -g install_mode="rookie"
	declare -g current_distro=$(lsb_release -ds 2>/dev/null || echo "Unknown Linux")

	# Load bundles from matrix file
	declare -g -a bundles_versions=() # all versions e.g. 1.0.0, 1.1.0, latest, ...

	declare -g target_bundle # target it to the latest available in matrixfile by init()
	declare -g -A target_bundle_components=() # e.g., hyprland -> 1.0.0 , ... must target_bundle_map_components(), every time target bundle is switched
	declare -g -A target_bundle_status=()
	# e.g., hyprland -> [ OK ] , ... must update_target_bundle_status() after every action on the components of the target bundle, like clone, install, etc. and also after switching to another bundle

	# for other processes
	declare -g -a bundle_idxes=()

	declare -g -A web_versions # e.g., hyprland -> 1.2.0(latest on github), ... must fetch_latest_versions() in init()
	#(IFS='|';echo "Loaded bundles: ${bundles[*]}")

	# pids
	declare -g -A pids

	# Create necessary directories
	[[ -d "$processing_dir" ]] || mkdir -p "$processing_dir"
	[[ -d "$bundles_dir" ]] || mkdir -p "$bundles_dir"
	[[ -d "$assets_dir" ]] || mkdir -p "$assets_dir"
	[[ -d "$wallpapers_dir" ]] || mkdir -p "$wallpapers_dir"
	[[ -d "$themes_dir" ]] || mkdir -p "$themes_dir"
	# Create matrix file if it doesn't exist
	[[ -f "$matrix_file" ]] || { echo "Error: File not found: $matrix_file"; exit 1;}
}

fetch_latest_versions(){
	for key in "${!components[@]}";do
	(
		local IFS='|';read -a data <<< "${components[$key]}"
		local link="${data[1]}"
		local last_line=""
		while IFS= read -r line; do
			last_line="$line"
		done < <(git ls-remote --sort="v:refname" --tags "$link")
		local tag=${last_line##*/}
		tag=${tag##[vV]}
		echo $tag > "/tmp/${key}.version"
	) &
	done
}

collect_web_versions() { # Read data from /tmp into main memory
	for key in "${!components[@]}";do
		if [[ -f "/tmp/${key}.version" ]]; then
			web_versions["$key"]="$(<"/tmp/${key}.version")"
			rm "/tmp/${key}.version"
		else
			web_versions["$key"]="N/A"
		fi
	done
}

pid_store() { # Takes Name ($1) and PID ($2)
	local name=$1
	local pid=$2
	pids["$name"]="$pid"
}

wait_pid() { # Takes Name ($1), waits if active, then unsets
	local name=$1
	local pid="${pids[$name]}"
	[[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && wait "$pid"
	unset "pids[$name]"
}

list_bundles() {
	echo "Available Bundles:"
	local -i index=${#bundles_versions[@]}
	bundle_idxes=() # reset indexes
	
	for ((i=0;i<${#bundles_versions[@]};i++)); do
		echo "$index) [${bundles_versions[i]}]"
		bundle_idxes+=($i)
		((index--))
	done

	# JOIN: Wait and then collect in main shell
	wait_pid "fetch_latest_versions"
	collect_web_versions
	target_bundle_update_status # Refresh statuses with new web data

	{
		echo "$index) [Github Latest]"
	}

}

target_bundle_map_components() {
	declare -g -A target_bundle_components=() # reset components globally
	if [[ "$target_bundle" == "vNext" ]]; then
		# Populate from web_versions instead of matrix
		for key in "${!components[@]}"; do
			[[ "${components[$key]}" != "dotfile|"* ]] && continue
			target_bundle_components["$key"]="${web_versions[$key]:-N/A}"
		done
		return
	fi

	local file_data=$(<"$matrix_file")
	local keys=$(grep "COMPONENTS:" <<< "$file_data")
	local row=$(grep "^\[$target_bundle\]" <<< "$file_data")

	keys=${keys#*COMPONENTS:}
	local values="${row#*|}"

	local -a keys_arr=()
	local -a values_arr=()

	local IFS=':'; read -ra keys_arr <<< "$keys"
	local IFS='|'; read -ra values_arr <<< "$values"

	for (( i=0; i<${#keys_arr[@]}; i++ )); do
		local key="${keys_arr[i]}"
		local value="${values_arr[i]}"
		# ONLY map if it's a dotfile type in our registry
		if [[ "${components[$key]}" == "dotfile|"* ]]; then
			target_bundle_components["$key"]="${value:-N/A}"
		fi
	done
}
compareVersions() { # over engineered version comparison function :)
    # 1. Clean inputs: Strip 'v'/'V', all whitespace, tabs, and trailing newlines
    local ver1=$(echo "$1" | tr -d 'vV[:space:]')
    local ver2=$(echo "$2" | tr -d 'vV[:space:]')

    # If either version string ends up completely empty, return unknown
    if [[ -z "$ver1" || -z "$ver2" ]]; then
        echo "unknown"
        return
    fi

    # 2. Parse into arrays using '.' as the delimiter
    IFS='.' read -r -a v1_parts <<< "$ver1"
    IFS='.' read -r -a v2_parts <<< "$ver2"

    # 3. HEAVY-DUTY PADDING: Force both arrays to have exactly 4 elements (0 to 3)
    for i in {0..3}; do
        if [[ -z "${v1_parts[i]}" ]]; then
            v1_parts[i]=0
        fi
        if [[ -z "${v2_parts[i]}" ]]; then
            v2_parts[i]=0
        fi
    done

    # 4. Strict Directional Left-to-Right Traversal
    for i in {0..3}; do
        if (( v1_parts[i] < v2_parts[i] )); then
            # The destination version (v2) is larger -> An update is available!
            case $i in
                0) echo "major update"; return ;;
                1) echo "minor update"; return ;;
                2) echo "patch update"; return ;;
                3) echo "hotfix update"; return ;;
            esac
        elif (( v1_parts[i] > v2_parts[i] )); then
            # The current version (v1) is larger -> Higher version already here!
            echo "downgrade"
            return
        fi
    done

    # If the loop finishes without returning, all parts matched perfectly
    echo "equal"
}

target_bundle_update_status(){
	for key in "${!target_bundle_components[@]}"; do
		local m_ver="${target_bundle_components[$key]}"
		local w_ver="${web_versions[$key]}"

		# Metadata parsing for Live Path
		local meta="${components[$key]}"
		local -a data; IFS='|' read -ra data <<< "$meta"
		local live_path="${data[4]}"

		local status="$minus"

		# 1. Status Logic: System Reality first, then Vault Sync, then Missing.
		if [[ -f "$live_path/.version" ]]; then
			local live_v=$(<"$live_path/.version")
			local comp=$(compareVersions "$live_v" "$m_ver")
			[[ "$comp" == "equal" ]] && status="$ok" || status="$diff"
		elif [[ -d "$bundles_dir/$target_bundle/${data[2]}" ]]; then
			status="$sync"
		else
			status="$minus"
		fi

		# 2. Web Update Check (Exclamation flag)
		local update_flag=""
		if [[ -n "$w_ver" && "$w_ver" != "N/A" ]]; then
			local web_comp=$(compareVersions "$m_ver" "$w_ver")
			[[ "$web_comp" == *"update"* ]] && update_flag="$exclamation"
		fi

		target_bundle_status["$key"]="$status$update_flag"
	done
}
target_bundle_clone(){
	for key in "${!target_bundle_components[@]}"; do
		local tag="${target_bundle_components[$key]}"

		local link="${components[$key]}"
		local -a data=()
		local IFS='|';read -a data <<< "$link"
		local link="${data[1]}"
		local folder="${data[2]}"

		local dest="$bundles_dir/$target_bundle/$folder"

		if [[ "$tag" != "N/A" ]]; then
		# with tag
			if [[ ! -d "$dest" ]];then
				git clone --depth 1 --branch "v$tag" "$link" "$dest" || git clone --depth 1 --branch "$tag" "$link" "$dest"
			fi
		else # clonse the latest if the version is N/A
			[[ ! -d "$dest" ]] && git clone --depth 1 "$link" "$dest"
		fi
	done
}

target_bundle_deploy() {
	# For each component, run its installer script if it exists
	for key in "${!target_bundle_components[@]}"; do
		local meta="${components[$key]}"
		local -a data; IFS='|' read -ra data <<< "$meta"
		local installer_script="${data[3]}"
		local live_path="${data[4]}"

		if [[ -f "$processing_dir/installers/$installer_script" ]]; then
			if [[ "$install_mode" == "interactive" ]]; then
				read -rp "Install ${key^} (v${target_bundle_components[$key]})? [Y/n]: " confirm
				[[ "$confirm" =~ ^[Yy]$ ]] || continue
				"$processing_dir/installers/$installer_script"
				target_bundle_update_status # Update status after each install
			fi
		else
			echo "Warning: Installer script not found for ${key^}: $installer_script"
		fi
	done
}
target_bundle_info_list(){
	local bundle_status="$ok"

	# Global Status Calculation
	for key in "${!target_bundle_components[@]}"; do
		local meta="${components[$key]}"
		local -a data; IFS='|' read -ra data <<< "$meta"

		# Priority 1: Not Cloned -> [!!]
		if [[ ! -d "$bundles_dir/$target_bundle/${data[2]}" ]]; then
			bundle_status="$exclamation"
			break
		fi

		# Priority 2: Cloned but Different -> [DIFF]
		if [[ "${target_bundle_status[$key]}" == *"$diff"* ]]; then
			bundle_status="$diff"
		fi
	done

	echo "#####################################"	
	echo "Target Bundle: $target_bundle $bundle_status"
	echo "Components:"
	
	# Loop through target components and print status/version
	for key in "${!target_bundle_components[@]}"; do
		local status="${target_bundle_status[$key]}"
		local version="${target_bundle_components[$key]}"
		
		# Default to minus if status is missing
		[[ -z "$status" ]] && status="$minus"
		
		printf " %-10b %-15s (v%s)\n" "$status" "${key^}" "$version"
	done
	echo "######################################"
}
dashboard() { # for now its dev dashboard
	local bundle_dir="$bundles_dir/$target_bundle"

	[[ -d "$bundle_dir" ]] || mkdir -p "$bundle_dir"
	# echo web latest and all the budles info
	echo "Dashboard"
	# here ill add some info about the system, like the current distro, the latest version of the bundles, etc.
}

toggle_install_mode() { # shift right [rookie -> force -> interactive -> rookie]
	[[ "$install_mode" == "rookie" ]] && install_mode="force" && return 0
	[[ "$install_mode" == "force" ]] && install_mode="interactive" && return 0
	[[ "$install_mode" == "interactive" ]] && install_mode="rookie" && return 0
}

target_bundle_menu(){ # 1
	while true; do
		target_bundle_info_list
		echo "1) "
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			1) echo aka ;;
			x|X) return 0 ;;
			*) echo "Invalid option. Please try again." ;;
		esac
	done
}

select_bundle_menu() { # 2
	while true; do
		list_bundles
		echo "x) Back to Main Menu"
		echo "Select Bundle: "

		read -rp "Select an option: " option
		case $option in # ill fix it later
			x|X) return 0 ;;
			0) 
				target_bundle="vNext"
				target_bundle_map_components
				target_bundle_update_status
				echo "Selected Bundle: ${target_bundle}"
				return 0
				;;
			*) 
				if [[ "$option" =~ ^[0-9]+$ ]] && (( option > 0 && option <= ${#bundles_versions[@]} )); then
					idx=${bundle_idxes[option-1]}
					target_bundle="${bundles_versions[idx]}"
					target_bundle_map_components
					target_bundle_update_status
					echo "Selected Bundle: ${target_bundle}"
					return 0
				else
					echo "Invalid option. Please try again."
				fi
				;;
		esac
	done
}
maintenance_menu() { # later
	while true; do
		echo "Maintenance Menu"
		echo "1) Update All Components"
		echo "2) Clean Vault (Delete all cloned repos)"
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			1) echo Update All ;;
			2) echo Clean Vault ;;
			x|X) return 0 ;;
			*) echo "Invalid option. Please try again." ;;
		esac
	done
}

info_page() { # Professional Hub Manual
	local info_content=$(cat << EOF
${SKY_BLUE}###########################################################${RESET}
##                 ${GREEN}DOTFILES HUB v2 - MANUAL${RESET}              ##
###########################################################

${YELLOW}1. STATUS INDICATORS${RESET}
${ok}  : System version matches the Hub's Matrix bundle.
${diff}  : A rice is installed, but the version is different.
${sync}  : Repo is in the Hub's vault, but NOT on your system.
${minus}  : Component is neither downloaded nor installed.
${exclamation}  : GitHub has a newer tag than your local Matrix.

${YELLOW}2. DEPLOYMENT MODES${RESET}
- ${GREEN}rookie${RESET}      : Backup -> Install App -> Apply Dots (Safe).
- ${ORANGE}force${RESET}       : Overwrite existing configs without backup.
- ${SKY_BLUE}interactive${RESET} : Step-by-step confirmation for every action.

${YELLOW}3. CONTROLS${RESET}
- ${WHITE}q${RESET} : Return to main menu.
- ${WHITE}Arrows${RESET} : Scroll through this manual.

${SKY_BLUE}###########################################################${RESET}
##              STAY CHILLY - Built by netchunk          ##
###########################################################
EOF
)
	echo -e "$info_content" | less -R
}

main_menu() {
	while true; do
		target_bundle_info_list
		echo "Main Menu"
		echo "1) Bundle: ${target_bundle} (menu)"
		echo "2) Switch Bundle (menu)" # first thing to make
		echo "m) Toggle Install Mode (Current: $install_mode)"
		echo "w) wallpapers (menu)" # later
		echo "t) themes (menu)" # later
		echo "s) maintenance (menu)" # later
		echo "i) info"
		echo "x) Exit"

		read -rp "Select an option: " option
		case $option in
			1) target_bundle_menu ;;
			2) select_bundle_menu ;;
			m) toggle_install_mode ;;
			i) info_page ;;
			x) echo "Exiting..."; exit 0 ;;
			*) echo "Invalid option. Please try again." ;;
		esac
	done
}
#main_menu

init(){
	bundles_versions=($(echo_bundle_versions))
	target_bundle="${bundles_versions[${#bundles_versions[@]}-1]}" # set it to the latest available in matrixfile	
	
	fetch_latest_versions & # Run in background to speed up the init
	pid_store "fetch_latest_versions" $! # Store its PID for later synchronization

	target_bundle_map_components # Map components for the initially selected bundle
	target_bundle_update_status # Update statuses based on the initial mapping
         
	if [[ -z $1 ]]; then
		main_menu
		return 0
	fi

	# --- Silent Execution Dispatcher ---
	case "$1" in
		"bundles") # Example: Raw output of available bundles
			(IFS=':'; echo "${bundles_versions[*]}")
			;;
		"install") # Future: automated install
			# target_bundle_clone
			# deploy_all
			;;
		"force") # Future: automated force install
			# install_mode="force"
			# target_bundle_clone
			# deploy_all
			;;
		*)
			echo "Silent Mode Error: Unknown argument '$1'"
			exit 1
			;;
	esac
}

init "$@"