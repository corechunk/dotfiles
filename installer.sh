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
    if git clone "$repo_url" .;then
        local error=false
        echo "downloaded contents from $repo_url successfully"
    else
        local error=true
        echo "contents from $repo_url couldn't be downloaded !!"
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
        echo "2. Download Neovim dotfiles"
        echo "3. Download Kitty dotfiles"
        echo "4. Download Tmux dotfiles"
        echo "5. Download Bash dotfiles"
        echo "6. Download all dotfiles"
        echo "[x]. Back to main menu : choose 'x' to return"
        echo "----------------------"
        
        read -p "Enter your choice: " choice
        echo ""
        
        case $choice in
            1)
                # @warning  it will only work if you provide the repo url without the ".git"
                #[ e.g. "https://github.com/Miraj13123/Neovim" instead of "https://github.com/Miraj13123/Neovim.git" ]
                download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
                ;;
            2)
                download_dotfile "neovim" "https://github.com/Miraj13123/Neovim.git"
                ;;
            3)
                download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
                ;;
            4)
                download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
                ;;
            5)
                download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
                ;;
            6)
                download_dotfile "neovim" "https://github.com/Miraj13123/Neovim.git"
                download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
                download_dotfile "tmux" "https://github.com/Miraj13123/Tmux.git"
                download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
                download_dotfile "omp" "https://github.com/Miraj13123/omp.git"
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
    echo "Dotfiles Installer"
    echo "This script manages the installation of dotfiles for Oh-My-Posh, Neovim, Kitty, Tmux, and Bash."
    echo "Ensure dotfiles are downloaded before running installation options."
    echo "Repository: [Your GitHub repo URL here]"
}

# Function to display the menu
show_menu() {
    # Check .git presence for each directory
    local neovim_git="(dotfiles aren't downloaded)"
    local kitty_git="(dotfiles aren't downloaded)"
    local tmux_git="(dotfiles aren't downloaded)"
    local bash_git="(dotfiles aren't downloaded)"
    local omp_git="(dotfiles aren't downloaded)"
    
    # calling function to check .git file
    check_git "neovim" && neovim_git="(dotfiles are downloaded)"
    check_git "kitty" && kitty_git="(dotfiles are downloaded)"
    check_git "tmux" && tmux_git="(dotfiles are downloaded)"
    check_git "bash" && bash_git="(dotfiles are downloaded)"
    check_git "omp" && omp_git="(dotfiles are downloaded)"
    
    # Check if all dotfiles are downloaded
    local all_downloaded="(all dotfiles are downloaded)"
    for dir in neovim kitty tmux bash omp; do
        if ! check_git "$dir"; then
            all_downloaded="(all dotfiles aren't downloaded)"
            break
        fi
    done

    echo "Dotfiles Installer Menu"
    echo "----------------------"
    echo "0. Download dotfiles"
    echo "1. Install all, $all_downloaded"
    echo "2. Install oh-my-posh dots, $omp_git"
    echo "3. Install Neovim dots, $neovim_git"
    echo "4. Install Kitty dots, $kitty_git"
    echo "5. Install Tmux dots, $tmux_git"
    echo "6. Install Bash dots, $bash_git"
    echo "7. Info"
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
        show_menu
    elif [ "$choice" = "1" ]; then
        clear
        if [[ "$all_downloaded"=="(all dotfiles are downloaded)" ]]; then
            run_installer "neovim"
            run_installer "kitty"
            run_installer "tmux"
            run_installer "bash"
            run_installer "omp"
        else
            echo "Dotfiles aren't fully downloaded. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "2" ]; then
        clear
        if [[ "$omp_git"=="(dotfiles are downloaded)" ]]; then
            run_installer "omp"
        else
            echo "oh-my-posh dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "3" ]; then
        clear
        if [[ "$neovim_git"=="(dotfiles are downloaded)" ]]; then
            run_installer "neovim"
        else
            echo "Neovim dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "4" ]; then
        clear
        if [[ "$kitty_git"=="(dotfiles are downloaded)" ]]; then
            run_installer "kitty"
        else
            echo "Kitty dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "5" ]; then
        clear
        if [[ "$tmux_git"=="(dotfiles are downloaded)" ]]; then
            run_installer "tmux"
        else
            echo "Tmux dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "6" ]; then
        clear
        if [[ "$bash_git"=="(dotfiles are downloaded)" ]]; then
            run_installer "bash"
        else
            echo "Bash dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "7" ]; then
        clear
        show_info
        show_menu
    elif [ "$choice" = "x" ] || [ "$choice" = "X" ]; then
        clear
        echo "Exiting..."
        exit 0
    else
        clear
        echo "================================="
        echo "Invalid choice, please try again."
        echo "================================="
        show_menu
    fi
}

# Main execution
clear
show_menu