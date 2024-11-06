#!/bin/bash

# Check if yq is installed (required for YAML parsing)
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it first:"
    echo "brew install yq"
    exit 1
fi

# Default config file location
CONFIG_FILE="dock-config.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [-b filename | -a filename]"
    echo "Options:"
    echo "  -b filename    Backup current dock configuration to specified YAML file"
    echo "  -a filename    Apply dock configuration from specified YAML file"
    echo "  -h            Show this help message"
    exit 1
}

# Function to get app name from bundle path
get_app_name() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    echo "$app_name"
}

# Function to safely read defaults with fallback
read_defaults() {
    local domain="$1"
    local key="$2"
    local default_value="$3"
    local type="$4"
    
    local value
    if value=$(defaults read "$domain" "$key" 2>/dev/null); then
        echo "$value"
    else
        echo "$default_value"
    fi
}

# Function to backup current dock configuration
backup_dock() {
    local output_file="$1"
    echo "Backing up current dock configuration to $output_file..."
    
    # Create temporary files for building the YAML
    local temp_file=$(mktemp)
    local temp_plist=$(mktemp)
    
    # Export dock configuration to a temporary plist
    defaults export com.apple.dock "$temp_plist"
    
    # Start building YAML structure
    echo "dock_apps:" > "$temp_file"
    
    # Debug output
    echo "DEBUG: Starting dock backup process..." > /tmp/dock-debug.log
    echo "DEBUG: PlistBuddy output for persistent-apps:" >> /tmp/dock-debug.log
    /usr/libexec/PlistBuddy -c "Print persistent-apps:" "$temp_plist" >> /tmp/dock-debug.log 2>&1
    
    # Extract app entries using PlistBuddy
    local app_count=$(/usr/libexec/PlistBuddy -c "Print persistent-apps:" "$temp_plist" 2>/dev/null | grep -c "_CFURLString")
    echo "DEBUG: Found $app_count apps" >> /tmp/dock-debug.log
    
    if [ "$app_count" -gt 0 ]; then
        for ((i=0; i<$app_count; i++)); do
            local app_path=$(/usr/libexec/PlistBuddy -c "Print persistent-apps:${i}:tile-data:file-data:_CFURLString" "$temp_plist" 2>/dev/null)
            
            if [ ! -z "$app_path" ] && [[ "$app_path" == *.app* ]]; then
                # Remove file:// prefix and decode URL encoding
                app_path=$(echo "$app_path" | sed 's|^file://||' | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))')
                local app_name=$(get_app_name "$app_path")
                echo "  - name: \"$app_name\"" >> "$temp_file"
                echo "    path: \"$app_path\"" >> "$temp_file"
                echo "    position: $((i+1))" >> "$temp_file"
                echo "" >> "$temp_file"
                echo "DEBUG: Added app: $app_name at $app_path" >> /tmp/dock-debug.log
            fi
        done
    fi
    
    # Add current dock settings with defaults
    echo "settings:" >> "$temp_file"
    echo "  minimize_effect: \"$(read_defaults com.apple.dock mineffect "genie")\"" >> "$temp_file"
    echo "  magnification: $(read_defaults com.apple.dock magnification "false")" >> "$temp_file"
    echo "  magnification_size: $(read_defaults com.apple.dock largesize "64")" >> "$temp_file"
    echo "  icon_size: $(read_defaults com.apple.dock tilesize "48")" >> "$temp_file"
    echo "  autohide: $(read_defaults com.apple.dock autohide "false")" >> "$temp_file"
    
    # Format the YAML nicely using yq
    yq eval -P "$temp_file" > "$output_file"
    
    # Clean up temporary files
    rm "$temp_file"
    rm "$temp_plist"
    
    echo "Backup complete! Current dock configuration has been saved to $output_file"
    echo "DEBUG: Backup process completed" >> /tmp/dock-debug.log
}

# Function to reset the dock
reset_dock() {
    echo "Clearing current dock items..."
    defaults write com.apple.dock persistent-apps -array
}

# Function to set dock settings
apply_dock_settings() {
    local config_file="$1"
    echo "Applying dock settings..."
    
    # Get settings from YAML
    minimize_effect=$(yq eval '.settings.minimize_effect' "$config_file")
    magnification=$(yq eval '.settings.magnification' "$config_file")
    magnification_size=$(yq eval '.settings.magnification_size' "$config_file")
    icon_size=$(yq eval '.settings.icon_size' "$config_file")
    autohide=$(yq eval '.settings.autohide' "$config_file")
    
    # Apply settings
    defaults write com.apple.dock mineffect -string "$minimize_effect"
    defaults write com.apple.dock magnification -bool "$magnification"
    defaults write com.apple.dock largesize -int "$magnification_size"
    defaults write com.apple.dock tilesize -int "$icon_size"
    defaults write com.apple.dock autohide -bool "$autohide"
}

# Function to add an app to the dock
add_app_to_dock() {
    local app_path="$1"
    
    # Remove file:// prefix and decode URL encoding if present
    app_path=$(echo "$app_path" | sed 's|^file://||' | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))')
    
    if [ ! -d "$app_path" ]; then
        echo "Warning: Application not found: $app_path"
        return
    fi
    
    echo "Adding $app_path to dock..."
    defaults write com.apple.dock persistent-apps -array-add "<dict>
        <key>tile-data</key>
        <dict>
            <key>file-data</key>
            <dict>
                <key>_CFURLString</key>
                <string>$app_path</string>
                <key>_CFURLStringType</key>
                <integer>0</integer>
            </dict>
        </dict>
    </dict>"
}

# Function to apply configuration
apply_configuration() {
    local config_file="$1"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file $config_file not found"
        exit 1
    fi
    
    echo "Starting dock configuration..."
    
    # Reset the dock first
    reset_dock
    
    # Get the number of apps in the configuration
    num_apps=$(yq eval '.dock_apps | length' "$config_file")
    
    # Read and process each app from the configuration
    for ((i=0; i<$num_apps; i++)); do
        app_path=$(yq eval ".dock_apps[$i].path" "$config_file")
        app_name=$(yq eval ".dock_apps[$i].name" "$config_file")
        echo "Processing $app_name..."
        add_app_to_dock "$app_path"
    done
    
    # Apply dock settings
    apply_dock_settings "$config_file"
    
    # Restart the Dock to apply changes
    echo "Restarting Dock to apply changes..."
    killall Dock
    
    echo "Dock configuration complete!"
}

# Parse command line arguments
while getopts "b:a:h" opt; do
    case $opt in
        b)
            backup_dock "$OPTARG"
            exit 0
            ;;
        a)
            CONFIG_FILE="$OPTARG"
            apply_configuration "$CONFIG_FILE"
            exit 0
            ;;
        h)
            show_usage
            ;;
        \?)
            show_usage
            ;;
    esac
done

# If no arguments provided, show usage
if [ $OPTIND -eq 1 ]; then
    show_usage
fi
