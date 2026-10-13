#!/bin/bash

#
# deploy_agent.sh
# Author: Isse112
#
# A shell script with three features for the Student Attendance
# Tracker Python app:
#   1. Deploy  - set up a new attendance_tracker_{name}/ project
#   2. Run     - run an already deployed project
#   3. Archive - archive the log files after a run
#
# It also safely handles Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP) while
# deploying, by zipping up whatever was created so far before exiting.
#

echo "deploy_agent.sh is starting..."

# 
# Pre-flight checks: make sure python3 and zip are installed
#
command -v python3 > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: python3 is not installed. Please install it first."
    exit 1
fi

command -v zip > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: zip is not installed. Please install it first."
    exit 1
fi

echo "Pre-flight checks passed: python3 and zip are installed."

# 
# Feature 2: Run an already deployed project
# 
run_app() {
    read -p "Enter the project name you want to run (the {name} part of attendance_tracker_{name}): " project_name
    project_dir="attendance_tracker_${project_name}"

    if [ ! -d "$project_dir" ]; then
        echo "ERROR: $project_dir does not exist. Deploy it first."
        exit 1
    fi

    cd "$project_dir"
    python3 attendance_checker.py
}
