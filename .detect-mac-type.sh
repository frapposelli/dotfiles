#!/bin/bash

# Function to check if we're running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script only works on macOS"
        exit 1
    fi
}

# Function to detect if the machine has a battery
detect_machine_type() {
    # Use pmset to get power source information
    local power_info
    power_info=$(pmset -g ps 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to get power information"
        exit 1
    fi
    
    # Check if there's a battery present
    if echo "$power_info" | grep -q "InternalBattery"; then
        echo "This is a MacBook (laptop)"
        
        # Optional: Get additional battery information
        local battery_info
        battery_info=$(system_profiler SPPowerDataType 2>/dev/null | grep -A 10 "Battery Information")
        if [[ -n "$battery_info" ]]; then
            echo -e "\nBattery Details:"
            echo "$battery_info"
        fi
        
        return 0
    else
        echo "This is a desktop Mac"
        return 1
    fi
}

# Main script execution
main() {
    # First check if we're on macOS
    check_macos
    
    # Then detect the machine type
    detect_machine_type
}

# Run the script
main
