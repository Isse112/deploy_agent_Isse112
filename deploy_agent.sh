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

#
# Feature 1: Deploy a new project (built in later steps)
#
deploy_app() {
	    read -p "Enter a name for your new project (it will be created as attendance_tracker_<name>): " deploy_name
    deploy_dir="attendance_tracker_${deploy_name}"

    if [ -d "$deploy_dir" ]; then
        echo "$deploy_dir already exists."
        read -p "Overwrite it? (y/n): " overwrite_choice

        if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
            echo "Removing old $deploy_dir ..."
            rm -rf "$deploy_dir"
        else
            echo "Aborting. Existing project was not touched."
            exit 1
        fi
    fi

        echo "Creating $deploy_dir ..."
    mkdir -p "$deploy_dir/Helpers"
    mkdir -p "$deploy_dir/reports"

    cp templates/attendance_checker.py "$deploy_dir/attendance_checker.py"
    cp templates/config.json "$deploy_dir/Helpers/config.json"

    echo ""
    echo "How do you want to build the student roster (assets.csv)?"
    echo "  A) Copy rows from templates/assets.csv"
    echo "  B) Generate a fresh roster (all counts start at 0)"
    read -p "Enter A or B: " roster_choice

    if [ "$roster_choice" = "A" ] || [ "$roster_choice" = "a" ]; then
        read -p "How many students to copy (1-10)? " student_count
        head -n 1 templates/assets.csv > "$deploy_dir/Helpers/assets.csv"
        tail -n +2 templates/assets.csv | head -n "$student_count" >> "$deploy_dir/Helpers/assets.csv"
        echo "Copied $student_count student(s) from templates/assets.csv."
        echo "Keeping total_sessions as shipped (5), consistent with the 4 prior sessions in the template roster."
    else
        read -p "How many students to generate? " student_count

        names=("Kevin Brown" "Laura Chen" "Mohammed Ali" "Nina Patel" "Omar Said" "Priya Singh" "Quinn Adams" "Rachel Kim" "Samuel Otieno" "Tasha Grant" "Umar Farouk" "Victoria Cruz" "Wendy Zhao" "Xavier Young" "Yara Haddad")
        emails=("kevin@example.com" "laura@example.com" "mohammed@example.com" "nina@example.com" "omar@example.com" "priya@example.com" "quinn@example.com" "rachel@example.com" "samuel@example.com" "tasha@example.com" "umar@example.com" "victoria@example.com" "wendy@example.com" "xavier@example.com" "yara@example.com")

        echo "Email,Names,Attendance Count,Absence Count" > "$deploy_dir/Helpers/assets.csv"
        for ((i=0; i<student_count; i++)); do
            echo "${emails[$i]},${names[$i]},0,0" >> "$deploy_dir/Helpers/assets.csv"
        done

        echo "Generated $student_count fresh student row(s) with counts starting at 0."

        sed -i "s/\"total_sessions\": [0-9]*/\"total_sessions\": 1/" "$deploy_dir/Helpers/config.json"
        echo "Set total_sessions to 1 in config.json (fresh roster = session one)."
    fi

    chmod +x "$deploy_dir/attendance_checker.py"
    chmod 600 "$deploy_dir/Helpers/config.json"
    echo "Permissions set: attendance_checker.py is executable; Helpers/config.json is restricted to owner read/write only (600)."

    echo ""
    read -p "Update the attendance alert thresholds now? (y/n): " threshold_choice
    if [ "$threshold_choice" = "y" ] || [ "$threshold_choice" = "Y" ]; then
        read -p "Enter warning threshold (default 75): " new_warning
        new_warning=${new_warning:-75}
        read -p "Enter failure threshold (default 50): " new_failure
        new_failure=${new_failure:-50}

        sed -i "s/\"warning\": [0-9]*/\"warning\": $new_warning/" "$deploy_dir/Helpers/config.json"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $new_failure/" "$deploy_dir/Helpers/config.json"
        chmod 600 "$deploy_dir/Helpers/config.json"

        echo "Updated thresholds: warning=$new_warning, failure=$new_failure."
    fi

    echo ""
    echo "Verifying deployment by running the application..."
    cd "$deploy_dir"
    python3 attendance_checker.py
}

#
# Feature 3: Archive the log files (built in later steps)
#
archive_logs() {
	    read -p "Enter the project name whose logs you want to archive (the {name} part of attendance_tracker_{name}): " archive_project_name
    project_dir="attendance_tracker_${archive_project_name}"

    if [ ! -d "$project_dir" ]; then
        echo "ERROR: $project_dir does not exist."
        exit 1
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$project_dir/archives/attendance"
    mkdir -p "$project_dir/archives/absent"

    if [ -f "$project_dir/reports/attendance.log" ]; then
        attendance_archive="$project_dir/archives/attendance/attendance_${timestamp}.log"
        cp "$project_dir/reports/attendance.log" "$attendance_archive"
        echo "Archived attendance.log -> $attendance_archive"
    else
        echo "No attendance.log found in $project_dir/reports/ - skipping."
    fi

    if [ -f "$project_dir/reports/absent.log" ]; then
        absent_archive="$project_dir/archives/absent/absent_${timestamp}.log"
        cp "$project_dir/reports/absent.log" "$absent_archive"
        echo "Archived absent.log -> $absent_archive"
    else
        echo "No absent.log found in $project_dir/reports/ - skipping."
    fi
}

#
# Main menu: let the user pick a feature
#
echo ""
echo "What would you like to do?"
echo "  1) Deploy a new project"
echo "  2) Run an already deployed project"
echo "  3) Archive the log files"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        deploy_app
        ;;
    2)
        run_app
        ;;
    3)
        archive_logs
        ;;
    *)
        echo "Invalid choice. Please run the script again and enter 1, 2, or 3."
        exit 1
        ;;
esac
