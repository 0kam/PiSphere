#!/bin/bash

# =========================================
# Initial Setup Script - Steps 1, 2 & 3
# Created on: 2024-12-09
# =========================================

# Error Handling
set -e

# Define color codes (Optional)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log Function with Colors
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to display the PiSphere logo with Colors
display_logo() {
    echo -e "${GREEN}"
    cat << "EOF"
    ______   _   ______         _
   (_____ \ (_) / _____)       | |
    _____) ) _ ( (____   ____  | |__   _____   ____  _____
   |  ____/ | | \____ \ |  _ \ |  _ \ | ___ | / ___)| ___ |
   | |      | | _____) )| |_| || | | || ____|| |    | ____|
   |_|      |_|(______/ |  __/ |_| |_||_____)|_|    |_____)
                        |_|

Welcome to PiSphere Setup!
EOF
    echo -e "${NC}"
    echo
}

# Function to display the welcome message with Colors
display_welcome_message() {
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}   Welcome to the PiSphere Setup Script!${NC}"
    echo -e "${GREEN}   This script will automate the necessary${NC}"
    echo -e "${GREEN}   configurations for PiSphere.${NC}"
    echo -e "${GREEN}   Please follow the prompts and provide${NC}"
    echo -e "${GREEN}   the required information.${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
}

# Function to determine the script owner's username
get_script_owner() {
    # Get the absolute path of the script
    SCRIPT_PATH="$(readlink -f "$0")"

    # Get the owner of the script file
    EXEC_USER="$(stat -c '%U' "$SCRIPT_PATH")"

    log "The script is located in the home directory of user: $EXEC_USER"
}

# Function to create pisphere.service from template
create_service_file() {
    # Define the service directory relative to the script's location
    SERVICE_DIR="$(dirname "$SCRIPT_PATH")/service"

    # Path to the template and the new service file
    TEMPLATE_FILE="$SERVICE_DIR/pisphere.service.template"
    SERVICE_FILE="$SERVICE_DIR/pisphere.service"

    # Check if the template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log "Template file $TEMPLATE_FILE does not exist. Exiting."
        exit 1
    fi

    # If the service file exists, delete it
    if [ -f "$SERVICE_FILE" ]; then
        log "Service file $SERVICE_FILE already exists. Deleting it."
        rm "$SERVICE_FILE"
    fi

    # Copy the template to the service file
    cp "$TEMPLATE_FILE" "$SERVICE_FILE"
    log "Copied $TEMPLATE_FILE to $SERVICE_FILE"

    # Replace 'USER' with the actual username
    sed -i "s/USER/$EXEC_USER/g" "$SERVICE_FILE"
    log "Replaced 'USER' with '$EXEC_USER' in $SERVICE_FILE"

    # Change ownership to EXEC_USER
    chown "$EXEC_USER":"$EXEC_USER" "$SERVICE_FILE"
    log "Changed ownership of $SERVICE_FILE to $EXEC_USER"
}

# Function to create pisphere.timer from template
create_timer_file() {
    # Define the service directory relative to the script's location
    SERVICE_DIR="$(dirname "$SCRIPT_PATH")/service"

    # Path to the template and the new timer file
    TEMPLATE_FILE="$SERVICE_DIR/pisphere.timer.template"
    TIMER_FILE="$SERVICE_DIR/pisphere.timer"

    # Check if the template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log "Template file $TEMPLATE_FILE does not exist. Exiting."
        exit 1
    fi

    # If the timer file exists, delete it
    if [ -f "$TIMER_FILE" ]; then
        log "Timer file $TIMER_FILE already exists. Deleting it."
        rm "$TIMER_FILE"
    fi

    # Copy the template to the timer file
    cp "$TEMPLATE_FILE" "$TIMER_FILE"
    log "Copied $TEMPLATE_FILE to $TIMER_FILE"

    # Replace 'START_TIME', 'END_TIME', and 'INTERVAL_MINUTES' with user inputs
    sed -i "s/START_TIME/$START_TIME/g" "$TIMER_FILE"
    sed -i "s/END_TIME/$END_TIME/g" "$TIMER_FILE"
    sed -i "s/INTERVAL_MINUTES/$INTERVAL_MINUTES/g" "$TIMER_FILE"
    log "Replaced 'START_TIME', 'END_TIME', and 'INTERVAL_MINUTES' in $TIMER_FILE"

    # Change ownership to EXEC_USER
    chown "$EXEC_USER":"$EXEC_USER" "$TIMER_FILE"
    log "Changed ownership of $TIMER_FILE to $EXEC_USER"
}

# Function to create run.sh from template
create_run_script() {
    # Define the scripts directory relative to the script's location
    SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")/shs"

    # Path to the template and the new run.sh file
    TEMPLATE_FILE="$SCRIPTS_DIR/run.sh.template"
    RUN_SCRIPT="$SCRIPTS_DIR/run.sh"

    # Check if the template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log "Template file $TEMPLATE_FILE does not exist. Exiting."
        exit 1
    fi

    # If the run.sh file exists, delete it
    if [ -f "$RUN_SCRIPT" ]; then
        log "Run script $RUN_SCRIPT already exists. Deleting it."
        rm "$RUN_SCRIPT"
    fi

    # Copy the template to the run.sh file
    cp "$TEMPLATE_FILE" "$RUN_SCRIPT"
    log "Copied $TEMPLATE_FILE to $RUN_SCRIPT"

    # Replace placeholders with actual values
    sed -i "s/USER/$EXEC_USER/g" "$RUN_SCRIPT"
    sed -i "s/START_TIME/$START_TIME/g" "$RUN_SCRIPT"
    sed -i "s/END_TIME/$END_TIME/g" "$RUN_SCRIPT"
    sed -i "s/INTERVAL_MINUTES/$INTERVAL_MINUTES/g" "$RUN_SCRIPT"
    log "Replaced placeholders in $RUN_SCRIPT"

    # Change ownership to EXEC_USER
    chown "$EXEC_USER":"$EXEC_USER" "$RUN_SCRIPT"
    log "Changed ownership of $RUN_SCRIPT to $EXEC_USER"

    # Make run.sh executable
    chmod +x "$RUN_SCRIPT"
    log "Set execute permission for $RUN_SCRIPT"
}

# Function to create symbolic links for systemd unit files
create_symlinks() {
    # Define the service directory relative to the script's location
    SERVICE_DIR="$(dirname "$SCRIPT_PATH")/service"

    # Define target and link paths
    SERVICE_TARGET="$SERVICE_DIR/pisphere.service"
    SERVICE_LINK="/etc/systemd/system/pisphere.service"

    TIMER_TARGET="$SERVICE_DIR/pisphere.timer"
    TIMER_LINK="/etc/systemd/system/pisphere.timer"

    # Create symbolic link for pisphere.service
    if [ -L "$SERVICE_LINK" ]; then
        log "Symbolic link $SERVICE_LINK already exists. Removing it."
        rm "$SERVICE_LINK"
    elif [ -e "$SERVICE_LINK" ]; then
        log "File $SERVICE_LINK already exists and is not a symbolic link. Exiting to prevent overwrite."
        exit 1
    fi

    ln -s "$SERVICE_TARGET" "$SERVICE_LINK"
    log "Created symbolic link: $SERVICE_LINK -> $SERVICE_TARGET"

    # Create symbolic link for pisphere.timer
    if [ -L "$TIMER_LINK" ]; then
        log "Symbolic link $TIMER_LINK already exists. Removing it."
        rm "$TIMER_LINK"
    elif [ -e "$TIMER_LINK" ]; then
        log "File $TIMER_LINK already exists and is not a symbolic link. Exiting to prevent overwrite."
        exit 1
    fi

    ln -s "$TIMER_TARGET" "$TIMER_LINK"
    log "Created symbolic link: $TIMER_LINK -> $TIMER_TARGET"
}

# Function to reload systemd daemon and enable/start services
reload_and_start_services() {
    # Reload systemd daemon to recognize new unit files
    systemctl daemon-reload
    log "Reloaded systemd daemon."

    # Enable pisphere.service and pisphere.timer to start on boot
    systemctl enable pisphere.service
    log "Enabled pisphere.service."

    systemctl enable pisphere.timer
    log "Enabled pisphere.timer."

    # Start pisphere.service and pisphere.timer
    systemctl start pisphere.service
    log "Started pisphere.service."

    systemctl start pisphere.timer
    log "Started pisphere.timer."
}

# Function to get user input for capture settings
get_user_settings() {
    echo "Please enter the capture start time (HH:MM, 24-hour format, e.g., 07:00):"
    read START_TIME_INPUT
    # Validate input format
    while ! [[ "$START_TIME_INPUT" =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; do
        echo "Invalid format. Please enter time as HH:MM (24-hour format, e.g., 07:00):"
        read START_TIME_INPUT
    done
    START_TIME="$START_TIME_INPUT"

    echo "Please enter the capture end time (HH:MM, 24-hour format, e.g., 18:00):"
    read END_TIME_INPUT
    # Validate input format
    while ! [[ "$END_TIME_INPUT" =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; do
        echo "Invalid format. Please enter time as HH:MM (24-hour format, e.g., 18:00):"
        read END_TIME_INPUT
    done
    END_TIME="$END_TIME_INPUT"

    echo "Please enter the capture interval in minutes (e.g., 30):"
    read INTERVAL_MINUTES_INPUT
    # Validate input is a positive integer
    while ! [[ "$INTERVAL_MINUTES_INPUT" =~ ^[1-9][0-9]*$ ]]; do
        echo "Invalid input. Please enter a positive integer for minutes (e.g., 30):"
        read INTERVAL_MINUTES_INPUT
    done
    INTERVAL_MINUTES="$INTERVAL_MINUTES_INPUT"

    log "User settings - Start Time: $START_TIME, End Time: $END_TIME, Interval: $INTERVAL_MINUTES minutes"
}

# Main Execution Flow

# Display Logo and Welcome Message
display_logo
display_welcome_message

# Determine Executing User based on script's ownership
get_script_owner

# Get user settings for capture
get_user_settings

# Log the EXEC_USER variable
log "The script is being executed for user: $EXEC_USER"

# Create pisphere.service from template
create_service_file

# Create pisphere.timer from template with user settings
create_timer_file

# Create run.sh from template
create_run_script

# Create symbolic links for systemd unit files
create_symlinks

# Reload systemd daemon and enable/start services
reload_and_start_services

log "PiSphere setup completed successfully."
