#!/bin/bash

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

# Function to show download menu
download_menu() {
    while true;do
        echo "Download Dotfiles Menu"
        echo "----------------------"
        echo "1. Download oh-my-posh dotfiles"
        echo "2. Download Kitty dotfiles"
        echo "3. Download Tmux dotfiles"
        echo "4. Download Neovim dotfiles"
        echo "5. Download Bash dotfiles"
        echo "  -------------------"
        echo "6. Download JaKooLit wallpapers"
        echo "7. Download Minecraft Wallpapers"
        echo "  -------------------"
        echo "8. Download all dotfiles only"
        echo "9. Download all wallpapers only"
        echo "10. Download all dotfiles and all wallpapers"
        echo "  -------------------"
        echo "[x]. Back to main menu : choose 'x' to return"
        echo "----------------------"
        
        read -p "Enter your choice: " choice
        echo ""
        
        case $choice in
            1)
                # Download oh-my-posh dotfiles
                download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
                ;;
            2)
                # Download Kitty dotfiles
                download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
                ;;
            3)
                # Download Tmux dotfiles
                download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
                ;;
            4)
                # Download Neovim dotfiles
                # Download Lazyvim branch of Neovim dotfiles
                download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
                ;;
            5)
                # Download Bash dotfiles
                download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
                ;;
            6)
                    # Download JaKooLit wallpapers
                echo "not configured yet"
                #download_dotfile "wjk" #JaKooLit Wallpapers --- needs to be configured
                ;;
            7)
                    # Download Minecraft wallpapers
                download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
                ;;
            8)
                    # Download all dotfiles only
                download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
                download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
                download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
                download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
                download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
                ;;
            9)
                    # Download all wallpapers only
                download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
                #download_dotfile "wjk" #JaKooLit Wallpapers --- needs to be configured
                ;;
            10)
                    # Download all dotfiles and all wallpapers
                download_dotfile "nvim" "https://github.com/Miraj13123/Neovim.git" "Lazyvim"  # lazyvim branch  \/\/\/\/\/\/\/\/\//\/\/
                download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
                download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
                download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
                download_dotfile "omp" "https://github.com/Miraj13123/omp.git"

                download_dotfile "wmc" "https://github.com/Miraj13123/wallpaper_minecraft.git"
                #download_dotfile "wjk" #JaKooLit Wallpapers --- needs to be configured
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

# Function to trigger download menu
download_dotfiles() {
    download_menu
}

# Function to run installer for a specific tool
run_installer() {
    local dir=$1
    local installer_script="$dir/installer_${dir}_dots.sh"
    
    if [ -f "$installer_script" ]; then
        echo "Running installer for $dir..."
        bash "$installer_script" || { echo "Error: Installer script $installer_script failed"; return 1; }
        return 0
    else
        echo "Error: Installer script $installer_script not found!"
        return 1
    fi
}

# Function to display info
show_info() {
    echo "=================================="
    echo "     Dotfiles Installer - Info"
    echo "=================================="
    echo ""
    echo "This script helps you:"
    echo "  • Download configuration files (dotfiles) for:"
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
        local neovim_git="(dotfiles aren't downloaded)"
        local kitty_git="(dotfiles aren't downloaded)"
        local tmux_git="(dotfiles aren't downloaded)"
        local bash_git="(dotfiles aren't downloaded)"
        local omp_git="(dotfiles aren't downloaded)"

        local wjk_git="(wallpapers aren't downloaded)"
        local wmc_git="(wallpapers aren't downloaded)"

        local all_dots="( downloaded )"
        local all_wallpapers="( downloaded )"
        
        local all_assets="( downloaded )"
        
        # calling function to check .git file
        check_git "nvim" && neovim_git="( downloaded )"
        check_git "kitty" && kitty_git="( downloaded )"
        check_git "tmux" && tmux_git="( downloaded )"
        check_git "bash" && bash_git="( downloaded )"
        check_git "omp" && omp_git="( downloaded )"

        check_git "wmc" && wmc_git="( downloaded )"
        #check_git "wjk" && wjk_git="( downloaded )"
        
        # Check if all dotfiles are downloaded
        for dir in nvim kitty tmux bash omp; do
            if ! check_git "$dir"; then
                all_dots="(all dotfiles aren't downloaded)"
                break
            fi
        done

        # Check if all wallpapers are downloaded
        for dir in wjk wmc; do
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

        echo "Dotfiles Installer Menu"
        echo "----------------------"
        echo "0. Download page for downloading any assets, $all_assets"
        echo "1. Install oh-my-posh dots, $omp_git"
        echo "2. Install Kitty dots, $kitty_git"
        echo "3. Install Tmux dots, $tmux_git"
        echo "4. Install Neovim dots, $neovim_git"
        echo "5. Install Bash dots, $bash_git"
        echo "6. Install JaKooLit wallpapers, $wjk_git"
        echo "7. Install Minecraft wallpapers, $wmc_git"
        echo "8. Install all dotfiles only, $all_dots"
        echo "9. Install all wallpapers only, $all_wallpapers"
        echo "10. Install all dotfiles and wallpapers, $all_assets"
        echo "11. Info"
        echo "[x]. Exit : choose 'x' to exit"
        echo ""
        
        # Read user input
        local choice=""
        read -p "Enter your choice: " choice
        echo ""

        # Process user choice
        if [ "$choice" = "0" ]; then
            
            clear
            download_dotfiles

        elif [ "$choice" = "1" ]; then
            clear

            if [[ "$omp_git"=="( downloaded )" ]]; then
                run_installer "omp"
            else
                echo "oh-my-posh dotfiles aren't available. Please download dotfiles to continue."
            fi

        elif [ "$choice" = "2" ]; then
            clear
            
            if [[ "$kitty_git"=="( downloaded )" ]]; then
                run_installer "kitty"
            else
                echo "Kitty dotfiles aren't available. Please download dotfiles to continue."
            fi
            
        elif [ "$choice" = "3" ]; then
            clear
            
            if [[ "$tmux_git"=="( downloaded )" ]]; then
                run_installer "tmux"
            else
                echo "Tmux dotfiles aren't available. Please download dotfiles to continue."
            fi
            
        elif [ "$choice" = "4" ]; then
            clear

            if [[ "$neovim_git"=="( downloaded )" ]]; then
                run_installer "nvim"
            else
                echo "Neovim dotfiles aren't available. Please download dotfiles to continue."
            fi

        elif [ "$choice" = "5" ]; then
            clear
            
            if [[ "$bash_git"=="( downloaded )" ]]; then
                run_installer "bash"
            else
                echo "Bash dotfiles aren't available. Please download dotfiles to continue."
            fi

        elif [ "$choice" = "6" ]; then
            clear
            
            if [[ "$wjk_git"=="( downloaded )" ]]; then
                #run_installer "wjk" #JaKooLit Wallpapers --- needs to be configured
            else
                echo "JaKooLit Wallpaper isn't downloaded. Please download JaKooLit's wallpaper to continue."
            fi

        elif [ "$choice" = "7" ]; then
            clear
            
            if [[ "$wmc_git"=="( downloaded )" ]]; then
                run_installer "wmc"
            else
                echo "Minecraft wallpapers aren't downloaded yet. Please download Minecraft Wallpapers to continue."
            fi

        elif [ "$choice" = "8" ]; then
            clear
            
            if [[ "$all_dots"=="( downloaded )" ]]; then
                run_installer "nvim"
                run_installer "kitty"
                run_installer "tmux"
                run_installer "bash"
                run_installer "omp"
            else
                echo "Dotfiles aren't fully downloaded. Please download all dotfiles to continue."
            fi
    
        elif [ "$choice" = "9" ]; then
            clear
            
            if [[ "$all_wallpapers"=="( downloaded )" ]]; then
                run_installer "wmc"
                #run_installer "wjk" #JaKooLit Wallpapers --- needs to be configured
            else
                echo "All wallpapers aren't fully downloaded. Please download all wallpapers to continue."
            fi

        elif [ "$choice" = "10" ]; then
            clear
            
            if [[ "$all_assets"=="( downloaded )" ]]; then
                run_installer "nvim"
                run_installer "kitty"
                run_installer "tmux"
                run_installer "bash"
                run_installer "omp"

                run_installer "wmc"
                #run_installer "wjk" #JaKooLit Wallpapers --- needs to be configured
            else
                echo "All assets aren't fully downloaded yet. Please download all dotfiles and wallpapers to continue."
            fi

        elif [ "$choice" = "11" ]; then
            clear
            
            show_info
            
        elif [ "$choice" = "x" ] || [ "$choice" = "X" ]; then
            clear
            echo "Exiting..."
            break
            
        else
            clear
            
            echo "================================="
            echo "Invalid choice, please try again."
            echo "================================="
            
        fi
    done
}

# Main execution
clear
show_menu
