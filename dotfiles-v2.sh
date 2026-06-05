#!/usr/bin/env bash

# Dotfiles Hub Orchestrator v2 (Architecture v2)
# Features: Standalone Vault, Live System Checks, Two-Phase Deployment

# --- Colors ---
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
RED="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# --- Paths & State ---
hub_dir="$(pwd)"
matrix_file="matrix.txt"
processing_dir="processing"
assets_dir="assets"

bundle_root="$hub_dir/$processing_dir/bundles"
cache_dir="$hub_dir/$processing_dir/cache"
web_cache="$cache_dir/web_versions.txt"

wallpapers_root="$hub_dir/$assets_dir/wallpapers"
themes_root="$hub_dir/$assets_dir/themes"

target_bundle="1.0.0"
install_mode="rookie"
current_distro=$(lsb_release -ds 2>/dev/null || echo "Unknown Linux")

mkdir -p "$bundle_root" "$cache_dir" "$wallpapers_root" "$themes_root"
touch "$web_cache"

# --- Registry (Component Metadata) ---
# Format: Key -> FolderName|RepoURL|InstallerSuffix|Type|LivePath
declare -A registry=(
    ["hyprland"]="hyprland|https://github.com/corechunk/hyprland.git|dots|bundle|$HOME/.config/hypr"
    ["waybar"]="waybar|https://github.com/corechunk/waybar.git|dots|bundle|$HOME/.config/waybar"
    ["quickshell"]="quickshell|https://github.com/corechunk/quickshell.git|dots|bundle|$HOME/.config/quickshell"
    ["wallust"]="wallust|https://github.com/corechunk/wallust.git|dots|bundle|$HOME/.config/wallust"
    ["fastfetch"]="fastfetch|https://github.com/corechunk/fastfetch.git|dots|bundle|$HOME/.config/fastfetch"
    ["neovim"]="Neovim|https://github.com/corechunk/Neovim.git|dots|bundle|$HOME/.config/nvim"
    ["kitty"]="Kitty|https://github.com/corechunk/Kitty.git|dots|bundle|$HOME/.config/kitty"
    ["bash"]="Bash|https://github.com/corechunk/Bash.git|dots|bundle|$HOME"
    ["tmux"]="Tmux|https://github.com/corechunk/Tmux.git|dots|bundle|$HOME/.config/tmux"
    ["omp"]="omp|https://github.com/corechunk/omp.git|dots|bundle|$HOME/.config/omp"
    ["sddm"]="sddm|https://github.com/corechunk/sddm.git|dots|bundle|/etc/sddm.conf.d"
    
    # Persistent Assets
    ["sddm-plus"]="sddm-themes-plus|https://github.com/corechunk/sddm-themes-plus.git|dots|theme|/usr/share/sddm/themes"
    ["wallpaper_os"]="wallpaper_os|https://github.com/corechunk/wallpaper_os.git|dots|wallpaper|"
    ["wallpaper_jakoolit"]="wallpaper_jakoolit|https://github.com/corechunk/wallpaper_jakoolit.git|dots|wallpaper|"
    ["wallpaper_minecraft"]="wallpaper_minecraft|https://github.com/corechunk/wallpaper_minecraft.git|dots|wallpaper|"
    ["wallpaper_anime"]="wallpaper_anime|https://github.com/corechunk/wallpaper_anime.git|dots|wallpaper|"
    ["wallpaper_deviantart"]="wallpaper_deviantart|https://github.com/corechunk/wallpaper_deviantart.git|dots|wallpaper|"
)

# --- Matrix Engine ---

load_matrix() {
    [[ ! -f "$matrix_file" ]] && return 1
    local header=$(grep "^COMPONENTS:" "$matrix_file" | head -n1 | sed 's/COMPONENTS://')
    IFS=':' read -r -a global_keys <<< "$header"
    
    local row=$(grep "^\[$target_bundle\]" "$matrix_file" | head -n1)
    [[ -z "$row" ]] && row=$(grep "^\[" "$matrix_file" | head -n1) && target_bundle=$(echo "$row" | cut -d'|' -f1 | tr -d '[]')
    
    declare -g -A bundle_versions
    local versions_str=$(echo "$row" | cut -d'|' -f2-)
    IFS='|' read -r -a v_array <<< "$versions_str"
    for i in "${!global_keys[@]}"; do bundle_versions["${global_keys[i]}"]="${v_array[i]}"; done
}

get_web_version() {
    local name=$1
    grep "^$name|" "$web_cache" | cut -d'|' -f2 || echo "..."
}

fetch_updates() {
    echo -e "${BLUE}[Discovery] : Fetching latest tags from GitHub...${RESET}"
    > "$web_cache.tmp"
    for key in "${global_keys[@]}"; do
        local meta="${registry[$key]}"
        [[ -z "$meta" ]] && continue
        local repo=$(echo "$meta" | cut -d'|' -f2)
        echo -e "${SKY_BLUE}Checking $key...${RESET}"
        local version=$(git ls-remote --tags --sort="v:refname" "$repo" | tail -n1 | sed 's/.*\/v//;s/.*\/V//;s/\^{}//')
        echo "$key|${version:-unknown}" >> "$web_cache.tmp"
    done
    mv "$web_cache.tmp" "$web_cache"
}

# --- Vault Management ---

get_vault_path() {
    local key=$1
    local meta="${registry[$key]}"
    local folder=$(echo "$meta" | cut -d'|' -f1)
    local type=$(echo "$meta" | cut -d'|' -f4)
    case $type in
        "theme") echo "$themes_root/$folder" ;;
        "wallpaper") echo "$wallpapers_root/$folder" ;;
        *) echo "$bundle_root/$target_bundle/$folder" ;;
    esac
}

ensure_component() {
    local key=$1
    local meta="${registry[$key]}"
    local repo_url=$(echo "$meta" | cut -d'|' -f2)
    local version="${bundle_versions[$key]}"
    local type=$(echo "$meta" | cut -d'|' -f4)
    local target_path=$(get_vault_path "$key")
    
    if [[ ! -d "$target_path" ]]; then
        echo -e "${BLUE}[Vault Sync] : ${SKY_BLUE}$key${RESET} -> ${ORANGE}$target_path${RESET}"
        mkdir -p "$(dirname "$target_path")"
        if [[ "$type" == "bundle" && -n "$version" ]]; then
            git clone --depth 1 --branch "v$version" "$repo_url" "$target_path" 2>/dev/null || git clone --depth 1 "$repo_url" "$target_path"
        else
            git clone --depth 1 "$repo_url" "$target_path"
        fi
    fi
}

# --- Core Execution ---

run_leaf_installer() {
    local key=$1
    local mode_arg=$2
    local meta="${registry[$key]}"
    [[ -z "$meta" ]] && return 1

    local suffix=$(echo "$meta" | cut -d'|' -f3)
    local target_path=$(get_vault_path "$key")
    
    # 1. Ensure it's downloaded to vault before running
    ensure_component "$key"

    local installer_script="installer_${key}_${suffix}.sh"
    [[ "$key" == "sddm-plus" ]] && installer_script="installer_TsddmP_dots.sh"
    [[ ! -f "$target_path/$installer_script" ]] && installer_script=$(find "$target_path" -maxdepth 1 -name "installer_*_dots.sh" -printf "%f\n" | head -n1)

    if [[ -n "$installer_script" && -f "$target_path/$installer_script" ]]; then
        echo -e "\n${BLUE}[Executing] : ${SKY_BLUE}$installer_script${RESET} in ${ORANGE}$target_path${RESET}"
        ( cd "$target_path" && bash "$installer_script" "$mode_arg" )
        return $?
    fi
    echo -e "${RED}[Error] : Installer not found in $target_path${RESET}"
    return 1
}

# --- Header & Dashboard ---

show_dashboard() {
    load_matrix
    echo "###########################################################"
    echo "## TARGET: v$target_bundle <[selected]> | DISTRO: $current_distro"
    echo "## -------------------------------------------------------"
    local count=0
    for key in "${global_keys[@]}"; do
        local meta="${registry[$key]}"
        [[ "$(echo "$meta" | cut -d'|' -f4)" != "bundle" ]] && continue
        
        local m_ver="${bundle_versions[$key]}"
        local w_ver=$(get_web_version "$key")
        local live_path=$(echo "$meta" | cut -d'|' -f5)
        
        local status="${RED}[ -- ]${RESET}"
        # Live System Check (Looks for .version in the PC's config folders)
        if [ -f "$live_path/.version" ]; then
            local live_v=$(cat "$live_path/.version")
            [[ "$live_v" == "$m_ver" ]] && status="${GREEN}[ OK ]${RESET}" || status="${YELLOW}[DIFF]${RESET}"
        elif [ -d "$(get_vault_path "$key")" ]; then
            status="${SKY_BLUE}[SYNC]${RESET}" # Downloaded to vault but not installed to live path
        fi
        
        local update_flag=""
        [[ "$w_ver" != "..." && "$w_ver" != "unknown" && "$w_ver" != "$m_ver" ]] && update_flag="${ORANGE}[!!]${RESET}"
        printf "## %-18s %-4s " "$status ${key^}" "$update_flag"
        ((count++))
        [[ $((count % 2)) -eq 0 ]] && echo ""
    done
    [[ $((count % 2)) -ne 0 ]] && echo ""
    echo "## -------------------------------------------------------"
    echo "## Mode: $install_mode | Status: Ready for Deployment"
    echo "###########################################################"
}

# --- Info Manual ---

show_info() {
    local info_content=$(cat << EOF
${BLUE}###########################################################${RESET}
##                 ${SKY_BLUE}DOTFILES HUB v2 - MANUAL${RESET}              ##
###########################################################

${MAGENTA}1. LIVE DETECTION (How [ OK ] works)${RESET}
The Hub checks if your rices are actually applied to your PC by 
reading the ${YELLOW}.version${RESET} file in their **Live Live Locations**.

${SKY_BLUE}Live Path Mapping:${RESET}
$(for key in "${!registry[@]}"; do 
    path=$(echo "${registry[$key]}" | cut -d'|' -f5)
    [[ -n "$path" ]] && echo "  - ${key^} : $path/.version"
done)

${MAGENTA}2. DASHBOARD INDICATORS${RESET}
${GREEN}[ OK ]${RESET} : Live PC version matches the selected Matrix bundle.
${YELLOW}[DIFF]${RESET} : Rice is installed, but version differs from Matrix.
${SKY_BLUE}[SYNC]${RESET} : Rice is in the Hub's vault, but NOT installed to PC.
${RED}[ -- ]${RESET} : Not downloaded and not installed.
${ORANGE}[!!]${RESET}   : GitHub has a newer tag than the local Matrix.

${MAGENTA}3. DEPLOYMENT FLOW (Sync -> Execute)${RESET}
1. ${SKY_BLUE}Vault Sync${RESET} : Clones all missing components to internal storage.
2. ${SKY_BLUE}Install${RESET}    : Runs the installers sequentially from the vault.

${MAGENTA}4. CONTROLS${RESET}
- ${YELLOW}Arrows${RESET} : Scroll | ${YELLOW}q${RESET} : Return to menu.

${BLUE}###########################################################${RESET}
##              STAY CHILLY - Built by netchunk          ##
###########################################################
EOF
)
    echo -e "$info_content" | less -R
}

# --- Menus ---

deploy_selective() {
    while true; do
        clear && show_dashboard
        echo "Selective Deployment"
        echo "----------------------"
        local core_keys=()
        for k in "${global_keys[@]}"; do [[ "${registry[$k]}" == *"bundle"* ]] && core_keys+=("$k"); done
        local i=1
        for key in "${core_keys[@]}"; do echo "$i. ${key^}"; ((i++)); done
        echo "x. Back"
        read -p "Choose component index: " choice
        [[ "$choice" == "x" ]] && break
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#core_keys[@]}" ]; then
            run_leaf_installer "${core_keys[$((choice-1))]}" "$install_mode"
            read -p "Press enter to continue..."
        fi
    done
}

deploy_menu() {
    while true; do
        clear && show_dashboard
        echo "Deployment Flow (Core Rice)"
        echo "----------------------"
        echo "1. [ Run All ] (Sequential Core Execution)"
        echo "2. [ Selective ] (Choose Components)"
        echo "m. Toggle Mode (Current: $install_mode)"
        echo "x. Back to Main Menu"
        read -p "Choice: " choice
        case $choice in
            1)
                echo -e "${BLUE}[Phase 1] : Syncing all components to vault...${RESET}"
                for key in "${global_keys[@]}"; do [[ "${registry[$key]}" == *"bundle"* ]] && ensure_component "$key"; done
                echo -e "${GREEN}[Phase 1] : Sync complete.${RESET}"
                
                echo -e "${BLUE}[Phase 2] : Executing installers...${RESET}"
                for key in "${global_keys[@]}"; do [[ "${registry[$key]}" == *"bundle"* ]] && run_leaf_installer "$key" "$install_mode"; done
                read -p "Deployment sequence complete. Enter..."
                ;;
            2) deploy_selective ;;
            m) [[ "$install_mode" == "rookie" ]] && install_mode="force" || { [[ "$install_mode" == "force" ]] && install_mode="interactive" || install_mode="rookie"; } ;;
            x) break ;;
        esac
    done
}

themes_plus_menu() {
    while true; do
        clear && show_dashboard
        echo "Themes Plus (Heavy persistent Packs)"
        echo "----------------------"
        local themes_list=()
        for key in "${!registry[@]}"; do [[ "${registry[$key]}" == *"theme"* ]] && themes_list+=("$key"); done
        local i=1
        for t in "${themes_list[@]}"; do echo "$i. $t"; ((i++)); done
        echo "x. Back"
        read -p "Choose theme pack: " choice
        [[ "$choice" == "x" ]] && break
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#themes_list[@]}" ]; then
            run_leaf_installer "${themes_list[$((choice-1))]}" "$install_mode"
            read -p "Press enter..."
        fi
    done
}

wallpapers_menu() {
    while true; do
        clear && show_dashboard
        echo "Wallpapers (Persistent Hub Assets)"
        echo "----------------------"
        local wp_list=()
        for key in "${!registry[@]}"; do [[ "${registry[$key]}" == *"wallpaper"* ]] && wp_list+=("$key"); done
        local i=1
        for wp in "${wp_list[@]}"; do echo "$i. $wp"; ((i++)); done
        echo "x. Back"
        read -p "Choose wallpaper pack: " choice
        [[ "$choice" == "x" ]] && break
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#wp_list[@]}" ]; then
            run_leaf_installer "${wp_list[$((choice-1))]}" "$install_mode"
            read -p "Press enter..."
        fi
    done
}

bundles_menu() {
    while true; do
        clear && show_dashboard
        echo "Bundle Management (Matrix Control)"
        echo "----------------------"
        local bundles=($(grep "^\[" "$matrix_file" | cut -d'|' -f1 | tr -d '[]'))
        local i=1
        for b in "${bundles[@]}"; do
            local mark=" "
            [[ "$b" == "$target_bundle" ]] && mark="*"
            echo "[$mark] $i. v$b"
            ((i++))
        done
        echo "r. Refresh Discovery Engine (ls-remote)"
        echo "x. Back"
        read -p "Select bundle: " choice
        [[ "$choice" == "x" ]] && break
        [[ "$choice" == "r" ]] && fetch_updates
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#bundles[@]}" ]; then target_bundle="${bundles[$((choice-1))]}"; fi
    done
}

maintenance_menu() {
    while true; do
        clear && show_dashboard
        echo "Maintenance & System"
        echo "----------------------"
        echo "1. Dependency Check"
        echo "2. Clean Discovery Cache"
        echo "3. Full Hub Reset"
        echo "x. Back"
        read -p "Choice: " choice
        case $choice in
            1) for cmd in git gh dialog lsb_release; do command -v $cmd >/dev/null 2>&1 && echo -e "${GREEN}[ OK ]${RESET} $cmd" || echo -e "${RED}[ !! ]${RESET} $cmd"; done; read -p "Press enter...";;
            2) rm -f "$web_cache"; echo "Cache cleaned."; sleep 1 ;;
            3) read -p "DANGER: Full Reset? (y/n): " confirm; [[ "$confirm" == "y" ]] && rm -rf "$processing_dir" "$assets_dir" && mkdir -p "$bundle_root" "$cache_dir" "$wallpapers_root" "$themes_root" ;;
            x) break ;;
        esac
    done
}

main_menu() {
    load_matrix
    while true; do
        clear && show_dashboard
        echo "Main Menu"
        echo "----------------------"
        echo "1. Deploy Core (Target: v$target_bundle)"
        echo "2. Themes Plus (Heavy Packs)"
        echo "3. Wallpapers (Assets)"
        echo "4. Bundles (Targeting Room)"
        echo "5. Maintenance"
        echo "i. Info / Manual (manpage)"
        echo "x. Exit"
        read -p "Choose option: " choice
        case $choice in
            1) deploy_menu ;;
            2) themes_plus_menu ;;
            3) wallpapers_menu ;;
            4) bundles_menu ;;
            5) maintenance_menu ;;
            i) show_info ;;
            x) clear; exit 0 ;;
        esac
    done
}

main_menu
