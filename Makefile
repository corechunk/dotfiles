SHELL := /usr/bin/env bash

# Define the name of the combined script
TARGET_SCRIPT := installer.sh

# List all dependency files in the correct order for concatenation
DEPENDENCY_FILES := \
    src/base_src.sh \
	src/delete_src.sh \
	src/download_src.sh \
	src/info_src.sh \
	src/installer_src.sh


.PHONY: all build clean


# Target to clean up generated files
clean:
	@echo "Cleaning up generated files..."
	rm -f $(TARGET_SCRIPT)
	@echo "Clean up complete."
# Target to build the combined script
build: $(TARGET_SCRIPT)

$(TARGET_SCRIPT): installer.sh $(DEPENDENCY_FILES)
	@echo "Building $(TARGET_SCRIPT)..."
	# Concatenate all dependency files, ensuring each is followed by a newline
	for file in $(DEPENDENCY_FILES); do \
		cat "$$file" >> $(TARGET_SCRIPT); \
		echo >> $(TARGET_SCRIPT); \
	done
	
	# Make the combined script executable
	chmod +x $(TARGET_SCRIPT)
	@echo "Successfully built $(TARGET_SCRIPT)"
rebuild: clean build


