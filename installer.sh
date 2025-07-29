#!/bin/bash

# Function to check if .git exists in a directory
check_git() {
    local dir=$1
    if [ -d "$dir/.git" ]; then
        return 0
    else
        return 1
    fi
}

# Function to download dotfiles (placeholder for later)
download_dotfiles() {
    echo "Downloading dotfiles... (placeholder)"
    # Add download logic here later
}

# Function to run installer for a specific tool
run_installer() {
    local dir=$1
    local installer_script="$dir/installer_${dir}_dots.sh"
    
    if [ -f "$installer_script" ]; then
        echo "Running installer for $dir..."
        bash "$installer_script"
    else
        echo "Error: Installer script $installer_script not found!"
        return 1
    fi
}

# Function to display info
show_info() {
    echo "Dotfiles Installer"
    echo "This script manages the installation of dotfiles for Neovim, Kitty, Tmux, and Bash."
    echo "Ensure dotfiles are downloaded before running installation options."
    echo "Repository: [Your GitHub repo URL here]"
}

# Function to display the menu
show_menu() {
    # Check .git presence for each directory
    local neovim_git=false
    local kitty_git=false
    local tmux_git=false
    local bash_git=false
    
    # calling function to check .git file
    check_git "neovim" && neovim_git=true
    check_git "kitty" && kitty_git=true
    check_git "tmux" && tmux_git=true
    check_git "bash" && bash_git=true
    
    # Check if all dotfiles are downloaded
    local all_downloaded=true
    if ! $neovim_git || ! $kitty_git || ! $tmux_git || ! $bash_git; then
        all_downloaded=false
    fi

    echo "Dotfiles Installer Menu"
    echo "----------------------"
    echo "0. Download dotfiles"
    
    if $all_downloaded; then
        echo "1. Install all"
    else
        echo "1. Install all (dotfiles not fully downloaded)"
    fi
    
    if $neovim_git; then
        echo "2. Install Neovim dots"
    else
        echo "2. Install Neovim dots (dotfiles not downloaded)"
    fi
    
    if $kitty_git; then
        echo "3. Install Kitty dots"
    else
        echo "3. Install Kitty dots (dotfiles not downloaded)"
    fi
    
    if $tmux_git; then
        echo "4. Install Tmux dots"
    else
        echo "4. Install Tmux dots (dotfiles not downloaded)"
    fi
    
    if $bash_git; then
        echo "5. Install Bash dots"
    else
        echo "5. Install Bash dots (dotfiles not downloaded)"
    fi
    
    echo "6. Info"
    echo "[x]. Exit : choose 'x' to exit"
    echo ""
    
    # Read user input
    read -p "Enter your choice: " choice
    echo ""

    # Process user choice
    if [ "$choice" = "0" ]; then
        download_dotfiles
        show_menu
    elif [ "$choice" = "1" ]; then
        if $all_downloaded; then
            run_installer "neovim"
            run_installer "kitty"
            run_installer "tmux"
            run_installer "bash"
        else
            echo "Dotfiles aren't fully downloaded. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "2" ]; then
        if $neovim_git; then
            run_installer "neovim"
        else
            echo "Neovim dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "3" ]; then
        if $kitty_git; then
            run_installer "kitty"
        else
            echo "Kitty dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "4" ]; then
        if $tmux_git; then
            run_installer "tmux"
        else
            echo "Tmux dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "5" ]; then
        if $bash_git; then
            run_installer "bash"
        else
            echo "Bash dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "6" ]; then
        show_info
        show_menu
    elif [ "$choice" = "x" ] || [ "$choice" = "X" ]; then
        echo "Exiting..."
        exit 0
    else
        echo "Invalid choice, please try again."
        show_menu
    fi
}

# Main execution
show_menu