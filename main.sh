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
	declare -g -A target_bundle_status=() # exclucive --------------------
	# e.g., hyprland -> [ OK ] , ... must update_target_bundle_status() after every action on the components of the target bundle, like clone, install, etc. and also after switching to another bundle
	declare -g -A web_versions # e.g., hyprland -> 1.2.0 (latest on github), ... must fetch_latest_versions() in init()
	#(IFS='|';echo "Loaded bundles: ${bundles[*]}")
	declare -g -A local_versions # e.g., hyprland -> 1.2.0 (from live paths)

	# for other processes
	declare -g -a bundle_idxes=()


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
	local -i index=1
	bundle_idxes=() # reset indexes
	
	for ((i=0;i<${#bundles_versions[@]};i++)); do
		echo "$index) [${bundles_versions[i]}]"
		bundle_idxes+=($i)
		((index++))
	done

	# JOIN: Wait and then collect in main shell
	wait_pid "fetch_latest_versions"
	collect_web_versions
	target_bundle_update_status # Refresh statuses with new web data
	# i want it to print that thing below only if the latest collected web versions are newer than the last version from matrix 
	# later ....
	{
		echo "g) [Github Latest]"
	}

}

local_bundle_map_versions(){
	declare -g -A local_versions=() # reset components globally

	for key in ${!components[@]};do
		local meta="${components[$key]}"
		[[ "$meta" != "dotfile|"* ]] && continue

		local arr
		local IFS='|';read -ra arr <<< "$meta"

		local path="${arr[4]}"

		[[ -f "$path/.version" ]] && local version="$(<"$path/.version")"

		local_versions[$key]="$version"
	done

}
target_bundle_map_components() {
	target_bundle_components=() # reset components (hits nearest local or global)
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

		# 1. Status Logic: Handle missing state first, then reality/sync
		local status
		if [[ ! -d "$bundles_dir/$target_bundle/${data[2]}" ]]; then
			status="$minus"
		elif [[ -f "$live_path/.version" ]]; then
			local live_v=$(<"$live_path/.version")
			local comp=$(compareVersions "$live_v" "$m_ver")
			[[ "$comp" == "equal" ]] && status="$ok" || status="$diff"
		else
			status="$sync"
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
		local folder="${data[2]}"
		local installer_script="${data[3]}"
		local conj="$folder/$installer_script"
		#local live_path="${data[4]}"

		if [[ -f "$bundles_dir/$target_bundle/$conj" ]]; then
			if [[ "$install_mode" == "interactive" ]]; then
				echo -e "running $conj (v${target_bundle_components[$key]})"
				# must be ran from from its dir
				(cd "$bundles_dir/$target_bundle/$folder"; "./$installer_script")
				target_bundle_update_status # Update status after each install
			elif [[ "$install_mode" == "rookie" ]];then
				echo -e "running $conj (v${target_bundle_components[$key]})"
				# must be ran from from its dir
				(cd "$bundles_dir/$target_bundle/$folder"; "./$installer_script" "$install_mode")
				target_bundle_update_status # Update status after each install
			elif [[ "$install_mode" == "force" ]];then
				echo -e "running $conj (v${target_bundle_components[$key]})"
				# must be ran from from its dir
				(cd "$bundles_dir/$target_bundle/$folder"; "./$installer_script" "$install_mode")
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
	declare -i idx=1
	# Loop through target components and print status/version
	for key in "${!target_bundle_components[@]}"; do
		local status="${target_bundle_status[$key]}"
		local version="${target_bundle_components[$key]}"
		
		# Default to minus if status is missing
		[[ -z "$status" ]] && status="$minus"
		
		printf " %-2b) %-10b %-15s (v%s)\n" "$idx" "$status" "${key^}" "$version"
		((idx++))
	done
	echo "######################################"
}
dashboard() { # for now its dev dashboard
	# These locals "shadow" the globals for this function AND all children called within it
	local target_bundle
	local -A target_bundle_components
	local -A target_bundle_status

	for target_bundle in "${bundles_versions[@]}" "vNext"; do
		target_bundle_map_components
		target_bundle_update_status
		target_bundle_info_list
	done
	# When dashboard ends, locals are destroyed and globals automatically reappear.
}

toggle_install_mode() { # shift right [rookie -> force -> interactive -> rookie]
	[[ "$install_mode" == "rookie" ]] && install_mode="force" && return 0
	[[ "$install_mode" == "force" ]] && install_mode="interactive" && return 0
	[[ "$install_mode" == "interactive" ]] && install_mode="rookie" && return 0
}

target_bundle_remove_menu(){
	# 1. Create a stable list of keys so indices match what the user sees
	local -a keys_list=()
	for k in "${!target_bundle_components[@]}"; do
		keys_list+=("$k")
	done

	while true; do
		reset
		target_bundle_info_list
		echo "Choose component(s) to remove from vault:"
		echo "(e.g. 1 / 1,3,4 / 1-3 / all / x to back)"

		local option
		read -r option
		[[ "$option" == "x" || "$option" == "X" ]] && return 0

		# 2. Parse input into individual numbers
		local -a selected_nums=()
		local -a parts
		IFS=',' read -ra parts <<< "$option"

		for p in "${parts[@]}"; do
			p="${p// /}" # shrink spaces
			if [[ "$p" == "all" || "$p" == "ALL" ]]; then
				selected_nums=() # Clear to avoid duplicates
				for ((i=1; i<=${#keys_list[@]}; i++)); do
					selected_nums+=("$i")
				done
				break
			fi
			if [[ "$p" == *-* ]]; then
				local start="${p%-*}"
				local end="${p#*-}"
				# Validate numeric range
				if [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
					for ((i=start; i<=end; i++)); do
						selected_nums+=("$i")
					done
				fi
			else
				selected_nums+=("$p")
			fi
		done

		# 3. Execute deletion based on stable indices
		for num in "${selected_nums[@]}"; do
			# Validate number is in range
			if [[ "$num" =~ ^[0-9]+$ ]] && (( num > 0 && num <= ${#keys_list[@]} )); then
				local comp_key="${keys_list[$((num-1))]}"
				local meta="${components[$comp_key]}"

				local -a meta_arr
				IFS='|' read -ra meta_arr <<< "$meta"
				local folder="${meta_arr[2]}"
				local path="$bundles_dir/$target_bundle/$folder"

				if [[ -d "$path" ]]; then
					echo -e "${ORANGE}Removing --> $path${RESET}"
					rm -rf "$path" && echo -e "${GREEN}Removed successfully.${RESET}"
				else
					echo -e "${YELLOW}Notice: Component '$comp_key' not found in vault.${RESET}"
				fi
			fi
		done
		read -rp "Action complete. Press enter to refresh..."
	done
}
target_bundle_menu(){ # 1
	while true; do
		reset
		target_bundle_info_list
		echo "0) clone/init"
		echo "1) $msg_exec"
		echo "2) uinstall bundle components (all/single/selective)!" # e.g. all/3,4,6-9/4
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			0) target_bundle_clone ;;
			1) target_bundle_deploy ;;
			2) target_bundle_remove_menu ;;
			x|X) return 0 ;;
			*) echo "Invalid option. Please try again." ;;
		esac
	done
}

select_bundle_menu() { # 2
	reset
	while true; do
		list_bundles
		echo "x) Back to Main Menu"
		echo "Select Bundle: "

		read -rp "Select an option: " option
		case $option in # ill fix it later
			x|X) return 0 ;;
			g) 
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
	reset
	while true; do
		# list all bundles downloaded here to chose from
		echo "Maintenance Menu"
		#echo "1) Update All Components"
		echo "1) Clean bundles"
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			#1) echo Update All ;;
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
			d) echo -e "$(dashboard)" | less -R ;;
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
	
	# Default State
	local ACTION=""
	local COMP_TYPE=""
	target_bundle="${bundles_versions[${#bundles_versions[@]}-1]}" # Default to latest in matrix
	
	# --- Flag Parser (Non-Positional) ---
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-m|--mode)
				if [[ "$2" =~ ^(rookie|force|interactive)$ ]]; then
					install_mode="$2"
					shift 2
				else
					echo -e "${RED}Error: Invalid mode '$2'. Valid options: rookie, force, interactive${RESET}"
					exit 1
				fi
				;;
			-b|--bundle)
				local found=false
				for v in "${bundles_versions[@]}" "vNext"; do
					[[ "$v" == "$2" ]] && found=true && break
				done
				if $found; then
					target_bundle="$2"
					shift 2
				else
					echo -e "${RED}Error: Invalid bundle '$2'. Use 'bundles' to see available options.${RESET}"
					exit 1
				fi
				;;
			-t|--type)
				local found_type=false
				for val in "${components[@]}"; do
					if [[ "${val%%|*}" == "$2" ]]; then
						found_type=true
						break
					fi
				done
				if $found_type; then
					COMP_TYPE="$2"
					shift 2
				else
					echo -e "${RED}Error: Invalid type '$2'. Available in registry: $(for v in "${components[@]}"; do echo "${v%%|*}"; done | sort -u | xargs)${RESET}"
					exit 1
				fi
				;;
			bundles|install|force|check-update|update|components|components-n|count)
				ACTION="$1"
				shift
				;;
			*)
				echo -e "${RED}Error: Unknown argument '$1'${RESET}"
				exit 1
				;;
		esac
	done

	fetch_latest_versions & # Run in background to speed up the init
	pid_store "fetch_latest_versions" $! # Store its PID for later synchronization

	target_bundle_map_components # Map components for the selected bundle
	target_bundle_update_status # Update statuses based on the mapping
         
	if [[ -z "$ACTION" ]]; then
		main_menu
		return 0
	fi

	# --- Silent Execution Dispatcher ---
	case "$ACTION" in
		"bundles")
			(IFS=':'; echo "${bundles_versions[*]}")
			;;
		"components"|"components-n"|"count")
			local -a filtered_keys=()
			for k in "${!components[@]}"; do
				if [[ -z "$COMP_TYPE" ]] || [[ "${components[$k]%%|*}" == "$COMP_TYPE" ]]; then
					filtered_keys+=("$k")
				fi
			done
			
			if [[ "$ACTION" == "components" ]]; then
				(IFS=':'; echo "${filtered_keys[*]}")
			else
				echo "${#filtered_keys[@]}"
			fi
			;;
		"install")
			target_bundle_clone
			target_bundle_deploy
			;;
		"force")
			install_mode="force"
			target_bundle_clone
			target_bundle_deploy
			;;
		#"check-update") 
		#	echo "Checking for updates..."
		#	wait_pid "fetch_latest_versions"
		#	collect_web_versions
		#	target_bundle_update_status
		#	# This will populate target_bundle_status with web update [!!] flags
		#	target_bundle_info_list
		#	;;
		"check-update") echo "will return if has any update after the current installed bundle" ;;                                              │ │
		# either it can return we have if a propern new bundle is found or let user know if he is able to test the                              │ │
		# THE few updated components even if ne bundle isnt found                                                                               │ │
		# for it i have to implement a mechanism to findout which version is installed RN
		"update")
			echo "will return if ... "
			;;
		*)
			exit 1
			;;
	esac
}

init "$@"