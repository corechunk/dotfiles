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