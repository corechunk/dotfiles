# Project Overview

This repository, `corechunk/dotfiles`, centralizes configuration files for various tools, making it easy to set up a consistent development environment. It includes configurations for Oh-My-Posh, Neovim, Kitty, Tmux, Bash, and now Hyprland (though currently marked as incomplete). It also manages wallpaper repositories for JaKooLit, Minecraft, and OS-specific wallpapers. The `installer.sh` script automates the downloading, installation, and uninstallation of these dotfiles and wallpapers via a user-friendly menu, offering both CLI and TUI modes.

## Main Technologies

*   **Bash Scripting**: The core logic for installation, download, and management is implemented in `installer.sh`.
*   **Git**: Used for cloning and managing sub-repositories for each dotfile/wallpaper collection.
*   **Configuration Files**: Various configuration file types (`.conf`, `.lua`, etc.) are managed for tools like Neovim, Kitty, Tmux, Bash, Oh-My-Posh, and Hyprland.

## Architecture

The project follows a modular approach where each tool/wallpaper collection resides in its own dedicated folder (e.g., `nvim/`, `kitty/`, `hyprland/`, `omp/`, `bash/`, `tmux/`, `wmc/`, `wjk/`, `wos/`). These folders potentially contain their own installer scripts (e.g., `installer_nvim_dots.sh`). The root `installer.sh` acts as a central orchestrator, providing a unified interface for managing these disparate configurations.

## Building and Running

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/corechunk/dotfiles.git
    cd dotfiles
    ```

2.  **Run the Installer**:
    ```bash
    chmod +x installer.sh
    ./installer.sh
    ```

3.  **Menu Navigation (via `installer.sh`):**
    The `installer.sh` script presents an interactive menu with the following options:

    *   `0`: Access the Download page for downloading any assets (dotfiles and wallpapers).
    *   `1`: Install Hyprland dotfiles (incomplete).
    *   `2`: Install oh-my-posh dotfiles.
    *   `3`: Install Kitty dotfiles.
    *   `4`: Install Tmux dotfiles.
    *   `5`: Install Neovim dotfiles.
    *   `6`: Install Bash dotfiles.
    *   `7`: Install JaKooLit wallpapers.
    *   `8`: Install Minecraft wallpapers.
    *   `9`: Install OS wallpapers.
    *   `10`: Install all dotfiles only (comprising 6 repositories: Hyprland, Oh-My-Posh, Kitty, Tmux, Neovim, Bash).
    *   `11`: Install all wallpapers only (comprising 3 repositories: Minecraft, JaKooLit, OS wallpapers).
    *   `12`: Install all dotfiles and all wallpapers (comprising a total of 9 repositories).
    *   `13`: Display information about the installer options.
    *   `x`: Exit the script.

4.  **Direct Installer Execution**:
    Individual installers within tool folders (e.g., `bash nvim/installer_nvim_dots.sh`) can be run standalone for specific tool installations.

## Development Conventions

*   **Modular Structure**: Each dotfile/wallpaper collection is maintained in its own dedicated directory, promoting organization and ease of management.
*   **Installer-Driven Workflow**: The primary method for managing (downloading, installing, uninstalling) dotfiles and wallpapers is through the central `installer.sh` script, which provides a consistent user experience.
*   **Git-Based Version Control**: All managed configurations are version-controlled using Git, typically by cloning separate repositories into the respective tool/wallpaper directories.
*   **Bash Scripting**: The automation logic is implemented using Bash scripting, adhering to common shell scripting practices.
*   **Hyprland Integration**: Hyprland's integration is currently marked as "incomplete," indicating ongoing development or missing components (e.g., its dedicated installer script).
*   **Documentation**: The `README.md` file is expected to be kept up-to-date, reflecting the current state and functionality of the `installer.sh` script and the managed dotfiles.
