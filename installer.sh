#!/usr/bin/env bash

if [[ "$1" == tui ]];then
	mode="tui"
elif  [[ "$1" == cli || "$1" == * ]];then
	mode="cli"
fi

# Function to check if .git exists in a directory
check_git() {
	local dir=$1
	[ -d "$dir/.git" ] && return 0 || return 1
}

# Function to download a single dotfile repository
download_dotfile() {
	local folder=$1
	local repo_url=$2
	#local temp_dir="temp_$(date +%s)"

	if [ -d "$folder" ] && [ "$(ls -A "$folder")" ]; then
		echo "Error: Directory $folder is not empty. Skipping clone."
		return 1
	fi
	
	echo "Downloading $folder dotfiles from $repo_url..."
	mkdir -p "$folder"
	cd "$folder"
	
	if [[ -z "$3" ]];then
		if git clone --depth 1 "$repo_url" .;then
			local error=false
			echo "downloaded contents from $repo_url successfully"
		else
			local error=true
			echo "contents from $repo_url couldn't be downloaded !!"
		fi
	else
		if git clone --depth 1 "$repo_url" -b "$3" .;then
			local error=false
			echo "downloaded contents from $repo_url successfully"
		else
			local error=true
			echo "contents from $repo_url couldn't be downloaded !!"
		fi
	fi
	cd ..
	
	if $error;then return 1;else return 0;fi
}

# Function to delete a folder with confirmation
delete_folder() {
    local folder=$1
    local choice
    if [ -d "$folder" ]; then
        if [[ "$mode" == "tui" ]]; then
            dialog --yesno "Are you sure you want to delete the folder '$folder'?" 7 60
            response=$?
            if [ $response -eq 0 ]; then
                rm -rf "$folder"
                dialog --msgbox "'$folder' has been deleted." 5 40
            else
                dialog --msgbox "Deletion of '$folder' cancelled." 5 40
            fi
        else
            read -p "Are you sure you want to delete the folder '$folder'? (y/n): " choice
            if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                rm -rf "$folder"
                echo "'$folder' has been deleted."
            else
                echo "Deletion of '$folder' cancelled."
            fi
        fi
    else
        if [[ "$mode" == "tui" ]]; then
            dialog --msgbox "Folder '$folder' does not exist." 5 40
        else
            echo "Folder '$folder' does not exist."
        fi
    fi
}

# Function to run installer for a specific tool
run_installer() {
	local dir=$1
	local installer_script="installer_${dir}_dots.sh"
	
	if [ -f "./$dir/$installer_script" ]; then
		echo "Running installer for $dir..."
		(
			cd "./$dir"
			bash "./$installer_script" "$mode" || { echo "Error: Installer script $installer_script failed"; return 1; }
		)
		return 0
	else
		echo "Error: Installer script $installer_script not found!"
		return 1
	fi
}
# Function to show delete menu
delete_menu() {
    while true;do
        if [[ "$mode" == "cli" ]];then
            echo "Delete Menu"
            echo "----------------------"
            echo "1. Delete Hyprland dotfiles"
            echo "2. Delete Fastfetch dotfiles"
            echo "3. Delete oh-my-posh dotfiles"
            echo "4. Delete Kitty dotfiles"
            echo "5. Delete Tmux dotfiles"
            echo "6. Delete Neovim dotfiles"
            echo "7. Delete Bash dotfiles"
            echo "  -------------------"
            echo "8. Delete JaKooLit wallpapers"
            echo "9. Delete Minecraft Wallpapers"
            echo "10. Delete os Wallpapers"
            echo "  -------------------"
            echo "11. Delete all dotfiles only"
            echo "12. Delete all wallpapers only"
            echo "13. Delete all dotfiles and all wallpapers"
            echo "  -------------------"
            echo "[x]. Back to main menu : choose 'x' to return"
            echo "----------------------"
            
            read -p "Enter your choice: " choice
            echo ""
        elif [[ "$mode" == "tui" ]];then
            choice=$(dialog --title "Delete Menu" \
                --menu "Select an option to delete:" 20 60 16 \
                1 "Delete Hyprland dotfiles" \
                2 "Delete Fastfetch dotfiles" \
                3 "Delete oh-my-posh dotfiles" \
                4 "Delete Kitty dotfiles" \
                5 "Delete Tmux dotfiles" \
                6 "Delete Neovim dotfiles" \
                7 "Delete Bash dotfiles" \
                8 "Delete JaKooLit wallpapers" \
                9 "Delete Minecraft Wallpapers" \
                10 "Delete os Wallpapers" \
                11 "Delete all dotfiles only" \
                12 "Delete all wallpapers only" \
                13 "Delete all dotfiles and all wallpapers" \
                x "Back to main menu" 2>&1 >/dev/tty)
        fi
        
        case $choice in
            1) delete_folder "hyprland";;
            2) delete_folder "fastfetch";;
            3) delete_folder "omp";;
            4) delete_folder "kitty";;
            5) delete_folder "tmux";;
            6) delete_folder "nvim";;
            7) delete_folder "bash";;
            8) delete_folder "wjk";;
            9) delete_folder "wmc";;
            10) delete_folder "wos";;
            11)
                delete_folder "hyprland"
                delete_folder "fastfetch"
                delete_folder "nvim"
                delete_folder "kitty"
                delete_folder "tmux"
                delete_folder "bash"
                delete_folder "omp"
                ;;
            12)
                delete_folder "wmc"
                delete_folder "wjk"
                delete_folder "wos"
                ;;
            13)
                delete_folder "hyprland"
                delete_folder "fastfetch"
                delete_folder "nvim"
                delete_folder "kitty"
                delete_folder "tmux"
                delete_folder "bash"
                delete_folder "omp"
                delete_folder "wmc"
                delete_folder "wjk"
                delete_folder "wos"
                ;;
            x|X)
                clear
                break
                ;;
            *)
                if [[ "$mode" == "tui" ]]; then
                    dialog --msgbox "Invalid choice, please try again." 5 40
                else
                    echo "================================="
                    echo "Invalid choice, please try again."
                    echo "================================="
                fi
                ;;
        esac
    done
}

# Function to show download menu
download_menu() {
	while true;do
		if [[ "$mode" == "cli" ]];then
			echo "Download Dotfiles Menu"
			echo "----------------------"
			echo "1. Download Hyprland dotfiles"
			echo "2. Download Fastfetch dotfiles"
			echo "3. Download oh-my-posh dotfiles"
			echo "4. Download Kitty dotfiles"
			echo "5. Download Tmux dotfiles"
			echo "6. Download Neovim dotfiles"
			echo "7. Download Bash dotfiles"
			echo "  -------------------"
			echo "8. Download JaKooLit wallpapers"
			echo "9. Download Minecraft Wallpapers"
			echo "10. Download os Wallpapers"
			echo "  -------------------"
			echo "11. Download all dotfiles only"
			echo "12. Download all wallpapers only"
			echo "13. Download all dotfiles and all wallpapers"
			echo "  -------------------"
			echo "14. Uninstall Page"
			echo "[x]. Back to main menu : choose 'x' to return"
			echo "----------------------"
			
			read -p "Enter your choice: " choice
			echo ""
		elif [[ "$mode" == "tui" ]];then
			choice=$(dialog --title "Download Dotfiles Menu" \
				--menu "Select an option:" 20 60 16 \
				1 "Download Hyprland dotfiles" \
				2 "Download Fastfetch dotfiles" \
				3 "Download oh-my-posh dotfiles" \
				4 "Download Kitty dotfiles" \
				5 "Download Tmux dotfiles" \
				6 "Download Neovim dotfiles" \
				7 "Download Bash dotfiles" \
				8 "Download JaKooLit wallpapers" \
				9 "Download Minecraft Wallpapers" \
				10 "Download os Wallpapers" \
				11 "Download all dotfiles only" \
				12 "Download all wallpapers only" \
				13 "Download all dotfiles and all wallpapers" \
				14 "Uninstall Page" \
				x "Back to main menu" 2>&1 >/dev/tty)
		fi
		
		case $choice in
			1)
				# Download Hyprland dotfiles
				download_dotfile "hyprland" "https://github.com/corechunk/hyprland.git"
				;;
			2)
				# Download Fastfetch dotfiles
				download_dotfile "fastfetch" "https://github.com/corechunk/fastfetch.git"
				;;
			3)
				# Download oh-my-posh dotfiles
				download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
				;;
			4)
				# Download Kitty dotfiles
				download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
				;;
			5)
				# Download Tmux dotfiles
				download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
				;;
			6)
				# Download Neovim dotfiles
				# Download Lazyvim branch of Neovim dotfiles
				download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
				;;
			7)
				# Download Bash dotfiles
				download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
				;;
			8)
					# Download JaKooLit wallpapers
				echo "not configured yet"
				download_dotfile "wjk" "https://github.com/Miraj13123/wallpaper_jakoolit.git"
				;;
			9)
					# Download Minecraft wallpapers
				download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
				;;
			10)
					# Download os wallpapers
				download_dotfile "wos" "https://github.com/corechunk/wallpaper_os.git"
				;;
			11)
					# Download all dotfiles only
				download_dotfile "hyprland" "https://github.com/corechunk/hyprland.git"
				download_dotfile "fastfetch" "https://github.com/corechunk/fastfetch.git"
				download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
				download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
				download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
				download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
				download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
				;;
			12)
					# Download all wallpapers only
				download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
				download_dotfile "wjk" "https://github.com/Miraj13123/wallpaper_jakoolit.git"
				download_dotfile "wos" "https://github.com/corechunk/wallpaper_os.git"
				;;
			13)
					# Download all dotfiles and all wallpapers
				download_dotfile "hyprland" "https://github.com/corechunk/hyprland.git"
				download_dotfile "fastfetch" "https://github.com/corechunk/fastfetch.git"
				download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
				download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
				download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
				download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
				download_dotfile "omp" "https://github.com/Miraj13123/omp.git"

				download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
				download_dotfile "wjk" "https://github.com/Miraj13123/wallpaper_jakoolit.git"
				download_dotfile "wos" "https://github.com/corechunk/wallpaper_os.git"
				;;
			14)
				clear
				delete_menu	
                ;;
            x|X)
				clear
				break
				#show_menu
				;;
			*)
				echo "================================="
				echo "Invalid choice, please try again."
				echo "================================="
				;;
		esac
	done
}
# Function to display info
show_info() {
	echo "=================================="
	echo "     Dotfiles Installer - Info"
	echo "=================================="
	echo ""
	echo "This script helps you:"
	echo "  • Download configuration files (dotfiles) for:"
	echo "    - Hyprland"
	echo "    - Neovim (LazyVim setup)"
	echo "    - Kitty terminal"
	echo "    - Tmux"
	echo "    - Bash"
	echo "    - Oh-My-Posh (prompt theme)"
	echo ""
	echo "  • Download curated wallpapers:"
	echo "    - Minecraft (official)"
	echo "    - [JaKooLit] - (coming soon)"
	echo ""
	echo "  • Install configurations with one click"
	echo ""
	echo "Features:"
	echo "  • Clean separation between download and install phases"
	echo "  • Prevents overwriting existing directories"
	echo "  • Git-powered updates (via --depth 1 clone)"
	echo "  • Branch support (e.g., LazyVim)"
	echo ""
	echo "Maintained by: Miraj13123"
	echo "Repository: https://github.com/Miraj13123/dotfiles"
	echo ""
	echo "Note: This is a personal automation tool."
	echo "       Always review installer scripts before running."
	echo "=================================="
}
# Function to display the menu
show_menu() {
	while true;do
		# Check .git presence for each directory
		local hyprland_git="(dotfiles aren't downloaded)"
		local neovim_git="(dotfiles aren't downloaded)"
		local kitty_git="(dotfiles aren't downloaded)"
		local tmux_git="(dotfiles aren't downloaded)"
		local bash_git="(dotfiles aren't downloaded)"
		local fastfetch_git="(dotfiles aren't downloaded)" # NEW
		local omp_git="(dotfiles aren't downloaded)"

		local wjk_git="(wallpapers aren't downloaded)"
		local wmc_git="(wallpapers aren't downloaded)"
		local wos_git="(wallpapers aren't downloaded)"

		local all_dots="( downloaded )"
		local all_wallpapers="( downloaded )"
		
		local all_assets="( downloaded )"
		
		# calling function to check .git file
		check_git "hyprland" && hyprland_git="( downloaded )"
		check_git "nvim" && neovim_git="( downloaded )"
		check_git "kitty" && kitty_git="( downloaded )"
		check_git "tmux" && tmux_git="( downloaded )"
		check_git "bash" && bash_git="( downloaded )"
		check_git "fastfetch" && fastfetch_git="( downloaded )" # NEW
		check_git "omp" && omp_git="( downloaded )"

		check_git "wmc" && wmc_git="( downloaded )"
		check_git "wjk" && wjk_git="( downloaded )"
		check_git "wos" && wos_git="( downloaded )"
		
		# Check if all dotfiles are downloaded
		for dir in hyprland nvim kitty tmux bash omp fastfetch; do
			if ! check_git "$dir"; then
				all_dots="(all dotfiles aren't downloaded)"
				break
			fi
		done

		# Check if all wallpapers are downloaded
		for dir in wjk wmc wos; do
			if ! check_git "$dir"; then
				all_wallpapers="(all wallpapers aren't downloaded)"
				break
			fi
		done

		# Check if all assets are downloaded
		if [[ "$all_dots"       == "( downloaded )" \
		   && "$all_wallpapers" == "( downloaded )" ]]; then

			all_assets="( downloaded )"
		else
			all_assets="(all assets aren't downloaded)"
		fi

		if [[ "$mode" == cli ]];then
			echo "Dotfiles Installer Menu"
			echo "----------------------"
			echo "0. Download page for downloading any assets, $all_assets"
			echo "1. Install Hyprland dots, $hyprland_git"
			echo "2. Install Fastfetch dots, $fastfetch_git"
			echo "3. Install oh-my-posh dots, $omp_git"
			echo "4. Install Kitty dots, $kitty_git"
			echo "5. Install Tmux dots, $tmux_git"
			echo "6. Install Neovim dots, $neovim_git"
			echo "7. Install Bash dots, $bash_git"
			echo "8. Install JaKooLit wallpapers, $wjk_git"
			echo "9. Install Minecraft wallpapers, $wmc_git"
			echo "10. Install os wallpapers, $wos_git"
			echo "11. Install all dotfiles only, $all_dots"
			echo "12. Install all wallpapers only, $all_wallpapers"
			echo "13. Install all dotfiles and wallpapers, $all_assets"
			echo "14. Info"
			echo "[x]. Exit : choose 'x' to exit"
			echo ""
			
			# Read user input
			local choice=""
			read -p "Enter your choice: " choice
			echo ""
		elif [[ "$mode" == tui ]];then
			choice=$(dialog --title "Dotfiles Installer Menu" \
				--menu "Select an option:" 20 70 16 \
				0 "Download page for downloading any assets, $all_assets" \
				1 "Install Hyprland dots, $hyprland_git" \
                2 "Install fastfetch dots, $fastfetch_git" \
				3 "Install oh-my-posh dots, $omp_git" \
				4 "Install Kitty dots, $kitty_git" \
				5 "Install Tmux dots, $tmux_git" \
				6 "Install Neovim dots, $neovim_git" \
				7 "Install Bash dots, $bash_git" \
				8 "Install JaKooLit wallpapers, $wjk_git" \
				9 "Install Minecraft wallpapers, $wmc_git" \
				10 "Install os wallpapers, $wos_git" \
				11 "Install all dotfiles only, $all_dots" \
				12 "Install all wallpapers only, $all_wallpapers" \
				13 "Install all dotfiles and wallpapers, $all_assets" \
				14 "Info" \
				x "Exit" 2>&1 >/dev/tty)
		fi

		# Process user choice
		case "$choice" in
			0)
				clear
				download_menu
				;;
			1)
				clear
				if [[ "$hyprland_git" == "( downloaded )" ]]; then
					run_installer "hyprland"
				else
					echo "Hyprland dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
            2)
				clear
				if [[ "$fastfetch_git" == "( downloaded )" ]]; then
					run_installer "fastfetch"
				else
					echo "fastfetch dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			3)
				clear
				if [[ "$omp_git" == "( downloaded )" ]]; then
					run_installer "omp"
				else
					echo "oh-my-posh dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			4)
				clear
				if [[ "$kitty_git" == "( downloaded )" ]]; then
					run_installer "kitty"
				else
					echo "Kitty dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			5)
				clear
				if [[ "$tmux_git" == "( downloaded )" ]]; then
					run_installer "tmux"
				else
					echo "Tmux dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			6)
				clear
				if [[ "$neovim_git" == "( downloaded )" ]]; then
					run_installer "nvim"
				else
					echo "Neovim dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			7)
				clear
				if [[ "$bash_git" == "( downloaded )" ]]; then
					run_installer "bash"
				else
					echo "Bash dotfiles aren't available. Please download dotfiles to continue."
				fi
				;;
			8)
				clear
				if [[ "$wjk_git" == "( downloaded )" ]]; then
					run_installer "wjk"
					echo "not configured yet"
				else
					echo "JaKooLit Wallpaper isn't downloaded. Please download JaKooLit's wallpaper to continue."
				fi
				;;
			9)
				clear
				if [[ "$wmc_git" == "( downloaded )" ]]; then
					run_installer "wmc"
				else
					echo "Minecraft wallpapers aren't downloaded yet. Please download Minecraft Wallpapers to continue."
				fi
				;;
			10)
				clear
				if [[ "$wos_git" == "( downloaded )" ]]; then
					run_installer "wos"
				else
					echo "os wallpapers aren't downloaded yet. Please download os Wallpapers to continue."
				fi
				;;
			11)
				clear
				if [[ "$all_dots" == "( downloaded )" ]]; then
					run_installer "hyprland"
                    run_installer "fastfetch"
					run_installer "nvim"
					run_installer "kitty"
					run_installer "tmux"
					run_installer "bash"
					run_installer "omp"
				else
					echo "Dotfiles aren't fully downloaded. Please download all dotfiles to continue."
				fi
				;;
			12)
				clear
				if [[ "$all_wallpapers" == "( downloaded )" ]]; then
					run_installer "wmc"
					run_installer "wjk"
					run_installer "wos"
				else
					echo "All wallpapers aren't fully downloaded. Please download all wallpapers to continue."
				fi
				;;
			13)
				clear
				if [[ "$all_assets" == "( downloaded )" ]]; then
					run_installer "hyprland"
                    run_installer "fastfetch"
					run_installer "nvim"
					run_installer "kitty"
					run_installer "tmux"
					run_installer "bash"
					run_installer "omp"
					run_installer "wmc"
					run_installer "wjk"
					run_installer "wos"
				else
					echo "All assets aren't fully downloaded yet. Please download all dotfiles and wallpapers to continue."
				fi
				;;
			14)
				clear
				show_info
				;;
			x|X)
				clear
				echo "Exiting..."
				break
				;;
			*)
				clear
				echo "================================="
				echo "Invalid choice, please try again."
				echo "================================="
				;;
		esac
	done
}
# Main execution
reset
clear
show_menu

