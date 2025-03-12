#!/bin/bash

# Function to prompt for a variable if it is not defined
prompt_for_variable() {
    local var_name=$1
    local prompt_message=$2

    if [ -z "${!var_name}" ]; then
        read -p "$prompt_message: " $var_name
    fi
}

# Example variables that might be used in the script
# You can define default values here if you want
VAR1=""
VAR2=""

# Prompt for VAR1 if it is not defined
prompt_for_variable "VAR1" "Please enter a value for VAR1"

# Prompt for VAR2 if it is not defined
prompt_for_variable "VAR2" "Please enter a value for VAR2"

# Now you can use VAR1 and VAR2 in your script
echo "VAR1 is set to: $VAR1"
echo "VAR2 is set to: $VAR2"

# Rest of your script...
