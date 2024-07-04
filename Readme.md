# Automating User and Group Management in Linux using Bash scripting: A Comprehensive Guide

## INTRODUCTION
Automation is an important aspect of DevOps enginneering. It reduces friction, saves time, and boosts efficiency and productivity.
In this article, we will explore a Bash script designed to automate the creation of users and groups based on input from a text file. Each user will have a personal group with the same name, and additional groups can be specified in the input file. The script also logs out the actions and securely stores generated passwords.

## TASK:
Your company has employed many new developers. As a SysOps engineer, write a bash script called create_users.sh that reads a text file containing the employee’s usernames and group names, where each line is formatted as user;groups.The script should: 
* Create users and groups as specified,
* Set up home directories with appropriate permissions and ownership,
* Generate random passwords for the users,
* Log all actions to `/var/log/user_management.log`,
* Store the generated passwords securely in `/var/secure/user_passwords.txt`.
* Ensure error handling for scenarios like existing users.
* Each User must have a personal group with the same group name as the username, this group name will not be written in the text file.

## SCRIPT BREAKDOWN

1. **Check for Input File and Define Variables:** The script starts off by declaring the shebang  ('#!/bin/bash') to specify the interpreter. If statement is use to check if a valid input file was provided in the command line, then initialises a variable to store the input file, logs and password.

```
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
```

2. **Create the Neccesary Directories:** This block ensures that the neccesary directories are created and it sets the appropriate permissions to secure the password file.
```
# Create log and password directories if they don't exist
sudo mkdir -p /var/log /var/secure
sudo touch "$log_file" "$password_file"
sudo chmod 600 "$password_file"

```

3. **The Log Function:** This function in the script appends messages with timestamps to the log file. This helps in tracking the actions performed by the script.

```
# Function to log messages
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$log_file"
}

```

4. **Function to Generate random Passwords:** This function uses `/dev/urandom`, a secure random number generator, to generate a random 12-character password for the users once they are created.
```
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}
```

5. **Main Script:** The main script is a while loop that is made of of two main blocks- The user processing and the group processing. I explain better below.

i. **User Processing:** This block carries out a number of actions as follows-
* **Read Input File:** The script uses IFS=';' to read each line from the input file, splitting it into username and groups using the  read -r command.
* **Create Users:** If the user does not already exist (`id "$username"`), the script creates the user along with a personal group (`-g "$username"`) and sets up the home directory with appropriate permissions.
* **Password Management**: The script calls the `generate_password()` function which generates a random password, assigns it to the user, and stores it securely.

```
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
```
**Group Processing:** This block processes additional groups from the input file, creating them if necessary, and adds the user to these groups.
* **Read input file with IFS:** IFS=',': The IFS is set to a comma, which means the read command will split the input string based on commas and store the groups in an array. This will enable the user to be added to multiple groups according to the input file.
* **Read Groups in Array:** After the groups have been stored in an array, a for loop is used to iterate over each group in the array.
* **Check if groups exist and Creats groups:** An if statement in the script checks if the group already exists, then creats one. It logs out the output of both cases.
* **Add User:** Finally the users are added to their appropriate groups.

```
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
```
## Execute Script
Make the script executable by running `chmod +x create_users.sh` in your terminal
Run the script with the input file like this `./create_users.sh input.txt`

This was a stage 1 DevOps Task at [HNG Internship](https://hng.tech/internship). You can check for available roles at [HNG Hire](https://hng.tech/hire).

You can find entire code here: https://github.com/Bezaleelstone/bash-script-for-HNG-stage-1