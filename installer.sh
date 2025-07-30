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

# Function to download a single dotfile repository
download_dotfile() {
    local folder=$1
    local repo_url=$2
    local temp_dir="temp_$(date +%s)"
    
    echo "Downloading $folder dotfiles from $repo_url..."
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Download the tarball
    if curl -L --fail "$repo_url/archive/refs/heads/main.tar.gz" -o "$temp_dir/repo.tar.gz"; then
        # Verify tarball is a valid gzip file
        if file "$temp_dir/repo.tar.gz" | grep -q "gzip compressed data"; then
            # Extract tarball
            if tar -xzf "$temp_dir/repo.tar.gz" -C "$temp_dir"; then
                # Find the extracted folder (GitHub appends branch name, e.g., Kitty-main)
                extracted_folder=$(ls "$temp_dir" | grep -E '.*-main$')
                
                if [ -d "$temp_dir/$extracted_folder" ]; then
                    # Create target folder if it doesn't exist
                    mkdir -p "$folder"
                    
                    # Move contents (not the folder itself) to the target folder
                    mv "$temp_dir/$extracted_folder/"* "$folder/" 2>/dev/null || {
                        echo "Error: Failed to move contents to $folder."
                        rm -rf "$temp_dir"
                        return 1
                    }
                    
                    echo "$folder dotfiles downloaded successfully."
                else
                    echo "Error: Could not find extracted folder in $temp_dir."
                    rm -rf "$temp_dir"
                    return 1
                fi
            else
                echo "Error: Failed to extract tarball."
                rm -rf "$temp_dir"
                return 1
            fi
        else
            echo "Error: Downloaded file is not a valid gzip tarball."
            rm -rf "$temp_dir"
            return 1
        fi
        # Clean up
        rm -rf "$temp_dir"
    else
        echo "Error: Failed to download repository from $repo_url."
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to show download menu
download_menu() {
    clear
    echo "Download Dotfiles Menu"
    echo "----------------------"
    echo "1. Download Neovim dotfiles"
    echo "2. Download Kitty dotfiles"
    echo "3. Download Tmux dotfiles"
    echo "4. Download Bash dotfiles"
    echo "5. Download all dotfiles"
    echo "[x]. Back to main menu : choose 'x' to return"
    echo ""
    
    read -p "Enter your choice: " choice
    echo ""
    
    case $choice in
        1)
            download_dotfile "neovim" "https://github.com/Miraj13123/Neovim.git"
            download_menu
            ;;
        2)
            download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
            download_menu
            ;;
        3)
            download_dotfile "tmux" "https://github.com/Miraj13123/tmux.git"
            download_menu
            ;;
        4)
            download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
            download_menu
            ;;
        5)
            download_dotfile "neovim" "https://github.com/Miraj13123/Neovim.git"
            download_dotfile "kitty" "https://github.com/Miraj13123/Kitty.git"
            download_dotfile "tmux" "https://github.com/Miraj13123/tmux.git"
            download_dotfile "bash" "https://github.com/Miraj13123/Bash.git"
            download_menu
            ;;
        x|X)
            clear
            #show_menu
            ;;
        *)
            clear
            echo "================================="
            echo "Invalid choice, please try again."
            echo "================================="
            download_menu
            ;;
    esac
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
        clear
        download_dotfiles
        show_menu
    elif [ "$choice" = "1" ]; then
        clear
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
        clear
        if $neovim_git; then
            run_installer "neovim"
        else
            echo "Neovim dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "3" ]; then
        clear
        if $kitty_git; then
            run_installer "kitty"
        else
            echo "Kitty dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "4" ]; then
        clear
        if $tmux_git; then
            run_installer "tmux"
        else
            echo "Tmux dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "5" ]; then
        clear
        if $bash_git; then
            run_installer "bash"
        else
            echo "Bash dotfiles aren't available. Please download dotfiles to continue."
        fi
        show_menu
    elif [ "$choice" = "6" ]; then
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