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
