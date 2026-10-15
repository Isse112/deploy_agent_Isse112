# deploy_agent_Isse112

Shell script for automated bootstrapping, running, and log archiving of a Student Attendance Tracker Python application, with safe Ctrl+C / Ctrl+Z handling during deployment.

## Overview

deploy_agent.sh has three features, chosen via an interactive menu:
1. Deploy a new project
2. Run an already deployed project
3. Archive the log files

## Requirements

- python3
- zip

The script checks for both at startup and exits with a clear error if either is missing.

## How to Run

./deploy_agent.sh

You'll see a menu:

What would you like to do?
  1) Deploy a new project
  2) Run an already deployed project
  3) Archive the log files
Enter your choice (1-3):

### Feature 1: Deploy a new project

- Enter a name; it creates attendance_tracker_<name>/.
- If a directory with that name already exists, you're asked whether to overwrite it or abort.
- attendance_checker.py and Helpers/config.json are copied unmodified from templates/.
- You choose how to build the roster (Helpers/assets.csv):
  - A) Copy from template - pick how many students (1-10) to copy from templates/assets.csv. These rows carry 4 prior sessions each, so total_sessions stays at the shipped value of 5.
  - B) Generate a fresh roster - pick how many students; rows are built from built-in sample names/emails with Attendance/Absence counts starting at 0. Since this is session one, total_sessions is set to 1.
- Permissions: attendance_checker.py is made executable (chmod +x), and Helpers/config.json is restricted to owner read/write only (chmod 600), since it holds grading-sensitive thresholds.
- You're then asked whether to update the attendance alert thresholds (warning, default 75; failure, default 50). If yes, sed edits the "warning" and "failure" lines of Helpers/config.json in place, without reformatting or reordering the rest of the file. Permissions are re-applied afterward to keep the file at 600.
- Finally, the deploy feature finishes by running the app (Feature 2) to verify the deployment - a successful start confirms the structure, roster, and config all work together.

### Feature 2: Run an already deployed project

- Enter the project name; the script cd's into attendance_tracker_<name>/ and runs python3 attendance_checker.py.

### Feature 3: Archive the log files

- Enter the project name.
- Checks whether reports/attendance.log and reports/absent.log exist.
- Each existing log is copied into its own archive directory with a timestamped filename:
  attendance_tracker_<name>/archives/attendance/attendance_YYYYMMDD_HHMMSS.log
  attendance_tracker_<name>/archives/absent/absent_YYYYMMDD_HHMMSS.log
- The original logs in reports/ are left untouched - only copies are archived.
- If a log doesn't exist (e.g. nobody was absent, so no absent.log was created), the script reports this and continues without crashing.
- Prints the final path of each archived log.

## Ctrl+C / Ctrl+Z Handling During Deployment

While Feature 1 is creating and setting up a project (from the moment the project directory is created, up until the verification run starts), the script traps both SIGINT (Ctrl+C) and SIGTSTP (Ctrl+Z).

If either signal is received during that window:
- The script prints a message explaining the deployment was interrupted.
- It zips whatever exists of attendance_tracker_<name>/ so far into attendance_tracker_<name>_archive.zip (using zip, so the file has a real .zip extension).
- The script then exits cleanly, instead of crashing or leaving a half-made directory behind.

This trap only covers the shell script's own setup steps. Once deployment reaches the verification run (the actual Python app), the trap is removed (trap - SIGINT SIGTSTP), so attendance_checker.py handles its own Ctrl+C during a live marking session instead.

### How I tested it

Ran: ./deploy_agent.sh, choice 1, project name demoC, then pressed Ctrl+C at the roster A/B prompt.

Result: the script printed the interrupted message, created attendance_tracker_demoC_archive.zip containing whatever had been created so far (attendance_checker.py, Helpers/config.json, empty reports/), and exited back to a normal shell prompt.

Repeated the same test pressing Ctrl+Z instead of Ctrl+C at the same prompt, with the same result, and confirmed with jobs that the script had exited rather than being suspended in the background.

## How I Tested the Deployed Application Structure

- Ran Feature 1 with roster Option A (copying 5 students) and confirmed via ls -la and cat that:
  - attendance_checker.py was present and executable (-rwxr-xr-x)
  - Helpers/config.json was present and restricted to -rw------- (600)
  - Helpers/assets.csv contained the header plus exactly the requested number of rows, unmodified from the template
  - total_sessions remained 5, consistent with the template's 4 prior sessions
- Ran Feature 1 again with roster Option B (generating 6 fresh students) and a threshold update (warning=80, failure=55), and confirmed:
  - Helpers/assets.csv contained 6 freshly generated rows with counts at 0
  - total_sessions was set to 1
  - Helpers/config.json showed the updated thresholds
  - Permissions on config.json were still 600 after the sed edits
- In both cases, the deploy feature's final verification step successfully started attendance_checker.py ("Today's session: N students, total_sessions=X"), confirming the structure, roster, and config all work together.
- Tested Feature 2 independently by running an already-deployed project.
- Tested Feature 3 by manually creating sample reports/attendance.log and reports/absent.log files, running the archive feature, and confirming both logs were copied into their own timestamped archive directories. Also tested the case where absent.log was missing, confirming the script reported it gracefully instead of crashing.

## templates/

Contains the three unmodified source files used to populate every new deployment:
- attendance_checker.py
- config.json
- assets.csv


## Walkthrough Video

Watch the walkthrough and demo here: https://youtu.be/T044tU1o_iQ
