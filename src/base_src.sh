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