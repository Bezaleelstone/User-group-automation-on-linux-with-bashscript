#!/bin/bash

# Check if the input file is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

#Initialize variables for input file from the command line
input_file=$1

#Initialize variables for log files and password files
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

# Create log and password directories if they don't exist
sudo mkdir -p /var/log /var/secure
sudo touch "$log_file" "$password_file"
sudo chmod 600 "$password_file"

# Function to log messages
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$log_file"
}

# Function to generate a random password
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Process each line in the input file
while IFS=';' read -r username groups; do
  if id "$username" &>/dev/null; then
    log "User $username already exists."
  else
    # Create the user with a home directory and a personal group
    sudo useradd -m -g "$username" "$username"
    log "User $username and personal group $username created."

    # Set up home directory with appropriate permissions
    sudo chmod 700 "/home/$username"
    sudo chown "$username:$username" "/home/$username"
    log "Home directory for $username set up with correct permissions."

    # Generate a random password and set it for the user
    password=$(generate_password)
    echo "$username:$password" | sudo chpasswd
    log "Password for $username set."
    
    # Store the password securely
    echo "$username:$password" | sudo tee -a "$password_file" > /dev/null
  fi

  # Process groups
  IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do
    if getent group "$group" &>/dev/null; then
      log "Group $group already exists."
    else
      sudo groupadd "$group"
      log "Group $group created."
    fi

    # Add the user to the group
    sudo usermod -aG "$group" "$username"
    log "User $username added to group $group."
  done
done < "$input_file"

log "User and group creation process completed."