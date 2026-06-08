#!/usr/bin/env bash


# key <--> type|link|folder|installer|live-ver-dest
declare -A components=(
	["hyprland"]="dotfile|https://github.com/corechunk/hyprland.git|hyprland|installer_hyprland_dots.sh|$HOME/.config/hypr"
    ["waybar"]="dotfile|https://github.com/corechunk/waybar.git|waybar|installer_waybar_dots.sh|$HOME/.config/waybar"
    ["quickshell"]="dotfile|https://github.com/corechunk/quickshell.git|quickshell|installer_quickshell_dots.sh|$HOME/.config/quickshell"
    ["wallust"]="dotfile|https://github.com/corechunk/wallust.git|wallust|installer_wallust_dots.sh|$HOME/.config/wallust"
    ["fastfetch"]="dotfile|https://github.com/corechunk/fastfetch.git|fastfetch|installer_fastfetch_dots.sh|$HOME/.config/fastfetch"
    ["neovim"]="dotfile|https://github.com/corechunk/Neovim.git|neovim|installer_nvim_dots.sh|$HOME/.config/nvim"
    ["kitty"]="dotfile|https://github.com/corechunk/Kitty.git|kitty|installer_kitty_dots.sh|$HOME/.config/kitty"
    ["bash"]="dotfile|https://github.com/corechunk/Bash.git|bash|installer_bash_dots.sh|$HOME"
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
	# declare -g RED=$(tput setaf 1)
	# declare -g GREEN=$(tput setaf 2)
	# declare -g YELLOW=$(tput setaf 3)
	# declare -g ORANGE=$(tput setaf 166)
	# declare -g SKY_BLUE=$(tput setaf 6)
	# declare -g MAGENTA=$(tput setaf 5)
	# declare -g WHITE=$(tput setaf 7)
	# declare -g RESET=$(tput sgr0)
	declare -g RED=$'\e[31m'
	declare -g GREEN=$'\e[32m'
	declare -g YELLOW=$'\e[33m'
	declare -g ORANGE=$'\e[38;5;166m'
	declare -g SKY_BLUE=$'\e[36m'
	declare -g MAGENTA=$'\e[35m'
	declare -g WHITE=$'\e[37m'
	declare -g RESET=$'\e[0m'
	declare -g RED=$'\e[31m'
	declare -g GREEN=$'\e[32m'
	declare -g YELLOW=$'\e[33m'
	declare -g ORANGE=$'\e[38;5;166m'
	declare -g SKY_BLUE=$'\e[36m'
	declare -g MAGENTA=$'\e[35m'
	declare -g WHITE=$'\e[37m'
	declare -g RESET=$'\e[0m'
	declare -g RED=$'\e[31m'
	declare -g GREEN=$'\e[32m'
	declare -g YELLOW=$'\e[33m'
	declare -g ORANGE=$'\e[38;5;166m'
	declare -g SKY_BLUE=$'\e[36m'
	declare -g MAGENTA=$'\e[35m'
	declare -g WHITE=$'\e[37m'
	declare -g RESET=$'\e[0m'
	# Status Indicators
	declare -g ok="${GREEN}[ OK ]${RESET}"
	declare -g diff="${YELLOW}[DIFF]${RESET}"
	declare -g sync="${SKY_BLUE}[SYNC]${RESET}"
	declare -g minus="${RED}[ -- ]${RESET}"
	declare -g exclamation="${ORANGE}[!!]${RESET}"
	declare -g vault_sync="${SKY_BLUE}Vault Sync${RESET}"
	declare -g selected="${GREEN}[#]${RESET}"

	# Hex to RGB Utility
	hex_to_rgb() {
		local hex="${1#\#}"
		[[ ${#hex} -ne 6 ]] && { echo "0 0 0"; return 1; }
		local r=$((16#${hex:0:2}))
		local g=$((16#${hex:2:2}))
		local b=$((16#${hex:4:2}))
		echo "$r $g $b"
	}

	# Directories
	declare -g script_dir=$(pwd)
	declare -g processing_dir="$script_dir/processing"
	declare -g bundles_dir="$processing_dir/bundles"
	declare -g assets_dir="$processing_dir/assets"
	declare -g wallpapers_dir="$assets_dir/wallpapers"
	declare -g themes_dir="$assets_dir/themes"
	declare -g hub_tmp="/tmp/corechunk/dotfiles"
	# Files
	declare -g matrixFileName="matrix.txt"
	declare -g matrix_file="$processing_dir/$matrixFileName"
	# Other variables
	declare -g install_mode="rookie"
	declare -g install_mode_styled="${GREEN}rookie${RESET}"
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
	[[ -d "$hub_tmp" ]] || mkdir -p "$hub_tmp"
	# Create matrix file if it doesn't exist
	[[ -f "$matrix_file" ]] || { echo "Error: File not found: $matrix_file"; exit 1;}

	deinit() {
		# echo -e "\n${ORANGE}Cleaning up temporary files...${RESET}"
		rm -rf "$hub_tmp"
		exit 0
	}

	trap deinit EXIT INT TERM
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
		echo $tag > "$hub_tmp/${key}.version"
	) &
	done
}

collect_web_versions() { # Read data from $hub_tmp into main memory
	for key in "${!components[@]}";do
		if [[ -f "$hub_tmp/${key}.version" ]]; then
			web_versions["$key"]="$(<"$hub_tmp/${key}.version")"
			rm "$hub_tmp/${key}.version"
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

comp_clone() {
	local key="$1"
	local -i is_async="$2"  # 1 = Background, 0 = Foreground

	local meta="${components[$key]}"
	local -a meta_arr
	local IFS='|'; read -ra meta_arr <<< "$meta"
	local type="${meta_arr[0]}"
	local link="${meta_arr[1]}"
	local folder="${meta_arr[2]}"

	local dest
	case "$type" in
		"dotfile")   dest="$bundles_dir/$target_bundle/$folder" ;;
		"wallpaper") dest="$wallpapers_dir/$folder" ;;
		"theme")     dest="$themes_dir/$folder" ;;
		*)           echo "Unknown type: $type"; return 1 ;;
	esac

	[[ -d "$dest" ]] && { touch "$hub_tmp/${key}.done"; return 0; } # Mark as done if exists

	local tag="${target_bundle_components[$key]}"
	local cmd="git clone --progress --depth 1"
	if [[ "$tag" != "N/A" && -n "$tag" ]]; then
		cmd="$cmd --branch v$tag $link $dest || $cmd --branch $tag $link $dest"
	else
		cmd="$cmd $link $dest"
	fi

	# Execution Block
	clone_logic() {
		# Redirect stderr to stdout, then convert \r to \n for clean log parsing
		if eval "$cmd" 2>&1 | stdbuf -oL tr '\r' '\n' > "$hub_tmp/${key}.log"; then
			touch "$hub_tmp/${key}.done"
		else
			echo "Error: Cloning $key failed." >> "$hub_tmp/${key}.log"
			# Marker must be touched even on failure to avoid hanging the progress bar
			touch "$hub_tmp/${key}.done"
		fi
	}

	if (( is_async )); then
		clone_logic &
		pid_store "clone_${type}_${key}" $!
	else
		clone_logic
	fi
}

batch_clone() {
	local label="$1"
	shift
	local -a keys=("$@")
	local total=${#keys[@]}
	(( total == 0 )) && return 0

	# Ensure hub_tmp is clean for markers
	rm -f "$hub_tmp"/*.done

	# 1. Run the entire loop in background
	(
		for key in "${keys[@]}"; do
			echo "Syncing $key..." > "$hub_tmp/sync.log"
			comp_clone "$key" 0 # Run internally as foreground because the whole loop is BG
		done
	) &
	pid_store "batch_clone" $!

	# 2. Trigger Multiplexed TUI Progress Bar (P: and M: tags)
	(
		file_count_feeder "$total" 30 "$hub_tmp" "*.done" | count_percent_emitter "$total" "v2" &
		file_log_feeder "$hub_tmp/sync.log" 20 &
		wait
	) | ui_tui_progress_bar_v2 -l "$label" --start "#0000FF" --end "#00FF00"

	wait_pid "batch_clone"
	rm -f "$hub_tmp"/*.done "$hub_tmp/sync.log"
}

target_bundle_clone() {
	local -a keys=()
	for k in "${!target_bundle_components[@]}"; do
		keys+=("$k")
	done
	batch_clone "Vault Sync" "${keys[@]}"
	target_bundle_update_status # Refresh status after batch clone
}

deploy_component() {
	local key="$1"
	local meta="${components[$key]}"
	local -a data; IFS='|' read -ra data <<< "$meta"
	local type="${data[0]}"
	local folder="${data[2]}"
	local installer_script="${data[3]}"
	
	local base_path
	if [[ "$type" == "dotfile" ]]; then
		base_path="$bundles_dir/$target_bundle"
	elif [[ "$type" == "wallpaper" ]]; then
		base_path="$wallpapers_dir"
	elif [[ "$type" == "theme" ]]; then
		base_path="$themes_dir"
	fi

	local full_path="$base_path/$folder"
	local script_path="$full_path/$installer_script"

	if [[ -f "$script_path" ]]; then
		echo -e "${SKY_BLUE}Deploying ${key^} (v${target_bundle_components[$key]:-persistent})...${RESET}"
		
		# Map Hub modes to Leaf arguments
		local mode_arg=""
		case "$install_mode" in
			"rookie")      mode_arg="backup+install+app" ;;
			"force")       mode_arg="installForce" ;;
			"backup")      mode_arg="backup" ;;
			"restore")     mode_arg="restore" ;;
			"interactive") mode_arg="" ;; # Passes no arg to trigger leaf menu
			*)             mode_arg="$install_mode" ;;
		esac

		(
			cd "$full_path"
			if [[ -n "$mode_arg" ]]; then
				bash "./$installer_script" "$mode_arg"
			else
				bash "./$installer_script"
			fi
		)
		target_bundle_update_status # Refresh status after each install
	else
		echo -e "${RED}Error: Installer not found at $script_path${RESET}"
	fi
}

target_bundle_deploy_menu() {
	# 1. Create a stable list of keys so indices match what the user sees
	local -a keys_list=()
	for k in "${!target_bundle_components[@]}"; do
		keys_list+=("$k")
	done

	while true; do
		reset
		target_bundle_info_list
		echo "Select component(s) to DEPLOY:"
		echo "(e.g. 1 / 1,3 / 1-3 / all / x to back)"

		local option
		read -r option
		[[ "$option" == "x" || "$option" == "X" ]] && return 0

		# 2. Pipeline: Parse -> Expand -> Validate
		local raw_expansion=$(parse_selection_input "$option" ",") || { echo -e "${RED}Error: Invalid syntax.${RESET}"; sleep 1; continue; }
		local full_list=$(expand_selection_all "${#keys_list[@]}" $raw_expansion)
		validate_selection_range "${#keys_list[@]}" $full_list || { echo -e "${RED}Error: One or more indices are out of range.${RESET}"; sleep 1; continue; }

		# 3. Execute deployment based on validated indices
		local -a selected_nums=($full_list)
		for num in "${selected_nums[@]}"; do
			local comp_key="${keys_list[$((num-1))]}"
			deploy_component "$comp_key"
		done
		read -rp "Action complete. Press enter to refresh..."
	done
}
target_bundle_info_list(){
	local bundle_status="$ok"
	local has_minus=false
	local has_diff=false
	local has_sync=false
	local has_excl=false

	# 1. Gather component states from the pre-calculated status map
	for key in "${!target_bundle_components[@]}"; do
		local st="${target_bundle_status[$key]}"
		[[ "$st" == *"$minus"* ]] && has_minus=true
		[[ "$st" == *"$diff"* ]] && has_diff=true
		[[ "$st" == *"$sync"* ]] && has_sync=true
		[[ "$st" == *"$exclamation"* ]] && has_excl=true
	done

	# 2. Apply Priority: Minus > Diff > Sync > Exclamation
	if $has_minus; then
		bundle_status="$minus"
	elif $has_diff; then
		bundle_status="$diff"
	elif $has_sync; then
		bundle_status="$sync"
	elif $has_excl; then
		bundle_status="$exclamation"
	fi

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

toggle_install_mode() { # cycle: rookie -> force -> interactive -> backup -> restore
	local color
	case "$install_mode" in
		"rookie")      install_mode="force";       color="$RED" ;;
		"force")       install_mode="interactive"; color="$MAGENTA" ;;
		"interactive") install_mode="backup";      color="$YELLOW" ;;
		"backup")      install_mode="restore";     color="$SKY_BLUE" ;;
		"restore")     install_mode="rookie";      color="$GREEN" ;;
		*)             install_mode="rookie";      color="$GREEN" ;;
	esac
	install_mode_styled="${color}${install_mode}${RESET}"
}

# --- UI Engine ---

# 1. Logic Layer: Monitors a directory for files matching a pattern and emits raw finished count
# Args: $1=Total, $2=Hz, $3=Directory, $4=Pattern
file_count_feeder() {
	local total=$1
	local hz=${2:-10}
	local dir="${3:-$hub_tmp}"
	local pattern="${4:-*.done}"
	local finished=0
	
	# Convert Hz to decimal interval (Bash Integer Scaling)
	local ms=$(( 1000 / hz ))
	local interval=$(printf "%d.%03d" $(( ms / 1000 )) $(( ms % 1000 )))

	while (( finished < total )); do
		local files=( "$dir"/$pattern )
		finished=${#files[@]}
		[[ -e "${files[0]}" ]] || finished=0
		
		echo "$finished"
		sleep "$interval"
	done
}

# 2. Math Layer: Converts raw count to 0-100 stream
# Args: $1=Total, $2=Format (optional: "v2" for P: tag)
count_percent_emitter() {
	local total=$1
	local format="$2"
	while read -r count; do
		local percent=$(( (count * 100) / total ))
		if [[ "$format" == "v2" ]]; then
			echo "P:$percent"
		else
			echo "$percent"
		fi
		[[ $percent -ge 100 ]] && break
	done
}

# 3. Log Layer: Monitors a specific file and emits M: tag
# Args: $1=LogFile, $2=Hz (Default: 5)
file_log_feeder() {
	local logfile="$1"
	local hz=${2:-5}
	
	local ms=$(( 1000 / hz ))
	local interval=$(printf "%d.%03d" $(( ms / 1000 )) $(( ms % 1000 )))

	while [[ -f "$logfile" ]]; do
		local line=$(tail -n 1 "$logfile" | cut -c 1-50)
		echo "M:$line"
		sleep "$interval"
	done
}

# 3. Renderer Layer: 60 FPS TrueColor Progress Bar
# Line 1: [Percent] [Label] | Line 2: [Bar]
ui_tui_progress_bar() {
	local label="Progress"
	local r1=0; local g1=0; local b1=255 # Default Start: Blue
	local r2=0; local g2=255; local b2=0  # Default End: Green

	# Simple Flag Parser
	if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
		label="$1"; shift
	fi
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-l|--label) label="$2"; shift 2 ;;
			-h|--hex|--start) read r1 g1 b1 < <(hex_to_rgb "$2"); shift 2 ;;
			--end) read r2 g2 b2 < <(hex_to_rgb "$2"); shift 2 ;;
			-rgb|--rgb) r1=$(echo "$2" | cut -d' ' -f1); g1=$(echo "$2" | cut -d' ' -f2); b1=$(echo "$2" | cut -d' ' -f3); shift 2 ;;
			*) shift ;;
		esac
	done

	local margin=2
	local bar_source="████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
	local empty_source="------------------------------------------------------------------------------------------------------------------------------------------------------"

	while read -r percent; do
		local width=${COLUMNS:-$(tput cols)}
		local bar_max=$(( width - (margin * 2) - 2 ))
		(( bar_max < 10 )) && bar_max=10

		local r_now=$(( r1 + (r2 - r1) * percent / 100 ))
		local g_now=$(( g1 + (g2 - g1) * percent / 100 ))
		local b_now=$(( b1 + (b2 - b1) * percent / 100 ))
		local color_esc="\033[38;2;${r_now};${g_now};${b_now}m"

		local filled_count=$(( bar_max * percent / 100 ))
		local empty_count=$(( bar_max - filled_count ))
		local blocks="${bar_source:0:filled_count}"
		local spaces="${empty_source:0:empty_count}"

		# Draw 2 Lines (Header and Bar both colored)
		printf "\r\033[K%${margin}s ${color_esc}%3d%% %s\033[0m\n" "" "$percent" "$label"
		printf "\033[K%${margin}s${color_esc}%s\033[38;2;60;60;60m%s\033[0m" "" "$blocks" "$spaces"
		
		[[ $percent -ge 100 ]] && break
		printf "\033[A" # Move UP 1 line to return to start
		sleep 0.016
	done
	printf "\n\n" # Release both lines
}

# 60 FPS 3-Line Multiplexed UI Engine
# Protocol: P:[0-100] for Progress | M:[String] for Message
# Uses non-blocking reads for fluid color transitions.
ui_tui_progress_bar_v2() {
	local label="Progress"
	local r1=0; local g1=0; local b1=255
	local r2=0; local g2=255; local b2=0

	# Simple Flag Parser
	if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
		label="$1"; shift
	fi
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-l|--label) label="$2"; shift 2 ;;
			-h|--hex|--start) read r1 g1 b1 < <(hex_to_rgb "$2"); shift 2 ;;
			--end) read r2 g2 b2 < <(hex_to_rgb "$2"); shift 2 ;;
			-rgb|--rgb) r1=$(echo "$2" | cut -d' ' -f1); g1=$(echo "$2" | cut -d' ' -f2); b1=$(echo "$2" | cut -d' ' -f3); shift 2 ;;
			*) shift ;;
		esac
	done

	local margin=2
	local bar_source="████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
	local empty_source="------------------------------------------------------------------------------------------------------------------------------------------------------"
	
	local percent=0
	local msg="Waiting for signal..."

	while true; do
		# Non-blocking read (0.01s timeout)
		if read -t 0.01 -r line; then
			case "$line" in
				P:*) percent="${line#P:}" ;;
				M:*) msg="${line#M:}" ;;
			esac
		elif [[ $? -le 128 ]]; then
			# Pipe closed/EOF
			break
		fi

		# --- RENDER FRAME ---
		local width=${COLUMNS:-$(tput cols)}
		local bar_max=$(( width - (margin * 2) - 2 ))
		(( bar_max < 10 )) && bar_max=10

		local r_now=$(( r1 + (r2 - r1) * percent / 100 ))
		local g_now=$(( g1 + (g2 - g1) * percent / 100 ))
		local b_now=$(( b1 + (b2 - b1) * percent / 100 ))
		local color_esc="\033[38;2;${r_now};${g_now};${b_now}m"

		local filled_count=$(( bar_max * percent / 100 ))
		local blocks="${bar_source:0:filled_count}"
		local spaces="${empty_source:0:$((bar_max - filled_count))}"

		# Line 1: Header (Colored)
		printf "\r\033[K%${margin}s ${color_esc}%3d%% %s\033[0m\n" "" "$percent" "$label"
		# Line 2: The Bar (Colored)
		printf "\033[K%${margin}s${color_esc}%s\033[38;2;60;60;60m%s\033[0m\n" "" "$blocks" "$spaces"
		# Line 3: Dynamic Message (Dimmed)
		printf "\033[K%${margin}s \033[2m➜ %s\033[0m" "" "$msg"

		[[ $percent -ge 100 ]] && break
		printf "\033[2A" # Move UP 2 lines to return to start
		sleep 0.016
	done
	printf "\n\n\n" # Release all 3 lines
}

# --- UI Bar V3: The Quantum Console ---
# Mode A (Linear): Input is 0-100.
# Mode B (Tagged): Input uses P: [0-100], M: [Status], L: [Log Entry]
# Args: -l|--label, -t|--tagged, --log-height [n], --start|--end [hex]
ui_tui_progress_bar_v3() {
	local label="Progress"
	local tagged=false
	local log_height=3
	local r1=0; local g1=0; local b1=255 # Default Start: Blue
	local r2=0; local g2=255; local b2=0  # Default End: Green

	# Flag Parser
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-l|--label) label="$2"; shift 2 ;;
			-t|--tagged) tagged=true; shift ;;
			--log-height) log_height="$2"; shift 2 ;;
			-h|--hex|--start) read r1 g1 b1 < <(hex_to_rgb "$2"); shift 2 ;;
			--end) read r2 g2 b2 < <(hex_to_rgb "$2"); shift 2 ;;
			*) shift ;;
		esac
	done

	local margin=2
	local bar_source="████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
	local empty_source="------------------------------------------------------------------------------------------------------------------------------------------------------"
	
	local percent=0
	local status_msg="Initializing..."
	local -a log_buffer=()
	for ((i=0; i<log_height; i++)); do log_buffer[i]=""; done

	while true; do
		# Non-blocking read (0.01s timeout)
		if read -t 0.01 -r line; then
			if $tagged; then
				case "$line" in
					P:*) percent="${line#P:}" ;;
					M:*) status_msg="${line#M:}" ;;
					L:*) 
						local raw_msg="${line#L:}"
						local w=${COLUMNS:-80}
						local max_w=$((w - margin - 5))
						((max_w < 10)) && max_w=10

						# Wrap by splitting into chunks and pushing each as a new log line
						while [[ -n "$raw_msg" ]]; do
							local chunk="${raw_msg:0:$max_w}"
							raw_msg="${raw_msg:$max_w}"
							
							# Shift logs up
							for ((i=0; i<log_height-1; i++)); do 
								log_buffer[i]="${log_buffer[i+1]}"
							done
							log_buffer[$((log_height-1))]="$chunk"
						done
						;;
				esac
			else
				# Linear Mode: Expect pure numbers
				if [[ "$line" =~ ^[0-9]+$ ]]; then
					percent="$line"
				fi
			fi
		elif [[ $? -le 128 ]]; then
			# Pipe closed/EOF
			break
		fi

		# --- RENDER FRAME ---
		local width=${COLUMNS:-$(tput cols)}
		local bar_max=$(( width - (margin * 2) - 2 ))
		(( bar_max < 10 )) && bar_max=10

		local r_now=$(( r1 + (r2 - r1) * percent / 100 ))
		local g_now=$(( g1 + (g2 - g1) * percent / 100 ))
		local b_now=$(( b1 + (b2 - b1) * percent / 100 ))
		local color_esc="\033[38;2;${r_now};${g_now};${b_now}m"

		local filled_count=$(( bar_max * percent / 100 ))
		local blocks="${bar_source:0:filled_count}"
		local spaces="${empty_source:0:$((bar_max - filled_count))}"

		# Line 1: Header
		printf "\r\033[K%${margin}s ${color_esc}%3d%% %s\033[0m\n" "" "$percent" "$label"
		# Line 2: The Bar
		printf "\033[K%${margin}s${color_esc}%s\033[38;2;60;60;60m%s\033[0m" "" "$blocks" "$spaces"

		local lines_to_reset=1 # Current line is Line 2, so we need to move up 1 line to get back to Line 1

		if $tagged; then
			# Line 3: Status Message
			printf "\n\033[K%${margin}s \033[1;34m➜\033[0m %s" "" "$status_msg"
			lines_to_reset=$((lines_to_reset + 1))

			# Lines 4+: Scrolling Logs
			for ((i=0; i<log_height; i++)); do
				printf "\n\033[K%${margin}s \033[2m│ %b\033[0m" "" "${log_buffer[i]}"
				lines_to_reset=$((lines_to_reset + 1))
			done
		fi

		[[ $percent -ge 100 ]] && break
		printf "\033[%dA" "$lines_to_reset" # Return to Line 1 start
		sleep 0.016
	done
	
	# Release: Just move to the next line since we are already at the bottom
	printf "\n"
}

# --- Helper Functions ---

# TIER 1: Stateless Parser (Expands ranges like "1-3" and splits by delimiter)
# Args: $1=input_string, $2=delimiter (default: ,)
# Returns: Space-separated string on stdout. Exit 1 on syntax error.
parse_selection_input() {
	local input="$1"
	local delim="${2:-,}"
	local -a expanded=()

	local -a parts
	IFS="$delim" read -ra parts <<< "$input"
	for p in "${parts[@]}"; do
		p="${p// /}" # trim spaces
		[[ -z "$p" ]] && continue
		
		if [[ "$p" == "all" || "$p" == "ALL" ]]; then
			expanded+=("all")
		elif [[ "$p" == *-* ]]; then
			local s="${p%-*}"
			local e="${p#*-}"
			if [[ "$s" =~ ^[0-9]+$ && "$e" =~ ^[0-9]+$ ]]; then
				# Simple expansion, no bounds checking yet
				for ((i=s; i<=e; i++)); do expanded+=("$i"); done
			else
				return 1 # Syntax error
			fi
		elif [[ "$p" =~ ^[0-9]+$ ]]; then
			expanded+=("$p")
		else
			return 1 # Invalid characters
		fi
	done
	echo "${expanded[*]}"
}

# TIER 2: Keyword Expander (Replaces "all" with 1..max)
# Args: $1=max_index, $@=list_from_tier1
# Returns: Space-separated numbers
expand_selection_all() {
	local max=$1
	shift
	local -a final=()
	for item in "$@"; do
		if [[ "$item" == "all" ]]; then
			for ((i=1; i<=max; i++)); do final+=("$i"); done
		else
			final+=("$item")
		fi
	done
	echo "${final[*]}"
}

# TIER 3: Range Validator (Strictly checks bounds)
# Args: $1=max, $@=numbers
# Returns: Exit 0 if all valid, Exit 1 if any out of bounds
validate_selection_range() {
	local max=$1
	shift
	[[ $# -eq 0 ]] && return 1
	for n in "$@"; do
		(( n > 0 && n <= max )) || return 1
	done
	return 0
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

		# 2. Pipeline: Parse -> Expand -> Validate
		local raw_expansion=$(parse_selection_input "$option" ",") || { echo -e "${RED}Error: Invalid syntax.${RESET}"; sleep 1; continue; }
		local full_list=$(expand_selection_all "${#keys_list[@]}" $raw_expansion)
		validate_selection_range "${#keys_list[@]}" $full_list || { echo -e "${RED}Error: One or more indices are out of range.${RESET}"; sleep 1; continue; }

		# 3. Execute deletion based on validated indices
		local -a selected_nums=($full_list)
		for num in "${selected_nums[@]}"; do
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
		done
		target_bundle_update_status # Refresh after removal
		read -rp "Action complete. Press enter to refresh..."
	done
}
target_bundle_menu(){ # 1
	while true; do
		# Dynamic message based on install_mode
		local msg_exec
		case "$install_mode" in
			"rookie")      msg_exec="${GREEN}Silent install (Safe/Full)${RESET}" ;;
			"interactive") msg_exec="${MAGENTA}Interactive install (Leaf Menu)${RESET}" ;;
			"force")       msg_exec="${RED}Force install (Overwrites)${RESET}" ;;
			"backup")      msg_exec="${YELLOW}Backup only (System -> Vault)${RESET}" ;;
			"restore")     msg_exec="${SKY_BLUE}Restore only (Vault -> System)${RESET}" ;;
		esac

		reset
		target_bundle_info_list
		echo "0) clone/init"
		echo "1) $msg_exec"
		echo "m) Toggle Install Mode (Current: $install_mode_styled)"
		echo "2) uinstall bundle components (all/single/selective)!" # e.g. all/3,4,6-9/4
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			0) target_bundle_clone ;;
			1) target_bundle_deploy_menu ;;
			m|M) toggle_install_mode ;;
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
- ${RED}force${RESET}       : Overwrite existing configs without backup.
- ${MAGENTA}interactive${RESET} : Drops you into the component's own menu.
- ${YELLOW}backup${RESET}      : Only backs up your system dots to the vault.
- ${SKY_BLUE}restore${RESET}     : Restores your system dots from the vault.

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

asset_management_menu() {
	local type="$1"
	local -a keys_list=()
	for k in "${!components[@]}"; do
		[[ "${components[$k]}" == "$type|"* ]] && keys_list+=("$k")
	done

	while true; do
		reset
		echo "#####################################"
		echo "${type^} Management"
		echo "Available ${type}s:"
		local -i idx=1
		for key in "${keys_list[@]}"; do
			local meta="${components[$key]}"
			local -a data; IFS='|' read -ra data <<< "$meta"
			local folder="${data[2]}"
			local status="$minus"
			local dest_dir
			[[ "$type" == "wallpaper" ]] && dest_dir="$wallpapers_dir" || dest_dir="$themes_dir"
			[[ -d "$dest_dir/$folder" ]] && status="$ok"
			printf " %-2b) %-10b %-20s\n" "$idx" "$status" "${key}"
			((idx++))
		done
		echo "######################################"
		echo "1) Clone/Sync selective"
		echo "2) Deploy selective"
		echo "3) Remove selective"
		echo "x) Back to Main Menu"

		read -rp "Select an option: " option
		case $option in
			1) asset_action_menu "$type" "clone" "${keys_list[@]}" ;;
			2) asset_action_menu "$type" "deploy" "${keys_list[@]}" ;;
			3) asset_action_menu "$type" "remove" "${keys_list[@]}" ;;
			x|X) return 0 ;;
			*) echo "Invalid option. Please try again." ;;
		esac
	done
}

asset_action_menu() {
	local type="$1"
	local action="$2"
	shift 2
	local -a keys_list=("$@")

	while true; do
		echo -e "\nSelect ${type}(s) to ${action}:"
		echo "(e.g. 1 / 1,3 / 1-3 / all / x to back)"
		read -r selection
		[[ "$selection" == "x" || "$selection" == "X" ]] && return 0

		local raw_expansion=$(parse_selection_input "$selection" ",") || { echo -e "${RED}Error: Invalid syntax.${RESET}"; sleep 1; continue; }
		local full_list=$(expand_selection_all "${#keys_list[@]}" $raw_expansion)
		validate_selection_range "${#keys_list[@]}" $full_list || { echo -e "${RED}Error: Out of range.${RESET}"; sleep 1; continue; }

		local -a selected_keys=()
		for num in $full_list; do
			selected_keys+=("${keys_list[$((num-1))]}")
		done

		case "$action" in
			"clone")
				batch_clone "${type^} Sync" "${selected_keys[@]}"
				read -rp "Action complete. Press enter..."
				;;
			"deploy")
				for k in "${selected_keys[@]}"; do
					deploy_component "$k"
				done
				read -rp "Action complete. Press enter..."
				;;
			"remove")
				for k in "${selected_keys[@]}"; do
					local meta="${components[$k]}"
					local -a data; IFS='|' read -ra data <<< "$meta"
					local folder="${data[2]}"
					local dest_dir
					[[ "$type" == "wallpaper" ]] && dest_dir="$wallpapers_dir" || dest_dir="$themes_dir"
					local path="$dest_dir/$folder"
					if [[ -d "$path" ]]; then
						echo -e "${ORANGE}Removing --> $path${RESET}"
						rm -rf "$path" && echo -e "${GREEN}Removed successfully.${RESET}"
					else
						echo -e "${YELLOW}Notice: Component '$k' not found.${RESET}"
					fi
				done
				read -rp "Action complete. Press enter..."
				;;
		esac
	done
}

main_menu() {
	while true; do
		target_bundle_info_list
		echo "Main Menu"
		echo "1) Bundle: ${target_bundle} (menu)"
		echo "2) Switch Bundle (menu)" # first thing to make
		echo "m) Toggle Install Mode (Current: $install_mode_styled)"
		echo "w) wallpapers (menu)"
		echo "t) themes (menu)"
		echo "s) maintenance (menu)" # later
		echo "i) info"
		echo "x) Exit"

		read -rp "Select an option: " option
		case $option in
			1) target_bundle_menu ;;
			2) select_bundle_menu ;;
			d) echo -e "$(dashboard)" | less -R ;;
			m) toggle_install_mode ;;
			w|W) asset_management_menu "wallpaper" ;;
			t|T) asset_management_menu "theme" ;;
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
				if [[ "$2" =~ ^(rookie|force|interactive|backup|restore)$ ]]; then
					install_mode="$2"
					shift 2
				else
					echo -e "${RED}Error: Invalid mode '$2'. Valid options: rookie, force, interactive, backup, restore${RESET}"
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
		"check-update") echo "will return if has any update after the current installed bundle" ;;
		# either it can return we have if a propern new bundle is found or let user know if he is able to test the
		# THE few updated components even if ne bundle isnt found
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

# --- UI Bar V3 Simulation Suite ---

# Simulation 1: Basic Linear (Label + Bar)
echo -e "${SKY_BLUE}Simulation 1: Basic Linear Indicator...${RESET}"
for i in {0..100..4}; do echo $i; sleep 0.03; done | ui_tui_progress_bar_v3 -l "System Init" --start "#FF5500" --end "#00FF55"

# Simulation 2: Progress + Activity Log (P: and L: tags)
echo -e "\n${YELLOW}Simulation 2: Progress + Scrolling Log...${RESET}"
(
    for i in {0..100..5}; do
        echo "P:$i"
        echo "L:Processing chunk $((i/5)) of 20..."
        sleep 0.1
    done
) | ui_tui_progress_bar_v3 -t -l "Data Indexer" --log-height 3 --start "#0055FF" --end "#FFFF00"

echo -e "\n${MAGENTA}Press any key for Simulation 3 (The Ultimate Quantum Console)...${RESET}"
read -n 1 -s -r

# Simulation 3: All-at-once (P: M: L: Tags + Async High-Hz)
echo -e "\n${MAGENTA}Simulation 3: Full Multiplexed Async Console...${RESET}"
declare start_color="#$(printf '%02x%02x%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))"
declare end_color="#$(printf '%02x%02x%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))"

(
    # Progress Feeder
    ( for i in {0..100..2}; do echo "P:$i"; sleep 0.2; done ) &
    # Status Feeder
    ( for s in "Scanning" "Analyzing" "Optimizing" "Finalizing"; do echo "M:Task: $s"; sleep 2; done ) &
    # Log Feeder (High Hz)
    ( 
        echo "L:STRESS_TEST: Starting high-frequency stream with intentional long-line wrapping enabled..."
        echo "L:LONG_LINE: This is an extremely long log message that is designed to exceed the typical terminal width of eighty characters to test if the new wrapping logic in the Quantum Console V3 engine is working correctly by splitting it into multiple buffer entries."
        sleep 1
        for i in {1..120}; do echo "L:IO_EVENT: [$(date +%T)] 0x$(printf '%x' $RANDOM) -> BUFFER_STREAM"; sleep 0.08; done 
    ) &
    wait
) | ui_tui_progress_bar_v3 -t -l "Quantum Engine" --log-height 6 --start "$start_color" --end "$end_color"

echo -e "\n${GREEN}UI Engine V3 Comprehensive Tests Complete.${RESET}"
