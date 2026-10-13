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
