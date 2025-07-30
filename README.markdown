# Dotfiles

Welcome to my dotfiles repository! This repo, `Miraj13123/dotfiles`, centralizes my configuration files for tools like Neovim, Kitty, Tmux, and Bash, making it easy to set up a consistent development environment across systems. The `installer.sh` script automates the process of downloading and installing these dotfiles, with user-friendly prompts to guide you through each step. Whether you're looking to adopt my configurations or use this as a template for your own dotfiles, this repo is designed to be modular and customizable.

## Table of Contents
- [Usage Guide](#usage-guide)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Installation Details](#installation-details)
- [Controls and Keybindings](#controls-and-keybindings)
- [License](#license)


## Gallery
<div style="display: flex; flex-wrap: wrap; gap: 10px;">
  <div style="flex: 1; min-width: 45%; max-width: 45%;">
    <img src="assets/image1.png" alt="Image 1" style="width: 100%; height: auto;">
    <img src="image2.png" alt="Image 2" style="width: 100%; height: auto;">
  </div>
  <div style="flex: 1; min-width: 45%; max-width: 45%;">
    <img src="image3.png" alt="Image 3" style="width: 100%; height: auto;">
    <img src="image4.png" alt="Image 4" style="width: 100%; height: auto;">
  </div>
</div>

---
Neovim | Tmux

-------------

 kitty_ _ _| Bash  

## Usage Guide
The `installer.sh` script is the main entry point for managing your dotfiles. Follow these steps to get started:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Miraj13123/dotfiles.git
   cd dotfiles
   ```

2. **Run the Installer**:
   ```bash
   chmod +x installer.sh
   ./installer.sh
   ```

3. **Navigate the Menu**:
   - The script displays a menu with the following options:
     - `0`: Download dotfiles from their respective repositories.
     - `1`: Install all dotfiles (requires all dotfiles to be downloaded).
     - `2-5`: Install dotfiles for Neovim, Kitty, Tmux, or Bash individually.
     - `6`: Display information about the repo.
     - `x`: Exit the script.
   - For option `0`, a sub-menu allows you to download specific dotfiles or all at once.
   - Options `1-5` are enabled only if the corresponding dotfiles are downloaded (checked via `.git` presence).

4. **Follow Prompts**:
   - The installer prompts for confirmation at each major step (e.g., installing dependencies, copying files).
   - For example, the Kitty installer checks for Kitty, fonts, and configuration files, asking for y/n input before proceeding.

## Prerequisites
Before running `installer.sh`, ensure the following are installed on your system:
- **Bash**: The script is written for Bash.
- **Git**: Required to clone the repository and check `.git` folders.
- **Curl**: Used to download dotfiles from GitHub.
- **Tar**: Needed to extract downloaded tarballs.
- **Package Manager**: Either `apt` (Debian-based) or `pacman` (Arch-based) for installing dependencies like Kitty.
- **Unzip** and **Fontconfig**: Required for installing fonts (e.g., FantasqueSansM Nerd Font Mono for Kitty).
- **Sudo**: Some installations (e.g., Kitty via `apt` or `pacman`) require superuser privileges.

To install these on a Debian-based system:
```bash
sudo apt update
sudo apt install -y git curl tar unzip fontconfig
```

On an Arch-based system:
```bash
sudo pacman -Syu --noconfirm git curl tar unzip fontconfig
```

## Repository Structure
The repository is organized as follows:
```
dotfiles/
├── .git/
├── bash/
│   └── installer_bash_dots.sh (not yet implemented)
├── kitty/
│   ├── installer_kitty_dots.sh
│   ├── kitty_custom.conf
│   ├── kitty-colors.conf
│   └── kitty-themes/
├── neovim/
│   └── installer_neovim_dots.sh (not yet implemented)
├── tmux/
│   └── installer_tmux_dots.sh (not yet implemented)
├── installer.sh
└── LICENSE
```
- Each tool’s folder contains its configuration files and an installer script (e.g., `installer_kitty_dots.sh`).
- The root `installer.sh` orchestrates downloading and running these installers.
- The `LICENSE` file specifies the terms of use (MIT License, as per your repo).

## Installation Details
The `installer.sh` script performs the following:
- **Download Dotfiles**: Fetches configurations from their respective GitHub repositories (e.g., `https://github.com/Miraj13123/Neovim.git` for Neovim) using `curl` and extracts them into the corresponding folders (`neovim`, `kitty`, etc.).
- **Check Dependencies**: Verifies if `.git` exists in each tool’s folder to enable installation options.
- **Run Installers**: Executes tool-specific installers (e.g., `installer_kitty_dots.sh`):
  - **Kitty**: Installs Kitty (if needed), the FantasqueSansM Nerd Font Mono, and copies `kitty_custom.conf`, `kitty-colors.conf`, and themes to `~/.config/kitty`. It includes files in `kitty.conf` and prompts for confirmation at each step.
  - **Neovim, Tmux, Bash**: Placeholder installers (to be implemented) will follow a similar pattern.
- **User Interaction**: All actions require user confirmation via y/n prompts, ensuring control over what gets installed.

Each tool’s installer can also be run standalone from its folder (e.g., `bash kitty/installer_kitty_dots.sh`).

## Controls and Keybindings
To explore the specific keybindings and configurations for each tool:
- For Neovim keybindings and configurations, visit [https://github.com/Miraj13123/Neovim.git](https://github.com/Miraj13123/Neovim.git).
- Keybindings for Kitty, Tmux, and Bash are included in their respective configuration files in this repository. Check the `kitty/kitty_custom.conf`, `tmux/`, and `bash/` folders after downloading for details.

## License
This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.