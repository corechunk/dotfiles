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
