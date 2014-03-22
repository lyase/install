#!/bin/bash
#
# LAST_UPDATE="12 Feb 2014 16:33"
# Orignal Date: 14 Jan 2012
#
# wget https://github.com/WittyWizard/install/archive/master.zip; unzip master.zip; cd install-master; mv -v * ..; cd ..; rm -rf install-master; rm -f master.zip;
# wget https://github.com/WittyWizard/install/archive/master.zip; unzip master.zip; rm -f master.zip;
# ./WittyWizard-install.sh -a USERNAME     RootFolder AppName      
# ./WittyWizard-install.sh -a wittywizard  public     WittyWizard
# ./WittyWizard-install.sh -l
# ./WittyWizard-install.sh -t
# ./WittyWizard-install.sh -h
#
# FIX
# Test for sshpass
#
declare CleanUp=0;   # Clear Console Histroy
declare CLEAN_ENV=1; # Set to 0 to skip Clean Environment. 
if [[ "$CLEAN_ENV" -eq 1 ]]; then 
    set +H; # turn off history expansion echo "Hi!" or set +o histexpand or histchars=
    source "/etc/profile" > /dev/null; # Run Environment script
    #set -eu # -e # errexit: Exit immediately if a simple command exits with a non-zero status... Causes menu to Fail
    set -u; # nounset: Treat unset variables as an error when performing parameter expansion. An error message will be written to the standard error, and a non-interactive shell will exit.
    # nocaseglob: If set, Bash matches filenames in a case-insensitive fashion when performing filename expansion.
    # dotglob: If set, Bash includes filenames beginning with a `.' in the results of filename expansion.
    # -s   Enable (set) each optname
    shopt -s nullglob dotglob;
    IFS=$' '; # IFS=$'\n\t';
    umask 022; # User's file creation mask. umask sets an environment variable which automatically sets file permissions on newly created files. i.e. it will set the shell process's file creation mask to mode.
    unalias -a; # -a   Remove All aliases
    unset -f $(declare -F | sed "s/^declare -f //"); # -f The names refer to shell Functions, and the function definition is removed. Readonly variables and functions may not be unset
else
    #set -o nounset;
    echo "";
fi
#
declare Run_Mode="";                # -l=Localize,-h=Help,-t=test,-a=automan
# Over-ride defaults
declare DEFAULT_HA_USERNAME='admin';
declare DEFAULT_HA_PASSWORD='opensaidme';
#
declare -a MySaveVars=('Server_Names' 'App_Names' 'App_Domains' 'App_IPs' 'App_Ports' 'App_Paths' 'App_Folder' 'User_Names' 'Passwords' 'Root_Passwords' 'Db_Type' 'DB_Names' 'DB_Root_PW' 'DB_User_Names' 'DB_Passwords' 'DB_Full_Paths' 'Server_OS' 'Static_Path' 'Install_Apache' 'Install_Wt' 'Install_WittyWizard' 'Install_PostgreSQL' 'Install_SQlite' 'Install_HaProxy' 'Install_Monit' 'Install_FTP' 'Install_PDF' 'Install_Moses' 'Install_Arch' 'Install_Type' 'Create_User' 'Create_Key' 'Rsync_Delete_Push' 'IncludePush' 'Rsync_Delete_Pull' 'IncludePull' 'Repo_Install' 'Is_Keyed' 'Server_Threads' 'Is_WWW' 'Global_Maxconn' 'Default_Maxconn' 'Install_Script_Type' 'FTP_Server' 'HA_User_Names' 'HA_Passwords' 'PackedVars');
declare -a MyDefaultSaveVars=( 'MyPassword' 'Master_UN' 'Farm_Name' 'EDITOR' 'SSH_Keygen_Type' 'Test_SSH_User' 'Test_SSH_PASSWD' 'Test_SSH_Root_PASSWD' 'Test_SSH_URL' 'Test_SSH_IP' 'Test_App_Path' 'Test_App_Folder' 'Base_Storage_Path' );
declare -a FTP_Servers=('None' 'ProFTP' 'VsFTP' 'Pure-FTP');  #
declare -a Db_Types=('None' 'SQlite' 'PostgreSql' 'MySql');   #
declare -a Install_Types=();                                  # Defined below: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
# Globals per Master
declare Farm_Name="";               # Name of Farm: farm.db will be appended to it i.e. Farm_Name-farm.db
declare Master_UN="$(whoami)";      # Master User Name, this is need in case its not the logged on user, i.e. root or sudo
# 
declare Test_SSH_User="";           # Test SSH User
declare Test_SSH_URL="";            # Test SSH URL
declare Test_SSH_IP="";             # Test SSH IP
declare Test_SSH_PASSWD="";         # Test SSH Password
declare Test_SSH_Root_PASSWD="";    # Test SSH Root Password
declare Test_App_Path="";           # Test SSH Path
declare Test_App_Folder="";         # Test SSH Folder
declare MyPassword='MyPassword';    # Password to Key all Passwords
declare MyDefaultPassword='';       # Default Password used to decrypt config file
declare -i SecurityLevel=1;         # 0=No Security, 1=Top... 
declare Base_Storage_Path='';       # Base Storage Path for all Web Apps
#declare SSH_Keygen_Type='';        # 
#
declare -a Server_Names=();         #  0. Server Name: Default hostname
declare -a App_Names=();            #  1. Application Names
declare -a App_Domains=();          #  2. Web Domain Name: url.tdl
declare -a App_IPs=();              #  3. Web IP Address: 0.0.0.0
declare -a App_Ports=();            #  4. Application Starting Port
declare -a App_Paths=();            #  5. Application Path: /home/UserName ~/ or Root
declare -a App_Folder=();           #  6. Application Root: /home/UserName/public
declare -a User_Names=();           #  7. User Name
declare -a Passwords=();            #  8. Password
declare -a Root_Passwords=();       #  9. Root Password
declare -a Db_Type=();              # 10. Database Types: 0=None,1=SQlite,2=PostgreSql,3=MySql
declare -a DB_Names=();             # 11. Database Name
declare -a DB_Root_PW=();           # 12. Database Password
declare -a DB_User_Names=();        # 13. Database User Name
declare -a DB_Passwords=();         # 14. Database Password
declare -a DB_Full_Paths=();        # 15. Database Full Path
declare -a Server_OS=();            # 16. Server OS, used to set the OS for Server Install
declare -a Static_Path=();          # 17. Static Path: resources, static, media - media.domain.com; where static content is located
declare -a Install_Apache=();       # 18. If no, then Remove Apache
declare -a Install_Wt=();           # 19. If no, then do nothing
declare -a Install_WittyWizard=();  # 20. 1=True, else install Custom Application
declare -a Install_PostgreSQL=();   # 21. Install PostgreSQL
declare -a Install_SQlite=();       # 22. Install SQlite
declare -a Install_HaProxy=();      # 23. Install HaProxy
declare -a Install_Monit=();        # 24. Install Monit
declare -a Install_FTP=();          # 25. Install FTP
declare -a Install_PDF=();          # 26. 1=True install haru
declare -a Install_Moses=();        # 27. Install Moses: This is only for the Master Server
declare -a Install_Arch=();         # 28. 1=x64 | 0=x32
declare -a Install_Type=();         # 29. Install Type: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
declare -a Create_User=();          # 30. Create User
declare -a Create_Key=();           # 31. Create ssh Key
declare -a Rsync_Delete_Push=();    # 32. rsynce --delete 
declare -a IncludePush=();          # 33. Include in Auto Push
declare -a Rsync_Delete_Pull=();    # 34. rsynce --delete 
declare -a IncludePull=();          # 35. Include in Auto Pull
declare -a Repo_Install=();         # 36. Repository Install = 1, Compile = 0
declare -a Is_Keyed=();             # 37. Is SSH Key installed
declare -a Server_Threads=();       # 38. Number of HTTP Servers or Threads you run on each IP
declare -a Is_WWW=();               # 39. If www.domain.com
declare -a Global_Maxconn=();       # 40. Global maxconn
declare -a Default_Maxconn=();      # 41. Global maxconn
declare -a Install_Script_Types=(); # 42. 0=Not-Installed, 1=Full-Install, 2=haproxy
declare -a FTP_Server=();           # 43. FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
declare -a HA_User_Names=();        # 44. haproxy stats access User Name
declare -a HA_Passwords=();         # 45. haproxy stats access Password
declare -a PackedVars=();           # 46. Packed Vars: IncludePush=1:IncludePull=0
#
declare -i Current_Domain_Index=0;  # Current_Domain_Index  to above Array's
#
declare -i IS_LAST_CONFIG_LOADED=0; # Check to see if Last Config was loaded.
#
# This is the full path to the Script, not where the script was called from.
declare FULL_SCRIPT_PATH="$(dirname $(readlink -f "$0"))";
declare CONFIG_PATH="${FULL_SCRIPT_PATH}/CONFIG";             # Config Path

# -------------------------------------
set_defaults()
{
    # -------------------------------------
    random_password() 
    {
        date +%s | sha256sum | base64 | head -c "$1" ; echo; # no Special Characters 
    }
    # -------------------------------------
    if [ ! -f "${CONFIG_PATH}/default-config.db" ]; then
        # echo "********** Create New Config ******************"; read -e -sn 1 -p "set_defaults @ $(basename $BASH_SOURCE) : $LINENO";
        Farm_Name='WittyWizard';
        MyDefaultPassword="$(random_password 16 0)";
        touch "${CONFIG_PATH}/default-config.db";
    fi
    echo "#"                                          > "${CONFIG_PATH}/default-config.db"; 
    echo "Farm_Name=\"$Farm_Name\";"                 >> "${CONFIG_PATH}/default-config.db"; 
    echo "MyDefaultPassword=\"$MyDefaultPassword\";" >> "${CONFIG_PATH}/default-config.db"; # Saved in plain text
}
# -------------------------------------
load_last_config()
{
    local Last_IFS="$IFS"; IFS=$' ';
    # 
    if [ -f "${CONFIG_PATH}/default-config.db" ]; then
        source "${CONFIG_PATH}/default-config.db";
    else
        set_defaults;
    fi
    IFS="$Last_IFS";
}
# -------------------------------------
load_last_config;
# Wizard API Script for core Interface
if [ -f "${FULL_SCRIPT_PATH}/wizard.sh" ]; then
    declare SCRIPT_NAME='WittyWizard-install.sh'
    declare -r LOCALIZED_PATH="${FULL_SCRIPT_PATH}/locale"; # Where the po.langage file goes -> Edit this line as needed for project
    declare LOCALIZED_FILE="witty-wizard.sh";               # Name to call the Langage File referanced above -> Edit this line as needed for project
    declare -i LOCALIZED_FILES_SAFE=0;                      # Set to 1 the first time you start Hand Translating your Localization files so they do not get overwriten.
    declare DEFAULT_LOCALIZED_LANG='en';                    # Change this to the Default Language that the Localized files are in
    #
    export TEXTDOMAINDIR="$LOCALIZED_PATH";                 # Multilingual Langage File Path -> from above: declare -r LOCALIZED_PATH="${FULL_SCRIPT_PATH}/locale"
    export TEXTDOMAIN="$LOCALIZED_FILE";                    # Multilingual Langage File Name -> from above: declare LOCALIZED_FILE="wizard.sh"
    declare -i RUN_LOCALIZER=0;                             # Localization of all script tags to support language
    declare -i RUN_HELP=0;                                  # Create Help.html
    declare -i RUN_TEST=0;                                  # 0=Disable, 1=Run, 2=Run Extended Test
    declare -i AUTOMAN=0;                                   # Automatically install from saved settings
    declare -i DETECTED_RUN_MODE=2;                         # Detected Run Mode
    declare -i RUNTIME_MODE=2;                              # 1 = Boot Mode, 2 = Live
    declare -i DRIVE_FORMATED=1;                            # Is Target Drive Formated yet
    declare MOUNTPOINT="";                                  # Mount-point is used when Mounting Systems, like in chroot; or its just a mounted folder.
    declare DATE_TIME="$(date +"%d-%b-%Y @ %r")";           # 21-Jan-2013 @ 01:25:29 PM
    declare LOG_DATE_TIME="$(date +"%d-%b-%Y-T-%H-%M")";    # Day-Mon-YYYY-T-HH-MM: 21-Jan-2013-T-13-24
    declare -i DEBUGGING=0;                                 # Debugging gives pauses and other help
    #
    if [[ "$#" -gt 0 ]]; then
        if [[ "$1" == "-l" ]]; then
            RUN_LOCALIZER=1; # Localize all Scripts
        fi
        if [[ "$1" == "-h" ]]; then
            RUN_HELP=1; # Build Help File: help.html
        fi
        if [[ "$1" == "-d" ]]; then
            DEBUGGING=1; # DEBUGGING set for all Scripts
        fi
        if [[ "$1" == "-t" ]]; then
            RUN_TEST=1; # Normal Testing
            DEBUGGING=1;
        fi
        if [[ "$1" == "-s" ]]; then
            RUN_TEST=2; # Extended Testing
            DEBUGGING=1;
        fi
        if [[ "$1" == "-i" ]]; then
            RUN_TEST=10; # Run All Tests
            DEBUGGING=1;
        fi
        if [[ "$1" == "-x" ]]; then
            RUN_TEST=3; # Extended Testing and Interface checks
            DEBUGGING=1;
        fi
        if [[ "$1" == "-a" ]]; then
            AUTOMAN=1; # Auto/Man: Automatically Install with passed in Arguments: @FIX Arguments: -a Farm_Name (what functions: rsync-pull).
        fi
    fi
    # change to project needs
    declare CONFIG_NAME="wittywizard";                                    # Config File Name
    declare LOG_PATH="${FULL_SCRIPT_PATH}/LOG";                           # Log Path
    declare USER_FOLDER="${FULL_SCRIPT_PATH}/USER";                       # User Folder is for user Settings
    declare ERROR_LOG="${LOG_PATH}/0-${CONFIG_NAME}-error.log";           # Error Log Path
    declare ACTIVITY_LOG="${LOG_PATH}/1-${CONFIG_NAME}-activity.log";     # Activity Log Path
    declare SCRIPT_LOG="${LOG_PATH}/2-${CONFIG_NAME}-script.log";         # Script Log path
    # ***********************************
    # load WittyWizard-packages.sh
    if [ -f "${FULL_SCRIPT_PATH}/WittyWizard-packages.sh" ]; then
        echo '';
        print_caution "TEST-FUNCTION-LOADED-FILE" "WittyWizard-packages.sh ...";
        source "${FULL_SCRIPT_PATH}/WittyWizard-packages.sh";
    else
        print_error "TEST-FUNCTION-FNF" "ERROR FILE NOT FOUND: - ${FULL_SCRIPT_PATH}/WittyWizard-packages.sh";
        exit 1;
    fi
    #
    # if [[ "$DEBUGGING" -eq 1 ]]; then read -e -sn 1 -p "load_default_config @ $(basename $BASH_SOURCE) : $LINENO"; fi
    #. "${FULL_SCRIPT_PATH}/wizard.sh";
    echo '';
    echo " Loading wizard.sh ";
    source "${FULL_SCRIPT_PATH}/wizard.sh";
    #
    os_info; # Get OS Info
else
    echo "$(gettext -s "TEST-FUNCTION-FNF") ERROR FILE NOT FOUND: - ${FULL_SCRIPT_PATH}/wizard.sh";
    exit 1;
fi
# You do not have a lot of tools to use until you load the wizard.sh file
if [[ "$#" -gt 0 && "$#" -ne 1 ]]; then 
    if [[ "$1" == "--help" ]]; then
        echo "Usage: ";
        exit 0;
    fi
elif [[ "$#" -eq 1 ]]; then 
    # 
    Run_Mode="$1";  # -l=Localize,-h=Help,-a=automan.
fi
# Archlinux AUR Helper
AUR_HELPER="yaourt";
# *****************************************************************************
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="install_app";
    USAGE="$(localize "INSTALL-APP-USAGE")";
    DESCRIPTION="$(localize "INSTALL-APP-DESC")";
    NOTES="$(localize "INSTALL-APP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="10 Apr 2013";
    REVISION="10 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALL-APP-USAGE"     "install_app 1->(File Name to write to) 2->(Current Domain index)"         "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-APP-DESC"      "install_app"         "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-APP-NOTES"     "Install Witty Wizard Application: This can be customized to install your App here." "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "INSTALL-WITTY-WIZARD"  "Install Witty Wizard" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-APP-LINE-PASS" "Installed Witty Wizard" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-APP-LINE-FAIL" "Failed to install Witty Wizard" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
install_app()
{
    if [[ "${Install_WittyWizard[$2]}" -eq 1 ]]; then
        #
        # Install Witty Wizard
        # @NOTE @FIX Make sure a test at the end is ran since it only returns the last command ~ ; if [ -d "${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt" ]; then exit 0; else exit 1; fi
        #
        # echo "echo \" $(gettext -s "INSTALL-WITTY-WIZARD") \"; [[ ! -d \"${App_Paths[$2]}/${App_Folder[$2]}/\" ]] && mkdir -p \"${App_Paths[$2]}/${App_Folder[$2]}/\"; [[ ! -d \"${App_Paths[$2]}/${App_Folder[$2]}/archive/\" ]] && mkdir -p \"${App_Paths[$2]}/${App_Folder[$2]}/archive/\"; cp -Rf \"${App_Paths[$2]}/${App_Folder[$2]}/\" \"${App_Paths[$2]}/archive/\"; cd \"${App_Paths[$2]}/${App_Folder[$2]}/\"; g++ -o WittyWizard.wt main.cpp -L/usr/lib -lwt -lwthttp -lwtdbo -lwtdbosqlite3 -lcrypt -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time; chown -R ${User_Names[$2]}:${User_Names[$2]} \"${App_Paths[$2]}/\"; if [ -d \"${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt\" ]; then exit 0; else exit 1; fi";
        # echo " Install Witty Wizard "; [[ ! -d "/home/wittywizard/public/" ]] && mkdir -p "/home/wittywizard/public/"; [[ ! -d "/home/wittywizard/archive/" ]] && mkdir -p "/home/wittywizard/archive/"; cp -Rf "/home/wittywizard/public/" "/home/wittywizard/archive/"; cd "/home/wittywizard/public/"; g++ -o WittyWizard.wt main.cpp -L/usr/lib -lwt -lwthttp -lwtdbo -lwtdbosqlite3 -lcrypt -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time; chown -R wittywizard:wittywizard "/home/wittywizard/"; if [ -f "/home/wittywizard/public/WittyWizard.wt" ]; then exit 0; else exit 1; fi
        #load_packages "${Server_OS[$2]}" "${Install_Arch[$2]}";    # Architect 32/64 for this item
        #ssh -t -t "root@${App_IPs["$CIndex"]}" "echo \" $(gettext -s "INSTALL-WITTY-WIZARD") \"; [[ ! -d \"${App_Paths[$2]}/${App_Folder[$2]}/\" ]] && mkdir -p \"${App_Paths[$2]}/${App_Folder[$2]}/\"; [[ ! -d \"${App_Paths[$2]}/${App_Folder[$2]}/archive/\" ]] && mkdir -p \"${App_Paths[$2]}/${App_Folder[$2]}/archive/\"; cp -Rf \"${App_Paths[$2]}/${App_Folder[$2]}/\" \"${App_Paths[$2]}/archive/\"; cd \"${App_Paths[$2]}/${App_Folder[$2]}/\"; $(package_type 0 "$APPS_REQUIRED_Install" "${Server_OS[$2]}"); g++ -o WittyWizard.wt main.cpp -L/usr/lib -lwt -lwthttp -lwtdbo -lwtdbosqlite3 -lcrypt -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time; chown -R ${User_Names[$2]}:${User_Names[$2]} \"${App_Paths[$2]}/\"; if [ -f \"${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt\" ]; then exit 0; else exit 1; fi";
        #if [[ "$?" -eq 0 ]]; then
        #    print_this "INSTALL-APP-LINE-PASS" "${Server_Names[$2]}";
        #else
        #    print_this "INSTALL-APP-LINE-FAIL" "${Server_Names[$2]}";
        #fi
        echo "echo \"$(gettext -s "INSTALL-WITTY-WIZARD")\""                                                                            >> "$1"
        echo "[[ ! -d \"${App_Paths[$2]}/${App_Folder[$2]}/\" ]] && mkdir -p \"${App_Paths[$2]}/${App_Folder[$2]}/\";"                  >> "$1"
        echo "[[ ! -d \"${App_Paths[$2]}/archive/\" ]] && mkdir -p \"${App_Paths[$2]}/archive/\";"                                      >> "$1"
        echo "[[ ! -d \"${App_Paths[$2]}/run/\" ]] && mkdir -p \"${App_Paths[$2]}/run/\";"                                              >> "$1"
        echo "cp -Rf \"${App_Paths[$2]}/${App_Folder[$2]}/\" \"${App_Paths[$2]}/archive/\";"                                            >> "$1"
        echo "cd \"${App_Paths[$2]}/${App_Folder[$2]}/\";"                                                                              >> "$1"
        # @FIX -lcrypt vs -lcrypto and -L/usr/lib
        echo "g++ -o WittyWizard.wt main.cpp -lwt -lwthttp -lwtdbo -lwtdbosqlite3 -lcrypto -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time;"  >> "$1"
        #echo "g++ -o WittyWizard.wt main.cpp -L/usr/lib -lwt -lwthttp -lwtdbo -lwtdbosqlite3 -lcrypt -lpng -lboost_signals -lboost_filesystem -lboost_system -lboost_regex -lboost_date_time;"  >> "$1"
        echo "chown -R \"\$USERNAME:\$USERNAME\" \"${App_Paths[$2]}/\";"                                                                    >> "$1"
        echo "if [ -f \"${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt\" ]; then echo 'passed'; else echo 'failed'; fi"         >> "$1"
    else # install ${App_Names["$CIndex"]}
        # Now just create the file custom-witty-wizard-install.sh and put a function named custom_witty_wizard_install in it and you never have to touch this code
        # make sure this only echos
        if [ -f "${FULL_SCRIPT_PATH}/custom-witty-wizard-install.sh" ]; then
            source "${FULL_SCRIPT_PATH}/custom-witty-wizard-install.sh";
        else
            exit 1;
        fi        
        custom_witty_wizard_install >> "$1";
    fi
}
# *****************************************************************************
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install";
    USAGE="do_install";
    DESCRIPTION="$(localize "DO-INSTALL-DESC")";
    NOTES="$(localize "DO-INSTALL-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="10 Apr 2013";
    REVISION="10 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-DESC"          "Create Installation scripts." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-NOTES"         "Install Witty Wizard."                                 "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-LINE-1"        "Wt Witty Wizard for Repository Installation" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-2"        "This script will create a user and ask for password using useradd and passwd command" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-3"        "Now make folders we need and set permissions" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-4"        "Now to install software" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DEV-TOOLS"     "Extra Development Tools, this loads a lot of stuff that Developers might need" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-6"        "These are Requirements" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HARU"          "Haru Library for PDF Support." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HARU-REMI"     "Haru Library from remi Repository for PDF Support." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-EPEL"          "EPEL Repository for monit, haproxy and wt (not sure which ones, plus this may change in the future): http://fedoraproject.org/wiki/EPEL/FAQ" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-9"        "Now we do an upgrade" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-10"       "Wt and Dependencies" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY"       "Install haproxy: This will give us Load Balancing and allow us to create a Farm, we only use two threads by default, so make sure you have RAM for two." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MONIT"         "Install Monit" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MOSES"         "Install Moses" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-13"       "Configure haproxy.cfg" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-14"       "Lets you edit this file, ctrl-o to save and ctrl-x to exit, for none nano users" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-START-HAPROXY" "Start haproxy and set it to come on after reboot" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-16"       "Make backup of monit.conf and create a new monit.conf" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-17"       "Starting monit..." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-18"       "FTP Configuration." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-LINE-19"       "Install Database" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-INSTALL"       "Install Scripts" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-INSTALL-PW"    "Enter Script Password" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-INSTALL-BY"    "Created by Witty Wizard" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";

    localize_info "DO-INSTALL-SRA"           "String replaced Applied" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SRP"           "String replaced Passed" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SRF"           "String replaced Failed" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";

    localize_info "DO-INSTALL-FF"            "Found File"     "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-FNF"           "File Not Found" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-DISTRO-REDHAT"      "Redhat"    "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-CENTOS"      "Centos"    "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-FEDORA"      "Fedora"    "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-ARCHLINUX"   "Archlinux" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-DEBIAN"      "Debian"    "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-UBUNTU"      "Ubuntu"    "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-LMDE"        "Linux Mint Debian Edition (LMDE)" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-DISTRO-UNSUPPORTED" "Unsupported" "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-SOFTWARE-FAIL-1"    "Failed to Execute"         "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO"
    localize_info "DO-INSTALL-SOFTWARE-PASSED"    "Executed Successfully"     "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO"
    localize_info "DO-INSTALL-PACKAGEMANAGER"     "Install PACKAGEMANAGER..." "Comment: do_install @ $(basename $BASH_SOURCE) : $LINENO"
fi
# -------------------------------------
do_install()
{
    print_title "DO-INSTALL-LINE-1";
    # First lets load the Farm
    load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
    #
    local -i total="${#App_Domains[@]}"; # total array count
    local -i CIndex=0;                   # for loop
    local -i App_Port=0;                 # App_Port number to increment
    local My_Install_Script_Name='';     # File name for script
    local This_OS='linux';               # linux
    local This_Distro='';                # redhat,archlinux,debian
    local This_PSUEDONAME='';            # centos,fedora,Ubuntu,LMDE
    local This_Distro_Version='';        # squeeze,wheezy,lenny,raring,quantal,precise
    local This_Version='';               # 5,6
    local My_Secret_Name='';
    #
    make_dir "${CONFIG_PATH}/Scripts" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    #
    for (( CIndex=0; CIndex<total; CIndex++ )); do
        unpack_bools "${PackedVars[$CIndex]}";
        # Set Script Name
        make_dir "${CONFIG_PATH}/Scripts/${Farm_Name}/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        My_Install_Script_Name="${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-install.sh"; # Script per Domain
        touch "$My_Install_Script_Name";
        chmod 755 "$My_Install_Script_Name";
        # Set Port for incrementing 
        App_Port="${App_Ports["$CIndex"]}";
        # linux:redhat:redhat-centos-fedora
        This_OS="$(string_split "${Server_OS[$CIndex]}" ":" 1)";             # linux
        This_Distro="$(string_split "${Server_OS[$CIndex]}" ":" 2)";         # redhat,archlinux,debian
        This_PSUEDONAME="$(string_split "${Server_OS[$CIndex]}" ":" 3)";     # centos,fedora,Ubuntu,LMDE
        This_Distro_Version="$(string_split "${Server_OS[$CIndex]}" ":" 4)"; # squeeze,wheezy,lenny,raring,quantal,precise
        This_Version="$(string_split "${Server_OS[$CIndex]}" ":" 5)";        # 5,6
        load_packages "${Server_OS[$CIndex]}" "${Install_Arch[$CIndex]}" "$CIndex"; # Server | Architect 32/64 for this item | Index
        # Now lets start making our Script 
        echo "# $(gettext -s "DO-INSTALL-INSTALL-BY") $DATE_TIME" > "${My_Install_Script_Name}";
        echo "# Server:${Server_Names["$CIndex"]} | Name:${App_Names["$CIndex"]} | IP:${App_IPs["$CIndex"]}"  > "${My_Install_Script_Name}";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "# Debugging: CIndex=$CIndex | This_OS = $This_OS | This_Distro=$This_Distro | Server_Names=${Server_Names["$CIndex"]} | App_Names=${App_Names["$CIndex"]} | ..." >> "${My_Install_Script_Name}";
        fi
        #
        echo "# 1->(MyPassword)"                                                                  >> "${My_Install_Script_Name}";
        echo "if [[ \"\$#\" -eq 1 ]]; then MyPassword=\"\$1\"; else MyPassword='?'; fi"           >> "${My_Install_Script_Name}";
        echo "if [[ \"\$MyPassword\" == '?' ]]; then"                                             >> "${My_Install_Script_Name}";
        echo "    echo -e \"$(gettext -s "DO-INSTALL-INSTALL-PW")\";"                             >> "${My_Install_Script_Name}";
        echo "    read -r -e OPTION;"                                                             >> "${My_Install_Script_Name}";
        echo "    MyPassword=\"\$OPTION\";"                                                       >> "${My_Install_Script_Name}";
        echo "fi"                                                                                 >> "${My_Install_Script_Name}";
        # 
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        echo "is_user()"                                                                      >> "${My_Install_Script_Name}";
        echo "{"                                                                              >> "${My_Install_Script_Name}";
        echo "  egrep -i \"^\$1\" /etc/passwd > /dev/null 2>&1;"                              >> "${My_Install_Script_Name}";
        echo "  return \"\$?\";"                                                              >> "${My_Install_Script_Name}";
        echo "}"                                                                              >> "${My_Install_Script_Name}";
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        echo "is_group()"                                                                     >> "${My_Install_Script_Name}";
        echo "{"                                                                              >> "${My_Install_Script_Name}";
        echo "  egrep -i \"^\$1\" /etc/group > /dev/null 2>&1;"                               >> "${My_Install_Script_Name}";
        echo "  return \"\$?\";"                                                              >> "${My_Install_Script_Name}";
        echo "}"                                                                              >> "${My_Install_Script_Name}";
        #
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        echo "password_safe()"                                                                >> "${My_Install_Script_Name}";
        echo "{"                                                                              >> "${My_Install_Script_Name}";
        echo "  if [[ \"\$3\" == 'encrypt' ]]; then"                                          >> "${My_Install_Script_Name}";
        echo "    echo -e \"\$1\" | openssl enc -aes-128-cbc -a -salt -pass pass:\"\$2\";"    >> "${My_Install_Script_Name}";
        echo "  else"                                                                         >> "${My_Install_Script_Name}";
        echo "    echo -e \"\$1\" | openssl enc -aes-128-cbc -a -d -salt -pass pass:\"\$2\";" >> "${My_Install_Script_Name}";
        echo "  fi"                                                                           >> "${My_Install_Script_Name}";
        echo "}"                                                                              >> "${My_Install_Script_Name}";
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        echo "# un_comment_file 1->(Text) 2->(FilePath)"                                      >> "${My_Install_Script_Name}";  # @FIX Language
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        echo "un_comment_file()"                                                              >> "${My_Install_Script_Name}";
        echo "{"                                                                              >> "${My_Install_Script_Name}";
        echo "    local -i MyReturn=1;"                                                       >> "${My_Install_Script_Name}";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "    echo \"un_comment_file \$1 \$2 ********************** \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}";
        fi
        echo "    if [[ -e \"\$2\" || -L \"\$2\" || -f \"\$2\" ]]; then"                      >> "${My_Install_Script_Name}"; # If file exist
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "        echo \" $(gettext -s "DO-INSTALL-FF") \$2 ******************************* \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}"; # @FIX Language
        fi
        echo "        if [ \$(egrep -ic \"#\$1\" \"\$2\") -gt 0 ]; then"                      >> "${My_Install_Script_Name}"; # if line to uncomment exist
        echo "            sed -i \"/#\${1}/ s/# *//\" \"\$2\";"                               >> "${My_Install_Script_Name}"; # uncomment it
        echo "            MyReturn=\"\$?\";"                                                  >> "${My_Install_Script_Name}"; 
        echo "            if [ \$(egrep -ic \"#\$1\" \"\$2\") -eq 0 ]; then"                  >> "${My_Install_Script_Name}"; # check to see if it was uncommented
        echo "                MyReturn=0;"                                                    >> "${My_Install_Script_Name}";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "                echo \"$(gettext -s "DO-INSTALL-SRP") \$1 *************** \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}"; # @FIX Language
        fi
        echo "            else"                                                               >> "${My_Install_Script_Name}";
        echo "                MyReturn=1;"                                                    >> "${My_Install_Script_Name}";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "                echo \"$(gettext -s "DO-INSTALL-SRF") \$1 *************** \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}"; # @FIX Language
        fi
        echo "            fi"                                                                 >> "${My_Install_Script_Name}";
        echo "        else"                                                                   >> "${My_Install_Script_Name}";
        echo "            MyReturn=0;"                                                        >> "${My_Install_Script_Name}";
        echo "            echo \"$(gettext -s "DO-INSTALL-SRA") \$1 ***** \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}"; # @FIX Language
        echo "        fi"                                                                     >> "${My_Install_Script_Name}";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            echo "    else"                                                                       >> "${My_Install_Script_Name}";
            echo "        echo \"$(gettext -s "DO-INSTALL-FNF") \$2 ************************************************** \$FUNCNAME @ \$(basename \$BASH_SOURCE) : \$LINENO\";" >> "${My_Install_Script_Name}"; # @FIX Language
        fi
        echo "    fi"                                                                         >> "${My_Install_Script_Name}";
        echo "    return \"\$MyReturn\";"                                                     >> "${My_Install_Script_Name}";
        echo "}"                                                                              >> "${My_Install_Script_Name}";
        echo "# -------------------------------------"                                        >> "${My_Install_Script_Name}";
        #
        if [[ "${Create_User["$CIndex"]}" -eq 1 && "$CIndex" -gt 0 ]]; then # Create User if not Master
            #
            My_Secret_Name=$(password_safe "${User_Names[${CIndex}]}" "$MyPassword" 'encrypt');
            echo "declare USERNAME=\$(password_safe \"${My_Secret_Name}\" \"\$MyPassword\" 'decrypt');" >> "${My_Install_Script_Name}";
            #
            echo "if ! is_user \"\$USERNAME\" ; then"                                             >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
            echo "    echo \" $(gettext -s "DO-INSTALL-LINE-2")\";"                               >> "${My_Install_Script_Name}";
            echo "    if ! is_group \"\$USERNAME\" ; then"                                        >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
            echo "        groupadd \"\$USERNAME\";"                                               >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
            echo "    fi"                                                                         >> "${My_Install_Script_Name}";
            #
            echo "    useradd -m -g \"\$USERNAME\" -G \"\${USERNAME}\",users -s /bin/bash \"\$USERNAME\";" >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
            # Note: Do not pass in pass words in clear text; this file may not be secure; but if you detect for blank MyPassword and prompt for it at run time once.
            #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            if [[ "$SecurityLevel" -eq 1 ]]; then
                local MySecret=$(password_safe "${Passwords[$CIndex]}" "$MyPassword" 'encrypt');
                # Password:  MySecret (Password and MyPassword)
                # MyPassword
                # USERNAME
                echo "    MySecret=\"$MySecret\";"                                                >> "${My_Install_Script_Name}"; # ${User_Names["$CIndex"]}
                echo "    echo -e \"\$(password_safe \"\${MySecret}\" \"\$MyPassword\" 'decrypt')\n\$(password_safe \"\${MySecret}\" \"\$MyPassword\" 'decrypt')\n\" | passwd \"\$USERNAME\";" >> "${My_Install_Script_Name}"; # ${User_Names["$CIndex"]}
            elif [[ "$SecurityLevel" -eq 0 ]]; then
                echo "    echo -e \"${Passwords[$CIndex]}\n${Passwords[$CIndex]}\n | passwd \"\$USERNAME\";" >> "${My_Install_Script_Name}"; # ${User_Names["$CIndex"]}
            else     # Prompt for password
                echo "    passwd \"\$USERNAME\";"                                                 >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
            fi
            echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"                       >> "${My_Install_Script_Name}";
            echo "    echo \" $(gettext -s "DO-INSTALL-LINE-3")\";"                               >> "${My_Install_Script_Name}";
            #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            if [[ "${Install_Wt["$CIndex"]}" -eq 1 ]]; then
                echo "    mkdir -p ${App_Paths["$CIndex"]}/;"                                     >> "${My_Install_Script_Name}";
                echo "    mkdir -p ${App_Paths["$CIndex"]}/${App_Folder["$CIndex"]};"             >> "${My_Install_Script_Name}";
                echo "    mkdir -p ${App_Paths["$CIndex"]}/run;"                                  >> "${My_Install_Script_Name}";
                echo "    chown -R \"\$USERNAME:\$USERNAME\" ${App_Paths["$CIndex"]};"            >> "${My_Install_Script_Name}"; # ${User_Names[$CIndex]}
                echo "    chmod -R 770 ${App_Paths["$CIndex"]}/;"                                 >> "${My_Install_Script_Name}";
                echo "    chmod -R 755 ${App_Paths["$CIndex"]}/${App_Folder["$CIndex"]}/;"        >> "${My_Install_Script_Name}";
            fi
            echo "fi"                                                                             >> "${My_Install_Script_Name}";
        fi
        #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        #
        echo "echo \" $(gettext -s "DO-INSTALL-LINE-4")\";"                                       >> "${My_Install_Script_Name}";
        echo "echo \" $(gettext -s "DO-INSTALL-DEV-TOOLS")\";"                                    >> "${My_Install_Script_Name}";
        # Test of OS and Distorbution comes from wizard.sh os_info
        if [[ "$This_OS" == "solaris" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"        >> "${My_Install_Script_Name}";
        elif [[ "$This_OS" == "aix" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"        >> "${My_Install_Script_Name}";
        elif [[ "$This_OS" == "freebsd" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"        >> "${My_Install_Script_Name}";
        elif [[ "$This_OS" == "windowsnt" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"        >> "${My_Install_Script_Name}";
            # http://www.cygwin.com/
            # http://cygwin.com/setup.exe
        elif [[ "$This_OS" == "mac" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"        >> "${My_Install_Script_Name}";
        elif [[ "$This_OS" == "linux" ]]; then
            # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use This_PSUEDONAME
            # See wizard.sh os_info to see if OS test exist or works
            if [[ "$This_Distro" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                #
                # Redhat *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
                #                    
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-REDHAT")\";"                        >> "${My_Install_Script_Name}";
                # Redhat, Centos, Fedora 
                # Install EPEL Repo
                echo "echo \" $(gettext -s "DO-INSTALL-EPEL")\";"                                 >> "${My_Install_Script_Name}";
                echo "${Repo_Extra};"                                                             >> "${My_Install_Script_Name}";
                echo "${Repo_Extra_Key};"                                                         >> "${My_Install_Script_Name}";
                # System Upgrade            
                echo "echo \" $(gettext -s "DO-INSTALL-LINE-9")\";"                               >> "${My_Install_Script_Name}";
                echo "$(package_type 9 "System-Upgrade" "${Server_OS[$CIndex]}" 0);"              >> "${My_Install_Script_Name}";
                echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"                   >> "${My_Install_Script_Name}";
                #
                if [[ "${Install_Wt["$CIndex"]}" -eq 1 ]]; then
                    # Install Dev Tools
                    echo "$(package_type 1 "$Group_Install" "${Server_OS[$CIndex]}" 0);"          >> "${My_Install_Script_Name}";
                    # Install Requirements
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-6")\";"                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$APPS_REQUIRED_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                    # Install Wt
                    if [[ "${Repo_Install["$CIndex"]}" -eq 0 ]]; then
                        echo "$(compile_install "${My_Install_Script_Name}")"                     >> "${My_Install_Script_Name}";
                    else    
                        echo "echo \" $(gettext -s "DO-INSTALL-LINE-10")\";"                      >> "${My_Install_Script_Name}";
                        echo "$(package_type 0 "$WT_REQUIRED_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                    fi # End Repo_Install
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # PDF HARU
                if [[ "${Install_PDF["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HARU-REMI")\";"                        >> "${My_Install_Script_Name}";
                    echo "${PDF_Lib};"                                                            >> "${My_Install_Script_Name}";
                    echo "${PDF_Lib_Key};"                                                        >> "${My_Install_Script_Name}";
                    # Refresh Repo
                    echo "$(package_type 10 " " "${Server_OS[$CIndex]}" 0);"                      >> "${My_Install_Script_Name}";
                    # Install HARU PDF Tools from remi
                    echo "yum --enablerepo=remi install $PDF_Install -y;"                         >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # PostgreSQL
                if [[ "${Install_PostgreSQL["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19") PostgreSQL\";"               >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$POSTGRESQL_Install" "${Server_OS[$CIndex]}" 0);"     >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # SQlite
                if [[ "${Install_SQlite["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19") SQLite \";"                  >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$SQLITE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # Db_Type: 0=None,1=SQlite,2=PostgreSql,3=MySql
                if [[ "${Db_Type["$CIndex"]}" -eq 3 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19") MySQL \";" >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$MYSQL_Install" "${Server_OS[$CIndex]}" 0);"          >> "${My_Install_Script_Name}";
                    echo "$(package_type 11 " " "${Server_OS[$CIndex]}" 0);"                      >> "${My_Install_Script_Name}"; 
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # Apache
                if [[ "${Install_Apache["$CIndex"]}" -eq 1 ]]; then
                    echo "${Run_This};"                                                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                else
                    # Stop apache 
                    echo "$(package_type 4 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    # uninstalled it
                    echo "$(package_type 2 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    # check to see who is listeners;
                    # echo "netstat -nat | grep 80 | grep LISTEN; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";" >> "${My_Install_Script_Name}";
                    # nothing;
                    # echo "netstat -an | grep 'LISTEN'; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";"       >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # HAPROXY
                if [[ "${Install_HaProxy["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HAPROXY") \";"                         >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$HAPROXY_Install" "${Server_OS[$CIndex]}" 0);"        >> "${My_Install_Script_Name}";
                    # Fix logging: tail -f /var/log/haproxy*.log
                    # echo “show info”   | socat unix-connect:/tmp/haproxy stdio
                    # echo “show stat”   | socat unix-connect:/tmp/haproxy stdio
                    # echo “show errors” | socat unix-connect:/tmp/haproxy stdio
                    # echo “show sess”   | socat unix-connect:/tmp/haproxy stdio
                    echo 'echo -e "\$ModLoad imudp\n\$UDPServerAddress 127.0.0.1\n\$UDPServerRun 514\nlocal1.* -/var/log/haproxy_1.log\n& ~" > /etc/rsyslog.d/49-haproxy.conf;' >> "${My_Install_Script_Name}";
                    echo 'service rsyslog restart;'                                               >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # Monit
                if [[ "${Install_Monit["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-MONIT") \";"                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$MONIT_Install" "${Server_OS[$CIndex]}" 0);"          >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                # Moses: only install on Master Server, i.e. CIndex > 0
                if [[ "${Install_Moses["$CIndex"]}" -eq 1 && "$CIndex" -eq 0 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-MOSES") \";"                           >> "${My_Install_Script_Name}";
                    if [ -n "$Moses_Install" ] ; then
                        echo "$(package_type 0 "$Moses_Install" "${Server_OS[$CIndex]}" 0);"      >> "${My_Install_Script_Name}";
                    else
                        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS} $(gettext -s "DO-INSTALL-MOSES") \";" >> "${My_Install_Script_Name}";
                        # Install Moses
                        # http://www.statmt.org/moses/?n=Moses.Baseline
                        # git clone git://github.com/moses-smt/mosesdecoder.git
                        # http://cl.naist.jp/~eric-n/ubuntu-nlp/
                        # wget http://cl.naist.jp/~eric-n/ubuntu-nlp/8ABD1965.gpg -O- | apt-key add -
                    fi
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # FTP
                if [[ "${Install_FTP[$CIndex]}" -eq 1 ]]; then
                    echo "echo \"$(gettext -s "DO-INSTALL-LINE-18")\";"                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$FTP_Install" "${Server_OS[$CIndex]}" 0);"            >> "${My_Install_Script_Name}";
                    # FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
                    if [[ "${FTP_Server[$CIndex]}" -eq 1 ]]; then 
                        # RPMForge
                        echo "$Repo_FTP"                                                          >> "${My_Install_Script_Name}";
                        echo "if [ \$(egrep -ic 'priority=1' \"$Repo_File\") -eq 0 ]; then sed -i '/\[base\]/a priority=1' \"$Repo_File\"; sed -i '/\[updates\]/a priority=1' \"$Repo_File\"; sed -i '/\[extras\]/a priority=1' \"$Repo_File\"; sed -i '/\[rpmforge\]/a priority=5' '/etc/yum.repos.d/rpmforge.repo'; sed -i '/\[epel\]/a priority=11' '/etc/yum.repos.d/epel.repo'; fi" >> "${My_Install_Script_Name}";
                        echo "$(package_type 9 "System-Upgrade" "${Server_OS[$CIndex]}" 0);"      >> "${My_Install_Script_Name}";
                        echo "yum --enablerepo=rpmforge install $FTP_Install -y;"                 >> "${My_Install_Script_Name}";
                    elif [[ "${FTP_Server[$CIndex]}" -eq 2 ]]; then 
                        # vsftpd
                        FTP_File='/etc/vsftpd/vsftpd.conf';
                        echo "if [ \$(egrep -ic 'anonymous_enable=YES' $FTP_File) -gt 0 ]; then sed -i 's/^'anonymous_enable='.*$/'anonymous_enable=NO'/' ${FTP_File}; un_comment_file 'ascii_upload_enable=YES' $FTP_File ; un_comment_file 'ascii_download_enable=YES' $FTP_File; echo 'use_localtime=YES' >> $FTP_File; fi" >> "${My_Install_Script_Name}";
                        # echo "exit 0" >> "${My_Install_Script_Name}";
                        # echo "if [ \$(egrep -ic 'anonymous_enable=YES' $FTP_File) -gt 0 ]; then sed -i 's/^'anonymous_enable='.*$/'anonymous_enable=NO'/' ${FTP_File}; sed -i 's/^#'#ascii_upload_enable=YES'/'#ascii_upload_enable=YES'/g' $FTP_File; sed -i 's/^#'#ascii_download_enable=YES'/'#ascii_download_enable=YES'/g' $FTP_File; echo 'use_localtime=YES' >> $FTP_File; fi" >> "${My_Install_Script_Name}";
                    elif [[ "${FTP_Server[$CIndex]}" -eq 3 ]]; then 
                        # /etc/pure-ftpd.conf
                        # # UnixAuthentication            yes
                        FTP_File='/etc/pure-ftpd.conf';
                        echo "if [ \$(egrep -ic '# UnixAuthentication            yes' $FTP_File) -gt 0 ]; then un_comment_file ' UnixAuthentication            yes' $FTP_File; fi" >> "${My_Install_Script_Name}";
                    fi
                    # CentOS uses vsftpd; maybe I should use it for the others FIX
                    #echo "nano /etc/${FTP_Install}.conf;"                                                       >> "${My_Install_Script_Name}";
                    echo "$(package_type 8 "$FTP_Install" "${Server_OS[$CIndex]}" 0);"                    >> "${My_Install_Script_Name}";
                fi
                #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            elif [[ "$This_Distro" == "archlinux" ]]; then # --------------------------- This_PSUEDONAME = Archlinux Distros
                #
                # Archlinux *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
                #                    
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-ARCHLINUX") \";"                    >> "${My_Install_Script_Name}";
                # System Upgrade            
                echo "$(package_type 9 "System-Upgrade" "${Server_OS[$CIndex]}" 0)"               >> "${My_Install_Script_Name}";
                # Install yaourt
                if ! pacman -Q "yaourt" &> /dev/null ; then        # check if a package is already installed from Core
                    echo "$(archlinux_add_repo "archlinuxfr" "http://repo.archlinux.fr/" "Never" 1)" >> "${My_Install_Script_Name}";
                    # Refresh Repo
                    echo "$(package_type 10 " " "${Server_OS[$CIndex]}" 0)"                       >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$Yaourt_Install" "${Server_OS[$CIndex]}" 0)"          >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #            
                if [[ "${Install_Apache["$CIndex"]}" -eq 1 ]]; then
                    echo "$(package_type 0 "$APACHE_Install" "${Server_OS[$CIndex]}" 0)"          >> "${My_Install_Script_Name}";
                else
                    # Stop apache 
                    echo "$(package_type 4 "$APACHE_Install" "${Server_OS[$CIndex]}" 0)"          >> "${My_Install_Script_Name}";
                    # uninstalled it
                    echo "$(package_type 2 "$APACHE_Install" "${Server_OS[$CIndex]}" 0)"          >> "${My_Install_Script_Name}";
                    # check to see who is listeners; 
                    echo "netstat -nat | grep 80 | grep LISTEN; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";" >> "${My_Install_Script_Name}";
                    # nothing;
                    echo "netstat -an | grep \"LISTEN \"; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";"       >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # PDF HARU
                if [[ "${Install_PDF["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HARU")\";"                             >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$PDF_Install" "${Server_OS[$CIndex]}" 0)"             >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #
                if [[ "${Install_Wt["$CIndex"]}" -eq 1 ]]; then
                    # Install Dev Tools
                    echo "$(package_type 0 "$DEV_TOOLS_Install" "${Server_OS[$CIndex]}" 0)"       >> "${My_Install_Script_Name}";
                    # Install Requirements
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-6") \";"                          >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$APPS_REQUIRED_Install" "${Server_OS[$CIndex]}" 0)"   >> "${My_Install_Script_Name}";
                    # Install Wt
                    if [[ "${Repo_Install["$CIndex"]}" -eq 0 ]]; then
                        echo "$(compile_install "${My_Install_Script_Name}")"                     >> "${My_Install_Script_Name}";
                    else    
                        echo "echo \" $(gettext -s "DO-INSTALL-LINE-10") \";"                     >> "${My_Install_Script_Name}";
                        echo "$(package_type 0 "$WT_REQUIRED_Install" "${Server_OS[$CIndex]}" 0)" >> "${My_Install_Script_Name}";
                    fi # End Repo_Install
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # PostgreSQL
                if [[ "${Install_PostgreSQL["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19" "PostgrSQL") \";"             >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$POSTGRESQL_Install" "${Server_OS[$CIndex]}" 0)"      >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # SQlite
                if [[ "${Install_SQlite["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19" "SQLite") \";"                >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$SQLITE_Install" "${Server_OS[$CIndex]}" 0)"          >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # HAPROXY
                if [[ "${Install_HaProxy["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HAPROXY") \";"                         >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$HAPROXY_Install" "${Server_OS[$CIndex]}" 1)"         >> "${My_Install_Script_Name}"; # yaourt install
                    echo "$(package_type 0 "$HAPROXY_Requirements" "${Server_OS[$CIndex]}" 0)"    >> "${My_Install_Script_Name}";
                    #$HAPROXY_Requirements
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # Monit
                if [[ "${Install_Monit["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-MONIT") \";"                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$MONIT_Install" "${Server_OS[$CIndex]}" 0)"           >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # Moses only Install on Master Server
                if [[ "${Install_Moses["$CIndex"]}" -eq 1 && "$CIndex" -eq 0 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-MOSES") \";"                           >> "${My_Install_Script_Name}";
                    if [ -n "$Moses_Install" ] ; then
                        echo "$(package_type 0 "$Moses_Install" "${Server_OS[$CIndex]}" 0)"       >> "${My_Install_Script_Name}";
                    else
                        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS} $(gettext -s "DO-INSTALL-MOSES") \";" >> "${My_Install_Script_Name}";
                        # http://cl.naist.jp/~eric-n/ubuntu-nlp/
                        # wget http://cl.naist.jp/~eric-n/ubuntu-nlp/8ABD1965.gpg -O- | apt-key add -
                    fi
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
            elif [[ "$This_Distro" == "debian" ]]; then # ------------------------------ Debian: This_PSUEDONAME = Ubuntu, LMDE - Distros
                #
                # Debian *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
                #                    
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-DEBIAN") \";"                       >> "${My_Install_Script_Name}";
                # @FIX gedit ~/.profile -> PATH="$HOME/bin:$PATH" -> PATH="$HOME/bin:/sbin:$PATH"
                if [[ "${Install_Apache["$CIndex"]}" -eq 1 ]]; then
                    echo "$(package_type 0 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                else
                    # Stop apache 
                    echo "$(package_type 4 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    # uninstalled it
                    echo "$(package_type 2 "$APACHE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    # check to see who is listeners;
                    echo "netstat -nat | grep 80 | grep LISTEN; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";" >> "${My_Install_Script_Name}";
                    # nothing;
                    echo "netstat -an | grep \"LISTEN \"; read -e -sn 1 -p \"$(gettext -s "PRESS-ANY-KEY-CONTINUE")\";" >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                #
                # Refresh Repo
                echo "$(package_type 10 " " "${Server_OS[$CIndex]}" 0);"                          >> "${My_Install_Script_Name}";
                #
                if [[ "${Install_Wt["$CIndex"]}" -eq 1 ]]; then
                    echo "$Repo_Extra"                                                            >> "${My_Install_Script_Name}";
                    echo "$Repo_Extra_Key"                                                        >> "${My_Install_Script_Name}";
                    echo "$Run_This"                                                              >> "${My_Install_Script_Name}";
                    # Install Dev Tools
                    echo "$(package_type 0 "$DEV_TOOLS_Install" "${Server_OS[$CIndex]}" 0);"      >> "${My_Install_Script_Name}";
                    # Install Requirements
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-6") \";"                          >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$APPS_REQUIRED_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                    # Install Wt
                    if [[ "${Repo_Install["$CIndex"]}" -eq 0 ]]; then
                        echo "$(compile_install "${My_Install_Script_Name}")"                     >> "${My_Install_Script_Name}";
                    else    
                        echo "echo \" $(gettext -s "DO-INSTALL-LINE-10") \";"                     >> "${My_Install_Script_Name}";
                        echo "$(package_type 0 "$WT_REQUIRED_Install" "${Server_OS[$CIndex]}" 0);">> "${My_Install_Script_Name}";
                    fi # End Repo_Install
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # System Upgrade
                echo "echo \" $(gettext -s "DO-INSTALL-LINE-9") \";"                              >> "${My_Install_Script_Name}";
                echo "$(package_type 9 "System-Upgrade" "${Server_OS[$CIndex]}" 0);"              >> "${My_Install_Script_Name}";
                # PDF HARU
                if [[ "${Install_PDF["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HARU")\";"                             >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$PDF_Install" "${Server_OS[$CIndex]}" 0);"            >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # Moses
                if [[ "$This_PSUEDONAME" == "Debian" ]]; then
                    # Moses only install on Master Server
                    if [[ "${Install_Moses["$CIndex"]}" -eq 1 && "$CIndex" -eq 0 ]]; then
                        echo "echo \" $(gettext -s "DO-INSTALL-MOSES") \";"                       >> "${My_Install_Script_Name}";
                        if [ -n "$Moses_Install" ] ; then
                            echo "$(package_type 0 "$Moses_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                        else
                            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS} $(gettext -s "DO-INSTALL-MOSES") \";" >> "${My_Install_Script_Name}";
                            # http://cl.naist.jp/~eric-n/ubuntu-nlp/
                            # wget http://cl.naist.jp/~eric-n/ubuntu-nlp/8ABD1965.gpg -O- | apt-key add -
                        fi
                    fi
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                elif [[ "$This_PSUEDONAME" == "Ubuntu" ]]; then
                    # Moses only install on Master Server
                    if [[ "${Install_Moses["$CIndex"]}" -eq 1 && "$CIndex" -eq 0 ]]; then
                        echo "echo \" $(gettext -s "DO-INSTALL-MOSES") \";"                       >> "${My_Install_Script_Name}";
                        if [ -n "$Moses_Install" ] ; then
                            echo "$(package_type 0 "$Moses_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                        else
                        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS} $(gettext -s "DO-INSTALL-MOSES") \";" >> "${My_Install_Script_Name}";
                            # http://cl.naist.jp/~eric-n/ubuntu-nlp/
                            # wget http://cl.naist.jp/~eric-n/ubuntu-nlp/8ABD1965.gpg -O- | apt-key add -
                        fi
                    fi
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                elif [[ "$This_PSUEDONAME" == "LMDE" ]]; then
                    # Moses only install on Master Server
                    if [[ "${Install_Moses["$CIndex"]}" -eq 1 && "$CIndex" -eq 0 ]]; then
                        echo "echo \" $(gettext -s "DO-INSTALL-MOSES") \";"                       >> "${My_Install_Script_Name}";
                        if [ -n "$Moses_Install" ] ; then
                            echo "$(package_type 0 "$Moses_Install" "${Server_OS[$CIndex]}" 0);"  >> "${My_Install_Script_Name}";
                        else
                        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS} $(gettext -s "DO-INSTALL-MOSES") \";" >> "${My_Install_Script_Name}";
                            # http://cl.naist.jp/~eric-n/ubuntu-nlp/
                            # wget http://cl.naist.jp/~eric-n/ubuntu-nlp/8ABD1965.gpg -O- | apt-key add -
                        fi
                        echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                    fi
                fi
                # PostgreSQL
                if [[ "${Install_PostgreSQL["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19") PostgrSQL \""                >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$POSTGRESQL_Install" "${Server_OS[$CIndex]}" 0);"     >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$Master_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # SQlite
                if [[ "${Install_SQlite["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-LINE-19") SQLite \""                   >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$SQLITE_Install" "${Server_OS[$CIndex]}" 0);"         >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # HAPROXY
                if [[ "${Install_HaProxy["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-HAPROXY") \";"                         >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$HAPROXY_Install" "${Server_OS[$CIndex]}" 0);"        >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
                # Monit
                if [[ "${Install_Monit["$CIndex"]}" -eq 1 ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-MONIT") \";"                           >> "${My_Install_Script_Name}";
                    echo "$(package_type 0 "$MONIT_Install" "${Server_OS[$CIndex]}" 0);"          >> "${My_Install_Script_Name}";
                    echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"               >> "${My_Install_Script_Name}";
                fi
            elif [[ "$This_Distro" == "unitedlinux" ]]; then # ------------------------- This_PSUEDONAME = unitedlinux Distros
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"    >> "${My_Install_Script_Name}";
            elif [[ "$This_Distro" == "mandrake" ]]; then # ---------------------------- This_PSUEDONAME = Mandrake Distros
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"    >> "${My_Install_Script_Name}";
            elif [[ "$This_Distro" == "suse" ]]; then # -------------------------------- This_PSUEDONAME = Suse Distros
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\" \"${This_OS}\";"    >> "${My_Install_Script_Name}";
            fi
        fi # end Linux
        # ***********************************************************
        # *
        install_app "${My_Install_Script_Name}" "$CIndex";     
        make_haproxy_monit "${My_Install_Script_Name}" "$CIndex";
        echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***"                           >> "${My_Install_Script_Name}";
    done
    # @FIX this is not getting written to file
    echo "# *** EOS ***"                                                                          >> "${My_Install_Script_Name}";
    return 0;
}
# -----------------------------------------------------------------------------
# MAKE HAPROXY MONIT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="make_haproxy_monit";
    USAGE="$(localize "MAKE-HAPROXY-USAGE")";
    DESCRIPTION="$(localize "MAKE-HAPROXY-DESC")";
    NOTES="$(localize "MAKE-HAPROXY-MONIT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "MAKE-HAPROXY-MONIT-USAGE"    "make_haproxy_monit 1->(FileName) 2->(Index)" "Comment: make_haproxy_monit @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-HAPROXY-MONIT-DESC"     "Create <a href='http://haproxy.1wt.eu/download/1.3/doc/configuration.txt' target='_blank'>haproxy</a> and <a href='http://mmonit.com/monit/documentation/monit.html' target='_blank'>monit</a> install Script." "Comment: make_haproxy_monit @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-HAPROXY-MONIT-NOTES"    "Load Balancing and Monitoring." "Comment: make_haproxy_monit @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "MAKE-HAPROXY-MONIT-INFO"     "Create haproxy and monit install Script for" "Comment: make_haproxy_monit @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
make_haproxy_monit()
{
    local -i total="${#App_Domains[@]}"; # total array count
    local -i App_Port="${App_Ports["$2"]}"; # App_Port to increment
    print_info "MAKE-HAPROXY-MONIT-INFO" "${Server_Names[$2]} $(($2+1)) -> $total";
    # linux:redhat:redhat-centos-fedora
    local This_OS="$(string_split "${Server_OS[$2]}" ":" 1)";             # linux
    local This_Distro="$(string_split "${Server_OS[$2]}" ":" 2)";         # redhat,archlinux,debian
    local This_PSUEDONAME="$(string_split "${Server_OS[$2]}" ":" 3)";     # centos,fedora,Ubuntu,LMDE
    local This_Distro_Version="$(string_split "${Server_OS[$2]}" ":" 4)"; # squeeze,wheezy,lenny,raring,quantal,precise
    local This_Version="$(string_split "${Server_OS[$2]}" ":" 5)";        # 5,6
    local PathHa='/etc/haproxy/haproxy.cfg';                              # haproxy.cfg location
    local -i CIndex=0;                                                    # loop
    local -i ST_Total=${Server_Threads["$2"]};                            # Server Thread Total
    #
    # 
    # Repo_Install
    #
        # this code is not used yet, 
        if [[ "$This_OS" == "solaris" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_OS" == "aix" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_OS" == "freebsd" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_OS" == "windowsnt" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_OS" == "mac" ]]; then
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_OS" == "linux" ]]; then
            # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use This_PSUEDONAME
            # See wizard.sh os_info to see if OS test exist or works
            if [[ "$This_Distro" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                # Redhat, Centos, Fedora 
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-REDHAT")\";" >> "${1}";
                
            elif [[ "$This_Distro" == "archlinux" ]]; then # --------------------------- This_PSUEDONAME = Archlinux Distros
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-ARCHLINUX") \";" >> "${1}";
                
            elif [[ "$This_Distro" == "debian" ]]; then # ------------------------------ Debian: This_PSUEDONAME = Ubuntu, LMDE - Distros
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-DEBIAN") \";" >> "${1}";
                
                if [[ "$This_PSUEDONAME" == "Debian" ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
                elif [[ "$This_PSUEDONAME" == "Ubuntu" ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
                elif [[ "$This_PSUEDONAME" == "LMDE" ]]; then
                    echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
                fi
            elif [[ "$This_Distro" == "unitedlinux" ]]; then # ------------------------- This_PSUEDONAME = unitedlinux Distros
                echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
            elif [[ "$This_Distro" == "mandrake" ]]; then # ---------------------------- This_PSUEDONAME = Mandrake Distros
                echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
            elif [[ "$This_Distro" == "suse" ]]; then # -------------------------------- This_PSUEDONAME = Suse Distros
                echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
            fi
        fi
    
    #
    if [[ "${Install_Monit["$2"]}" -eq 1 ]]; then
        echo "echo \"$(gettext -s "DO-INSTALL-LINE-16")\";" >> "${1}";
        echo "cp /etc/monit.conf /etc/monit.conf.bak;" >> "${1}";
        #
        App_Port="${App_Ports["$2"]}"; # Reset Value
        # 
        echo "echo \"# $(gettext -s "DO-INSTALL-INSTALL-BY") $DATE_TIME \" > /etc/monit.conf;" >> "${1}";
        #
        for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
            if [[ "$2" -ne 0 && "$2" -eq "$2" ]]; then      # Not Master and This Record
                echo "echo 'check process ${App_Names[$2]}.wt-$((App_Port)) with pidfile ${App_Paths[$2]}/run/${App_Names[$2]}.wt-$((App_Port)).pid ' >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' start program  = " "${App_Paths[$2]}/wthttpd.sh start ${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt ${App_IPs[$2]} $((App_Port))" " with timeout 60 seconds ' >> /etc/monit.conf;" >> "${1}";
                # echo "echo \"  start program = \"${App_Paths["$2"]}/wthttpd.sh start ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt ${App_IPs["$2"]} $((App_Port))\" with timeout 60 seconds \" >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' stop program  = " "${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))" "' >> /etc/monit.conf;" >> "${1}";
                # echo "echo \"  stop program  = \"${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))\" \" >> /etc/monit.conf;" >> "${1}";
                echo "echo \"  if failed port $((App_Port)) protocol http request /monittoken-$((App_Port++)) then restart \" >> /etc/monit.conf;" >> "${1}";
            elif [[ "$2" -ne 0 && "$2" -eq "$2" ]]; then      # Not Master and This Record
                echo "echo \"check process ${App_Names[$2]}.wt-$((App_Port)) with pidfile ${App_Paths[$2]}/run/${App_Names[$2]}.wt-$((App_Port)).pid \" >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' start program  = " "${App_Paths[$2]}/wthttpd.sh start ${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt ${App_IPs[$2]} $((App_Port))" " with timeout 60 seconds ' >> /etc/monit.conf;" >> "${1}";
                # echo "echo \"  start program = \"${App_Paths["$2"]}/wthttpd.sh start ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt ${App_IPs["$2"]} $((App_Port))\" with timeout 60 seconds \" >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' stop program  = " "${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))" "' >> /etc/monit.conf;" >> "${1}";
                # echo "echo \"  stop program  = \"${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))\" \" >> /etc/monit.conf;" >> "${1}";
                echo "echo \"  if failed port $((App_Port)) protocol http request /monittoken-$((App_Port++)) then restart \" >> /etc/monit.conf;" >> "${1}";
            elif [[ "$2" -ne 0 && "$2" -ne "$2" ]]; then      # Not Master and Not This Record - 
                echo "echo \"check process ${App_Names[$2]}.wt-$((App_Port)) with pidfile ${App_Paths[$2]}/run/${App_Names[$2]}.wt-$((App_Port)).pid \" >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' start program  = " "${App_Paths[$2]}/wthttpd.sh start ${App_Paths[$2]}/${App_Folder[$2]}/${App_Names[$2]}.wt ${App_IPs[$2]} $((App_Port))" " with timeout 60 seconds ' >> /etc/monit.conf;" >> "${1}";
                # echo echo \"  start program = \"${App_Paths["$2"]}/wthttpd.sh start ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt ${App_IPs["$2"]} $((App_Port))\" with timeout 60 seconds \" >> /etc/monit.conf;" >> "${1}";
                printf '%-s\"%-s\"%-s\n' "echo ' stop program  = " "${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))" "' >> /etc/monit.conf;" >> "${1}";
                # echo "echo \"  stop program  = \"${App_Paths["$2"]}/wthttpd.sh stop  ${App_Paths["$2"]}/${App_Folder["$2"]}/${App_Names["$2"]}.wt $((App_Port))\" \" >> /etc/monit.conf;" >> "${1}";
                echo "echo \"  if failed port $((App_Port)) protocol http request /monittoken-$((App_Port++)) then restart \" >> /etc/monit.conf;" >> "${1}";
            fi
        done
        #
        #echo "nano /etc/monit.conf;" >> "${1}";
        echo "echo \"$(gettext -s "DO-INSTALL-LINE-17")\";"             >> "${1}";
        echo "$(package_type 7 "$MONIT_Install" "${Server_OS[$2]}" 0);" >> "${1}";
        echo "# *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ***" >> "${1}";
    fi # End if Install_Monit
    #
    if [[ "${Install_HaProxy["$2"]}" -eq 1 ]]; then
        #
        # /etc/apache2/apache2.conf >> 
        # #LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
        # LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
        #
        # http://www.mattbeckman.com/ 
        #
        # reqirep ^Accept-Encoding:\ gzip[,]*[\ ]*deflate.* Accept-Encoding:\ gzip,deflate
        #
        # redirect prefix http://example.com code 301 if { hdr(host) -i www.example.com }
        #
        # ca-base
        # crt-base
        #
        # chroot 
        #   This only works when the process is started with superuser privileges. 
        #   It is important to ensure that <jail_dir> is both empty and unwritable to anyone.
        # 
        # maxcompcpuusage Sets the maximum CPU usage HAProxy can reach before stopping the compression for new requests or decreasing the compression level of current requests.
        #
        # bind 10.0.0.9:443 name https ssl crt /path/to/domain.pem ciphers RC4:HIGH:!aNULL:!MD5
        #
        # Called from inside a loop, pasted in Output full path, 
        # ******************>
        # 1. Glabal Section *
        # ******************>
        echo "echo \"$(gettext -s "DO-INSTALL-LINE-13")\";"                    >> "${1}";
        echo "cp $PathHa ${PathHa}.bak;"                                       >> "${1}";
        echo "echo \"global\"                                    > ${PathHa};" >> "${1}";
        echo "echo \"    log 127.0.0.1 local0\"                 >> ${PathHa};" >> "${1}";
        echo "echo \"    log 127.0.0.1 local1 notice\"          >> ${PathHa};" >> "${1}";
        # ******************>
        # 2. maxconn Sets the maximum per-process number of concurrent connections to <number>.
        # ******************>
        echo "echo \"    maxconn ${Global_Maxconn[$2]}\"        >> ${PathHa};" >> "${1}";
        echo "echo \"    user haproxy\"                         >> ${PathHa};" >> "${1}";
        echo "echo \"    group haproxy\"                        >> ${PathHa};" >> "${1}";
        # ******************>
        # 3. Makes the process fork into background. This is the recommended mode of operation.
        echo "echo \"    daemon\"                               >> ${PathHa};" >> "${1}";
        # ******************>
        echo "echo \"    stats socket    /tmp/haproxy\"         >> ${PathHa};" >> "${1}";
        echo "echo \"\"                                         >> ${PathHa};" >> "${1}";
        # ******************>
        # 4. A "defaults" section sets default parameters for all other sections following its declaration.
        # ******************>
        echo "echo \"defaults\"                                 >> ${PathHa};" >> "${1}";
        echo "echo \"    log           global\"                 >> ${PathHa};" >> "${1}";
        echo "echo \"    mode          http\"                   >> ${PathHa};" >> "${1}";
        echo "echo \"    option        httplog\"                >> ${PathHa};" >> "${1}";
        echo "echo \"    option        dontlognull\"            >> ${PathHa};" >> "${1}";
        #        
        echo "echo \"    option        http-server-close\"      >> ${PathHa};" >> "${1}";
        echo "echo \"    option        http-pretend-keepalive\" >> ${PathHa};" >> "${1}";
        echo "echo \"    option        forwardfor\"             >> ${PathHa};" >> "${1}";
        echo "echo \"    option        originalto\"             >> ${PathHa};" >> "${1}";
        #
        echo "echo \"    retries       3\"                      >> ${PathHa};" >> "${1}";
        echo "echo \"    option        redispatch\"             >> ${PathHa};" >> "${1}";
        # ******************>
        # 5. maxconn
        # ******************>
        echo "echo \"    maxconn       ${Default_Maxconn[$2]}\" >> ${PathHa};" >> "${1}";
        echo "echo \"    contimeout    5000\"                   >> ${PathHa};" >> "${1}";
        echo "echo \"    clitimeout    50000\"                  >> ${PathHa};" >> "${1}";
        echo "echo \"    srvtimeout    50000\"                  >> ${PathHa};" >> "${1}";
        echo "echo \"\"                                         >> ${PathHa};" >> "${1}";
        # ******************>
        # 6. A "frontend" section describes a set of listening sockets accepting client connections.
        # ******************>
        echo "echo \"frontend wt\"                              >> ${PathHa};" >> "${1}";
        #
        # ******************>
        local ThisIP="${App_IPs["$2"]}";           # This script is called in a Loop, $2 is index of loop
        local ThisDefault="${Server_Names["$2"]}";
        # ******************>
        #
        # called inside a loop; 
        #
        for (( CIndex=0; CIndex<total; CIndex++ )); do
            echo "# *** Index=$CIndex $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
            App_Port="${App_Ports["$CIndex"]}";
            if [[ "$CIndex" -eq 0 && "$2" -eq 0 && "$CIndex" -eq "$2" ]]; then        # Master and This Record
                # ******************>
                echo "# Start: Master and This Record FE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                # ******************>
                printf "%s        %s %43s\n" "echo \""  "bind ${App_IPs["$CIndex"]}:80 \"" ">> ${PathHa};" >> "${1}";
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    echo "echo \"        #\" >> ${PathHa};" >> "${1}";
                    echo "# ${App_IPs["$CIndex"]}:$App_Port *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    # Returns true when one of the headers ends with one of the strings. See "hdr" for more information on header matching. Use the shdr_end() variant for response headers sent by the server.
                    echo "echo \"        acl $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex} url_sub wtd=wt-$((App_Port++))\" >> ${PathHa};" >> "${1}";
                    # Returns true when the number of usable servers of either the current backend or the named backend matches the values or ranges specified. This is used to switch to an alternate backend when the number of servers is too low to to handle some load
                    echo "echo \"        acl $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}_up nbsrv($(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}) gt 0\" >> ${PathHa};" >> "${1}";
                    # All proxy names must be formed from upper and lower case letters, digits, '-' (dash), '_' (underscore) , '.' (dot) and ':' (colon). ACL names are case-sensitive, which means that "www" and "WWW" are two different proxies.
                    echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex} if $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}_up $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}\" >> ${PathHa};" >> "${1}";
                done
                # ******************>
                echo "# End: Master and This Record FE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                # ******************>
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -eq "$2" ]]; then      # Not Master and This Record
                if [[ "${App_IPs["$2"]}" == "$ThisIP" ]]; then # This should always be true, maybe remove it
                    # ******************>
                    echo "# Start: Not Master and This Record FE | Install_Type=${Install_Type[$CIndex]} | ${App_IPs[$CIndex]} | ThisIP=$ThisIP *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    # ******************>
                    printf "%s        %s %43s\n" "echo \""  "bind ${App_IPs["$CIndex"]}:80\"" ">> ${PathHa};" >> "${1}";
                    echo "echo \"        #\" >> ${PathHa};" >> "${1}";
                    # @FIX make it both ways, 
                    if [[ "${Is_WWW["$CIndex"]}" -eq 1 ]]; then
                        echo "echo \"        redirect prefix http://www.${App_Domains[$CIndex]} code 301 if { hdr(host) -i ${App_Domains[$CIndex]} }\" >> ${PathHa};" >> "${1}";
                    else
                        echo "echo \"        redirect prefix http://${App_Domains[$CIndex]} code 301 if { hdr(host) -i www.${App_Domains[$CIndex]} }\" >> ${PathHa};" >> "${1}";
                    fi
                    #                    
                    for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                        echo "echo \"        #\" >> ${PathHa};" >> "${1}";
                        if [[ "${Install_Type[$CIndex]}" -eq 0 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=0 Wthttpd Server *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                            # Returns true when one of the headers ends with one of the strings. See "hdr" for more information on header matching. Use the shdr_end() variant for response headers sent by the server.
                            echo "echo \"        acl is_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_$SIndex hdr_end(host) -i ${App_Domains[$CIndex]}\" >> ${PathHa};" >> "${1}";
                            # Returns true when the number of usable servers of either the current backend or the named backend matches the values or ranges specified. This is used to switch to an alternate backend when the number of servers is too low to to handle some load
                            echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex}_up nbsrv($(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_$SIndex) gt 0\" >> ${PathHa};" >> "${1}";
                            # check to see if its on thread is on port with prefix
                            echo "echo \"        acl is_sub_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_$SIndex url_sub wtd=wt-$((App_Port++))\" >> ${PathHa};" >> "${1}";
                            # All proxy names must be formed from upper and lower case letters, digits, '-' (dash), '_' (underscore) , '.' (dot) and ':' (colon). ACL names are case-sensitive, which means that "www" and "WWW" are two different proxies.
                            echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex} if is_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex} is_sub_$(string_replace "${App_Domains[$2]}" '.' '_' )_$SIndex $(string_replace "${App_Domains[$2]}" '.' '_' )_${SIndex}_up \" >> ${PathHa};" >> "${1}";
                        elif [[ "${Install_Type[$CIndex]}" -eq 1 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=1 Web Server *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        elif [[ "${Install_Type[$CIndex]}" -eq 2 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=2 Static Content *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                            echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_static_$SIndex hdr_beg(host) -i ${Static_Path[$CIndex]}\" >> ${PathHa};" >> "${1}";
                            echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_url_${SIndex} path_beg /${Static_Path[$CIndex]}\"         >> ${PathHa};" >> "${1}";
                            echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_static_${SIndex} if $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_static_$SIndex\" >> ${PathHa};" >> "${1}";
                            echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_url_${SIndex} if $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_url_$SIndex\" >> ${PathHa};" >> "${1}";
                            #acl host_static hdr_beg(host) -i static  
                            #acl url_static  path_beg    /static  
                            #use_backend static if host_static  
                            #use_backend static if url_static                          
                            echo '# Static Content' >> "${1}";
                        elif [[ "${Install_Type[$CIndex]}" -eq 3 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=3 Email Server *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        elif [[ "${Install_Type[$CIndex]}" -eq 4 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=4 Database Engine PostgreSQL *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        elif [[ "${Install_Type[$CIndex]}" -eq 5 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=5 Database Engine MySQL *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        fi # End if Install_Type
                    done # for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    #
                    # Now to look at all the rest of the Records
                    
                    # ******************>
                    echo "# End: Not Master and This Record FE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    # ******************>
                fi # End if [[ "${App_IPs["$2"]}" == "$ThisIP" ]]; then
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -ne "$2" ]]; then      # Not Master and Not This Record - 
                # ******************>
                echo "# Start: Not Master and Not This Record FE | Install_Type=${Install_Type[$CIndex]} | ${App_IPs[$CIndex]} | ThisIP=$ThisIP *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                # ******************>
                # 
                #if [[ "${App_IPs[$CIndex]}" == "$ThisIP" ]]; then
                    for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                        echo "echo \"        #\" >> ${PathHa};" >> "${1}";
                        if [[ "${Install_Type[$CIndex]}" -eq 0 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=0 Wthttpd Server *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                            # Returns true when one of the headers ends with one of the strings. See "hdr" for more information on header matching. Use the shdr_end() variant for response headers sent by the server.
                            #echo "echo \"        acl is_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_$SIndex hdr_end(host) -i ${App_Domains[$CIndex]}\" >> ${PathHa};" >> "${1}";
                            # Returns true when the number of usable servers of either the current backend or the named backend matches the values or ranges specified. This is used to switch to an alternate backend when the number of servers is too low to to handle some load
                            #echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex}_up nbsrv($(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_$SIndex) gt 0\" >> ${PathHa};" >> "${1}";
                            # All proxy names must be formed from upper and lower case letters, digits, '-' (dash), '_' (underscore) , '.' (dot) and ':' (colon). ACL names are case-sensitive, which means that "www" and "WWW" are two different proxies.
                            # check to see if its on thread is on port with prefix
                            # Can not do this, its local to the machine ->  echo "echo \"        acl is_sub_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_$SIndex url_sub wtd=wt-$((App_Port++))\" >> ${PathHa};" >> "${1}";
                            # All proxy names must be formed from upper and lower case letters, digits, '-' (dash), '_' (underscore) , '.' (dot) and ':' (colon). ACL names are case-sensitive, which means that "www" and "WWW" are two different proxies.
                            #echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex} if is_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex} $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex}_up\" >> ${PathHa};" >> "${1}";
                        fi # End if Install_Type
                    done
                    #                    
                    if [[ "${Install_Type[$CIndex]}" -eq 1 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                            echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=1 Web Server *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                            #acl host_static hdr_beg(host) -i static  
                            #acl url_static  path_beg    /static  
                            #use_backend static if host_static  
                            #use_backend static if url_static              
                            
                            #backend static  
                            #   # for static media, connections are cheap, plus the client is very likely to request multiple files    
                            #   # so, keep the connection open (KeepAlive is the default)    
                            #   balance roundrobin  
                            #   server media1 media1 check port 80  
                            #   server media2 media2 check port 80  
                            #  
                            #listen stats :1936  
                            #   mode http  
                            #   stats enable  
                            #   stats scope http  
                            #   stats scope www  
                            #   stats scope static  
                            #   stats scope static_httpclose  
                            #   stats realm Haproxy\ Statistics  
                            #   stats uri /                                          
                    elif [[ "${Install_Type[$CIndex]}" -eq 2 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "# ${App_IPs["$CIndex"]}:$App_Port -> Install_Type=2 Static Content *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_static_$SIndex hdr_beg(host) -i ${App_Domains[$CIndex]}\" >> ${PathHa};" >> "${1}";
                        echo "echo \"        acl $(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex}_up nbsrv($(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_$SIndex) gt 0\" >> ${PathHa};" >> "${1}";
                        # check to see if its on thread is on port with prefix
                        echo "echo \"        acl is_sub_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_$SIndex url_sub wtd=wt-$((App_Port++))\" >> ${PathHa};" >> "${1}";
                        # All proxy names must be formed from upper and lower case letters, digits, '-' (dash), '_' (underscore) , '.' (dot) and ':' (colon). ACL names are case-sensitive, which means that "www" and "WWW" are two different proxies.
                        echo "echo \"        use_backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex} if is_$(string_replace "${App_Domains[$CIndex]}" '.' '_' )_${SIndex} is_sub_$(string_replace "${App_Domains[$2]}" '.' '_' )_$SIndex $(string_replace "${App_Domains[$2]}" '.' '_' )_${SIndex}_up\" >> ${PathHa};" >> "${1}";
                    elif [[ "${Install_Type[$CIndex]}" -eq 3 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "# ${App_IPs["$CIndex"]}:$App_Port *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                        
                    elif [[ "${Install_Type[$CIndex]}" -eq 4 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "# ${App_IPs["$CIndex"]}:$App_Port *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    elif [[ "${Install_Type[$CIndex]}" -eq 5 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "# ${App_IPs["$CIndex"]}:$App_Port *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    fi
                    # ******************>
                    echo "# End: Not Master and Not This Record FE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                    # ******************>
                #fi # End if [[ "${App_IPs["$2"]}" != "$ThisIP" ]]; then
            fi # End elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -ne "$2" ]]; then
        done # for (( CIndex=0; CIndex<total; CIndex++ )); do
        echo "echo \"        #\"                                          >> ${PathHa};" >> "${1}";
        echo "echo \"        default_backend ${ThisDefault//./_}_lb\"     >> ${PathHa};" >> "${1}";
        echo "echo \"# Set default Backend \"                             >> ${PathHa};" >> "${1}";
        #
        local SIndex=0;
        #
        # A "backend" section describes a set of servers to which the proxy will connect to forward incoming connections.
        echo "echo \"backend $(string_replace "${Server_Names[$2]}" '.' '_' )_lb\" >> ${PathHa};" >> "${1}";
        echo "echo \"        balance roundrobin\"                                  >> ${PathHa};" >> "${1}";
        for (( CIndex=0; CIndex<total; CIndex++ )); do
            #
            App_Port="${App_Ports[$CIndex]}"; # Reset Value
            if [[ "$CIndex" -eq 0 && "$2" -eq 0 && "$CIndex" -eq "$2" ]]; then        # Master and This Record
                #
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex} ${App_IPs[$CIndex]}:$((App_Port++)) track $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}/$(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}\" >> ${PathHa};" >> "${1}";
                done
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -eq "$2" ]]; then      # Not Master and This Record
                #
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex} ${App_IPs[$CIndex]}:$((App_Port++)) track $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}/$(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}\" >> ${PathHa};" >> "${1}";
                done
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -ne "$2" ]]; then      # Not Master and Not This Record - 
                #
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex} ${App_IPs[$CIndex]}:$((App_Port++))\" >> ${PathHa};" >> "${1}"; #  track $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}/$(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex}
                done
            fi
        done
        #
        local -i IsMasterRecord=0;
        #
        for (( CIndex=0; CIndex<total; CIndex++ )); do
            #
            App_Port="${App_Ports[$CIndex]}"; # Reset Value
            #
            if [[ "$CIndex" -eq 0 && "$2" -eq 0 && "$CIndex" -eq "$2" ]]; then        # Master and This Record
                echo "# Start: Master and This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    echo "echo \"backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_$SIndex\"          >> ${PathHa};" >> "${1}";                
                    echo "echo \"        balance roundrobin\"                                                        >> ${PathHa};" >> "${1}";
                    echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${CIndex} ${App_IPs[$CIndex]}:$((App_Port++)) check\"   >> ${PathHa};" >> "${1}";
                    echo "echo \"\"                                                                                  >> ${PathHa};" >> "${1}";
                done
                echo "# End: Master and This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -eq "$2" ]]; then      # Not Master and This Record
                echo "# Start: Not Master and This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                #
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    # A "backend" section describes a set of servers to which the proxy will connect to forward incoming connections.
                    if [[ "${Install_Type[$CIndex]}" -eq 0 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "echo \"backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}\"         >> ${PathHa};" >> "${1}";
                        echo "echo \"        balance roundrobin\"                                                         >> ${PathHa};" >> "${1}";
                        echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${SIndex} ${App_IPs[$CIndex]}:$((App_Port++)) check\" >> ${PathHa};"   >> "${1}";
                    elif [[ "${Install_Type[$CIndex]}" -eq 2 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "echo \"backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_static_${SIndex}\"  >> ${PathHa};" >> "${1}";
                        echo "echo \"        balance roundrobin\"                                                         >> ${PathHa};" >> "${1}";
                        echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${$CIndex} ${App_IPs[$CIndex]}:$((App_Port++)) check\" >> ${PathHa};"   >> "${1}";
                    fi
                done
                echo "# End: Not Master and This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
            elif [[ "$CIndex" -ne 0 && "$2" -ne 0 && "$CIndex" -ne "$2" ]]; then      # Not Master and Not This Record - 
                echo "# Start: Not Master and Not This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
                #
                for (( SIndex=0; SIndex<ST_Total; SIndex++ )); do
                    # A "backend" section describes a set of servers to which the proxy will connect to forward incoming connections.
                    if [[ "${Install_Type[$CIndex]}" -eq 0 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "echo \"backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_${SIndex}\"         >> ${PathHa};" >> "${1}";
                        echo "echo \"        balance roundrobin\"                                                        >> ${PathHa};" >> "${1}";
                        echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${CIndex} ${App_IPs[$CIndex]}:$((App_Port++)) check\" >> ${PathHa};"   >> "${1}";
                    elif [[ "${Install_Type[$CIndex]}" -eq 2 ]]; then # 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
                        echo "echo \"backend $(string_replace "${Server_Names[$CIndex]}" '.' '_' )_be_static_${SIndex}\"  >> ${PathHa};" >> "${1}";
                        echo "echo \"        balance roundrobin\"                                                        >> ${PathHa};" >> "${1}";
                        echo "echo \"        server $(string_replace "${Server_Names[$CIndex]}" '.' '_' )-ST-${$CIndex} ${App_IPs[$CIndex]}:$((App_Port++)) check\" >> ${PathHa};"   >> "${1}";
                    fi
                done
                echo "# End: Not Master and Not This Record BE *** $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" >> "${1}";
            fi
        done    
        echo "echo \"# haproxy stat http://${App_Domains[$2]}:1936/haproxy?stats\" >> ${PathHa};"   >> "${1}";
        echo "echo \"listen stats :1936\"                  >> ${PathHa};"   >> "${1}";
        echo "echo \"    mode http\"                       >> ${PathHa};"   >> "${1}";
        echo "echo \"    stats enable\"                    >> ${PathHa};"   >> "${1}";
        echo "echo \"#    stats hide-version\"              >> ${PathHa};"   >> "${1}"; # FIX
        echo "echo \"    stats realm Haproxy\ Statistics\" >> ${PathHa};"   >> "${1}";
        echo "echo \"    stats uri /\"                     >> ${PathHa};"   >> "${1}";
        local MySecretUserName=$(password_safe "${HA_User_Names[$2]}" "$MyPassword" 'encrypt');
        echo "declare MySecretUserName=\"$MySecretUserName\";"              >> "${1}"; 
        local MySecretPassword=$(password_safe "${HA_Passwords[$2]}" "$MyPassword" 'encrypt');
        echo "declare MySecretPassword=\"$MySecretPassword\";"              >> "${1}"; 
        echo "echo \"    stats auth \$(password_safe \"\${MySecretUserName}\" \"\$MyPassword\" 'decrypt'):\$(password_safe \"\${MySecretPassword}\" \"\$MyPassword\" 'decrypt')\" >> ${PathHa};" >> "${1}"; 
        #    
        echo "echo \"# EOF #\"                             >> ${PathHa};"   >> "${1}";
        #
        # Edit not working via ssh
        #echo "echo \"$(gettext -s "DO-INSTALL-LINE-14")\";" >> "${1}";
        #echo "nano "${PathHa}";" >> "${1}";
        echo "echo \"$(gettext -s "DO-INSTALL-START-HAPROXY")\";"           >> "${1}";
        echo "$(package_type 6 "$HAPROXY_Install" "${Server_OS[$2]}" 0);"   >> "${1}";
    fi # End if Install_HaProxy
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# COMPILE INSTALL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="compile_install";
    USAGE="$(localize "COMPILE-INSTALL-USAGE")";
    DESCRIPTION="$(localize "COMPILE-INSTALL-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "COMPILE-INSTALL-USAGE"    "compile_install 1->(FileName)" "Comment: compile_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COMPILE-INSTALL-DESC"     "Compile Installation" "Comment: compile_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "COMPILE-INSTALL-TITLE"    "Compile Installation." "Comment: compile_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COMPILE-INSTALL-INFO"     "Compile Install" "Comment: compile_install @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
compile_install()
{
    print_title "COMPILE-INSTALL-TITLE";
    print_info "COMPILE-INSTALL-INFO";
    # Boost http://sourceforge.net/projects/boost/files/latest/download

    if [[ "$This_OS" == "solaris" ]]; then
        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
    elif [[ "$This_OS" == "aix" ]]; then
        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
    elif [[ "$This_OS" == "freebsd" ]]; then
        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
    elif [[ "$This_OS" == "windowsnt" ]]; then
        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
    elif [[ "$This_OS" == "mac" ]]; then
        echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
    elif [[ "$This_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use This_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$This_Distro" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            # Redhat, Centos, Fedora 
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-REDHAT")\";" >> "${1}";
            
        elif [[ "$This_Distro" == "archlinux" ]]; then # --------------------------- This_PSUEDONAME = Archlinux Distros
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-ARCHLINUX") \";" >> "${1}";
            
        elif [[ "$This_Distro" == "debian" ]]; then # ------------------------------ Debian: This_PSUEDONAME = Ubuntu, LMDE - Distros
            echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-DEBIAN") \";" >> "${1}";
            
            if [[ "$This_PSUEDONAME" == "Debian" ]]; then
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
            elif [[ "$This_PSUEDONAME" == "Ubuntu" ]]; then
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
            elif [[ "$This_PSUEDONAME" == "LMDE" ]]; then
                echo "echo \" $(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED") \";" >> "${1}";
            fi
        elif [[ "$This_Distro" == "unitedlinux" ]]; then # ------------------------- This_PSUEDONAME = unitedlinux Distros
            echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_Distro" == "mandrake" ]]; then # ---------------------------- This_PSUEDONAME = Mandrake Distros
            echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        elif [[ "$This_Distro" == "suse" ]]; then # -------------------------------- This_PSUEDONAME = Suse Distros
            echo "echo \"$(gettext -s "DO-INSTALL-DISTRO-UNSUPPORTED")\";" >> "${1}";
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# ARCHLINUX ADD REPO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="archlinux_add_repo";
    USAGE="$(localize "ARCHLINUX-ADD-REPO-USAGE")";
    DESCRIPTION="$(localize "ARCHLINUX-ADD-REPO-DESC")";
    NOTES="$(localize "ARCHLINUX-ADD-REPO-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then  
    localize_info "ARCHLINUX-ADD-REPO-USAGE" "archlinux_add_repo 1->(repo-name) 2->(url) 3->(trust-level) 4->(1=add &#36;arch to url)" "Comment: archlinux_add_repo @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ARCHLINUX-ADD-REPO-DESC"  "archlinux_add_repo." "Comment: archlinux_add_repo @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ARCHLINUX-ADD-REPO-NOTES" "trust-level: Optional TrustAll, PackageRequired, Never" "Comment: archlinux_add_repo @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
archlinux_add_repo()
{
    if [[ "$#" -ne "4" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    #
    echo "cp -f /etc/pacman.conf /etc/pacman.bak";
    #
    echo "count=\$(egrep -ic \"\$1\" /etc/pacman.conf);";
    #
    echo "    sed -i '\$ a #'                  /etc/pacman.conf";
    echo "    sed -i \"\$ a [\${1}]\"          /etc/pacman.conf";
    echo "    sed -i \"\$ a SigLevel = \${3}\" /etc/pacman.conf";
    echo "    if [[ \"\$4\" -eq 1 ]]; then";
    echo "        sed -i \"\$ a Server = \${2}\\$arch\" /etc/pacman.conf";
    echo "    else";
    echo "        sed -i \"\$ a Server = \${2}\"       /etc/pacman.conf";
    echo "    fi";
    echo "fi";
    #
    echo "if [[ \"\$ARCHI\" == 'x86_64' ]]; then";
    echo "    multilib=\$(grep -n \"\\[multilib\\]\" /etc/pacman.conf | cut -f1 -d:);";
    echo "    if \$multilib &> /dev/null; then";
    echo "        echo -e \"\\n[multilib]\\nSigLevel = PackageRequired\\nInclude = /etc/pacman.d/mirrorlist\" >> /etc/pacman.conf";
    echo "    else";
    echo "        sed -i \"\${multilib}s/^#//\" /etc/pacman.conf";
    echo "        multilib=\$(( \$multilib + 1 ))";
    echo "        sed -i \"\${multilib}s/^#//\" /etc/pacman.conf";
    echo "        multilib=\$(( \$multilib + 1 ))";
    echo "        sed -i \"\${multilib}s/^#//\" /etc/pacman.conf";
    echo "    fi";
    echo "fi";
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL SCRIPT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install_script";
    USAGE="$(localize "DO-INSTALL-SCRIPT-USAGE")";
    DESCRIPTION="$(localize "DO-INSTALL-SCRIPT-DESC")";
    NOTES="$(localize "DO-INSTALL-SCRIPT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then  
    localize_info "DO-INSTALL-SCRIPT-USAGE" "do_install_script 1->(index) 2->(Install Type: 0=Not-Install, 1=Full-Install, 2=haproxy)" "Comment: do_install_script @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SCRIPT-DESC"  "Do Push Backup during Automated install." "Comment: do_install_script @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SCRIPT-NOTES" "Copy install script to the server." "Comment: do_install_script @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-SCRIPT-FCF" "Failed to Create Folder" "Comment: do_install_script @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_install_script()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    #echo "do_install_script start";
    local Install_Script_Path='';
    local Install_Script_Name="";
    if [[ "$2" -eq '1' ]]; then
        Install_Script_Path="${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-install.sh";         #
        Install_Script_Name="${Server_Names[$1]}-install.sh";
    elif [[ "$2" -eq '2' ]]; then
        Install_Script_Path="${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-haproxy-install.sh"; # 
        Install_Script_Name="${Server_Names[$1]}-haproxy-install.sh";
    else
        return 1;
    fi        
    if [ ! -f "$Install_Script_Path" ]; then
        print_error "DO-INSTALL-SCRIPT-FCF" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; # fix
    fi
    #
    print_this "MAIN-MENU-WORKING" "${Server_Names[$1]}";
    if is_online "${App_IPs[$1]}" ; then
        ssh -t -t "root@${App_IPs[$1]}" "mkdir -p \"${App_Paths[$1]}/Scripts/${Farm_Name}/\";chmod -R 755 \"${App_Paths[$1]}/Scripts/${Farm_Name}/\"; if [ -d \"${App_Paths[$1]}/Scripts/${Farm_Name}/\" ]; then echo '0'; else echo '1'; fi";
        if [ "$?" -ne 0 ]; then # you would have to keep track of each return to truly test for each error; this only shows the last; so I would make that a test
           print_error "DO-INSTALL-SCRIPT-FCF" "$1"; # fix
        fi
        #rsync -ave ssh -t -t "${Install_Script_Path}" "${User_Names[$1]}@${App_IPs[$1]}:${App_Paths[$1]}/Scripts/${Farm_Name}/";   
        scp -B "${Install_Script_Path}" "root@${App_IPs[$1]}:${App_Paths[$1]}/Scripts/${Farm_Name}/${Install_Script_Name}";  
        if [[ "$?" -eq 0 ]]; then
            print_this "MAIN-MENU-FARM-DONE" "${Server_Names[$1]}"; # fix
        else
            print_warning "MAIN-MENU-INSTALL-FAILED" "${App_IPs[$1]}"; # fix
            write_error "MAIN-MENU-INSTALL-FAILED" "${App_IPs[$1]} $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    else
        print_warning "MAIN-MENU-OFFLINE" "${App_IPs[$1]}"; # fix
        write_error "MAIN-MENU-OFFLINE" "${App_IPs[$1]}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    #echo "do_install_script end";
}
#}}}
# -----------------------------------------------------------------------------
# GET INSTALL TYPE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_install_type";
    USAGE=$(localize "GET-INSTALL-TYPE-USAGE");
    DESCRIPTION=$(localize "GET-INSTALL-TYPE-DESC");
    NOTES=$(localize "GET-INSTALL-TYPE-NOTES");
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then  
    localize_info "GET-INSTALL-TYPE-USAGE" "get_install_type 1->(index) 2->(Install Type: 1=Full-Install, 2=haproxy, 3=Not-Install)" "Comment: get_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INSTALL-TYPE-DESC"  "get_install_type." "Comment: get_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INSTALL-TYPE-NOTES" "" "Comment: get_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INSTALL-TYPE-FNF"   "File Not Found" "Comment: get_install_type @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_install_type()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    local -i isInstall=0; # is File Install
    local -i isHaproxy=0; # Is File haproxy
    local -i doInstall=0; # Do Install, else Do haproxy
    #
    if [ -f "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-install.sh" ]; then         isInstall=1; fi
    if [ -f "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-haproxy-install.sh" ]; then isHaproxy=1; fi
    #
    if [[ "$2" -eq 0 ]]; then
        echo 0; 
        return 0;
    elif [[ "$2" -eq 1 ]]; then
        if [[ "$isInstall" -eq 1 ]]; then
            echo 1; 
            return 1;
        else
            print_error "GET-INSTALL-TYPE-FNF" "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-install.sh";
        fi    
    elif [[ "$2" -eq 2 ]]; then
        if [[ "$isHaproxy" -eq 1 ]]; then
            echo 2; 
            return 2;
        else
            print_error "GET-INSTALL-TYPE-FNF" "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$1]}-haproxy-install.sh";
        fi    
    fi
    echo 0;
    return 0;
}
#}}}
# *****************************************************************************
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="main_menu";
    USAGE="main_menu";
    DESCRIPTION="$(localize "MAIN-MENU-DESC")";
    NOTES="$(localize "MAIN-MENU-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="10 Apr 2013";
    REVISION="10 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "MAIN-MENU-DESC"           "Main Menu for Witty Wizard" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-NOTES"          "Install Witty Wizard."      "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-TITLE"          "Witty Wizard Installation." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB"             "Install Witty Wizard."      "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FAILED"         "Failed !"                   "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-INSTALL-FAILED" "ssh Install Failed"         "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-WORKING"        "Working on"                 "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-OFFLINE"        "Offline"                    "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-STORAGE-ERR"    "Application Storage Missing" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-PUSH"      "Push Install, Update, Restore." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-PULL"      "Pull Backup will overwrite and possibly delete (if set) Storage Files" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-PULLIT"    "Pull Backup"                    "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-DONE"      "Completed"                      "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-INSTALL"   "Full Install and haproxy install files found, you must chose one of them for Server" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-NI"        "Not Installed" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-VD"        "Y = Install, N = haproxy install." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-FNF"       "File Not Found"                 "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM-REC"       "Number of Farms"                "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Menu Localization
    localize_info "MAIN-MENU-INFO-1"         "OS Information."            "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-INFO-2"         "Configuration Settings."    "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-FARM"           "Farm"                       "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    MyTotal=1;
    # Install Witty Wizard
    localize_info "MAIN-MENU-${MyTotal}"     "Create Scripts"                              "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Create Scripts: Create Install Scripts for Wt, Witty Wizard, Apache, EMail, Database or Custom App." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Witty Wizard Create Scripts." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # haproxy
    localize_info "MAIN-MENU-${MyTotal}"     "Create haproxy Scripts"                      "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Create haproxy Scripts: Create Install Scripts for haproxy." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Create haproxy Scripts Installation." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # SSH Key
    localize_info "MAIN-MENU-${MyTotal}"     "Install Scripts"                             "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Install Scripts: Install Scripts created above to all sites" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Install Scripts installed."        "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Push Master to Slave Server
    localize_info "MAIN-MENU-${MyTotal}"     "Push - Restore"                              "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Push: Push Master to Slave Server, Install, Update or Restore."  "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Restore Complete."                 "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Pull Slave to Master Server
    localize_info "MAIN-MENU-${MyTotal}"     "Pull - Backup"                               "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Pull: Pull from Slave to Master Server, as Backup." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Backup Complete."  "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Load Farm
    localize_info "MAIN-MENU-${MyTotal}"     "Load Farm"                            "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Load Farm: Pick a new Farm to Load." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Farm Loaded."               "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Configure Farm
    localize_info "MAIN-MENU-${MyTotal}"     "Configure Farm"                       "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Configure Farm: Menu to maintain Farm Database." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Farm Configured."           "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Update System
    localize_info "MAIN-MENU-${MyTotal}"     "Update System"                       "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Update System: Run Update, Upgrade and Cleanup commands on all servers." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Systems Updated."           "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Required_Wizard
    localize_info "MAIN-MENU-${MyTotal}"     "Required Applications"                "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Required Applications: Install Required Applications on Client." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Required Applications Installed" "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Clear Password
    localize_info "MAIN-MENU-${MyTotal}"     "Clear Password"                           "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Clear Password: Clears Password in Database to secure all Passwords." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Password Cleared"               "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    # Debug Mode
    localize_info "MAIN-MENU-${MyTotal}"     "Debug Mode"                           "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-I-${MyTotal}"         "Debug Mode: Sets a Var to allow more testing and pauses to help debug scripts." "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-MENU-SB-$((MyTotal++))"        "Debug Mode"                 "Comment: main_menu @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
main_menu()
{
    local -r menu_name="Main-Menu";  # You must define Menu Name here
    local Breakable_Key="Q";            # Q=Quit, D=Done, B=Back
    # No reason to save menu
    local OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important
    #local -a Menu_Checks=( $(load_array "${MENU_PATH}" "${menu_name}.db" 0 0 ) ); # Used to Persist Menu state | MENU_PATH is Global
    local -a Menu_Checks=( $(create_data_array 0 0 ) ); 
    IFS="$OLD_IFS";
    #
    local -i KIndex=0;
    #
    local Status_Bar_1="$(localize "MAIN-MENU-SB-1")";
    local Status_Bar_2='';
    #
    if [[ "$MyPassword" == "MyPassword" ]]; then
        get_my_password;
        save_default_config; 
    fi
    #
    while [[ 1 ]]; do
        #
        load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
        local -i total="${#Server_Names[@]}";
        if [[ "$total" -eq 0 ]]; then
            if [[ "$DEBUGGING" -eq 1 ]]; then
                set_farm_defaults;
            else
                farm_config;
            fi
        fi
        #
        print_title "MAIN-MENU-TITLE";
        print_caution "${Status_Bar_1}" "${Status_Bar_2}";
        # 
        print_warning "MAIN-MENU-FARM" ": $Farm_Name";
        #
        print_warning "MAIN-MENU-INFO-1"
        print_this "OS = ${My_OS} | Distribution = ${My_DIST} | Code Name = ${My_PSUEDONAME} | Version = ${My_Ver} (${My_Ver_Major}.${My_Ver_Minor}) ${BWhite} ";
        echo ""
        print_warning "MAIN-MENU-INFO-2"
        print_this "Master_UN                 = ${BWhite} ${Master_UN}                                 ${White}";
        print_this "EDITOR                    = ${BWhite} ${EDITOR}                                    ${White}";
        #
        local -a Menu_Items=(); local -a Menu_Info=(); RESET_MENU=1; # Reset        
        #
        local -i ThisMenuItem=1;
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 1
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 2
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 3
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 4
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 5
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 6
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 7
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 8
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 9
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 10
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "MAIN-MENU-$ThisMenuItem"  "" "" "MAIN-MENU-I-$ThisMenuItem" "MenuTheme[@]"; ((ThisMenuItem++)); # 11
        #
        print_menu "Menu_Items[@]" "Menu_Info[@]" "$Breakable_Key";
        #
        local SUB_OPTIONS="";        
        #
        read_input_options "$SUB_OPTIONS" "$Breakable_Key";
        SUB_OPTIONS=""; # Clear All previously entered Options so we do not repeat them
        #
        local S_OPT;
        for S_OPT in "${OPTIONS[@]}"; do
            case "$S_OPT" in
                1)  # Create Scripts
                    Menu_Checks[$((S_OPT - 1))]=1;
                    do_install;
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                2)  # haproxy
                    Menu_Checks[$((S_OPT - 1))]=1;
                    local -i CIndex=0;
                    local My_Install_Script_Name='';
                    make_dir "${CONFIG_PATH}/Scripts/${Farm_Name}/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    for (( CIndex=0; CIndex<total; CIndex++ )); do
                        My_Install_Script_Name="${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-haproxy-install.sh"; # Script per Domain
                        touch "$My_Install_Script_Name";
                        chmod 755 "$My_Install_Script_Name";
                        echo "# $DATE_TIME Created by Witty Wizard" > "${My_Install_Script_Name}";
                        echo "# Server:${Server_Names["$CIndex"]} | Name:${App_Names["$CIndex"]} | IP:${App_IPs["$CIndex"]}" >> "${My_Install_Script_Name}";
                        make_haproxy_monit "${My_Install_Script_Name}" "$CIndex";
                    done
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                3)  # Install Scripts
                    Menu_Checks[$((S_OPT - 1))]=1;
                    # if run it
                    read_input_yn "DO-INSTALL-INSTALL" " " 0;
                    if [[ "YN_OPTION" -eq 1 ]]; then
                        local -i total="${#App_Domains[@]}"; # total array count
                        local This_Install_Type=0;
                        local -i CIndex=0;
                        local -i isInstall=0; 
                        local -i isHaproxy=0;
                        local -i doInstall=0;
                        for (( CIndex=1; CIndex<total; CIndex++ )); do # @FIX
                            print_line;
                            unpack_bools "${PackedVars[$CIndex]}";
                            #                            
                            if [[ "${Create_Key[$CIndex]}" -eq 1 ]]; then
                                if key_website "${User_Names[$CIndex]}" "${App_IPs[$CIndex]}" "${Passwords[$CIndex]}" "${Root_Passwords[$CIndex]}" "${App_Paths[$CIndex]}" "${App_Folder[$CIndex]}" "${Create_User[$CIndex]}"; then 
                                    print_warning "FARM-CONFIG-KEY-PASS"; 
                                    Is_Keyed["$CIndex"]="1";
                                    save_farm;
                                    # fix save
                                else
                                    print_error "FARM-CONFIG-KEY-FAIL"; 
                                    pause_function "$(gettext -s 'FARM-CONFIG-KEY-FAIL')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                fi
                            fi
                            #
                            # FIX check to see if Wt is installed, stop it, stop monit, stop haproxy 
                            #
                            # Uploads all files
                            do_push "${Base_Storage_Path}/${App_Paths[$CIndex]}/" "${App_Paths[$CIndex]}/" "${User_Names[$CIndex]}" "${App_IPs[$CIndex]}" "${Server_Names[$CIndex]}" "${Rsync_Delete_Push[$CIndex]}" "1"
                            #                1                     2                        3                     4                      5                           6                          7
                            create_database "${Db_Type[$CIndex]}" "${User_Names[$CIndex]}" "${App_IPs[$CIndex]}" "${DB_Names[$CIndex]}" "${DB_User_Names[$CIndex]}" "${DB_Passwords[$CIndex]}" "${DB_Root_PW[$CIndex]}";
                            #
                            scp -B "${FULL_SCRIPT_PATH}/wthttpd.sh" "root@${App_IPs[$CIndex]}:${App_Paths[$CIndex]}/wthttpd.sh";  
                            if [[ "$?" -ne 0 ]]; then
                                print_this "INSTALL-APP-LINE-FAIL" "${Server_Names[$CIndex]} -> ${FULL_SCRIPT_PATH}/wthttpd.sh"; # fix
                            fi
                            #
                            local -i This_Install_Type=$(get_install_type "$CIndex" "${Install_Script_Type[$CIndex]}"); # 0=Not-Installed, 1=Full-Install, 2=haproxy
                            do_install_script "$CIndex" "${Install_Script_Type[$CIndex]}";
                            if [[ "$This_Install_Type" -eq 1 ]]; then
                                #ssh -t -t "root@${App_IPs["$CIndex"]}" 'bash -s' < "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-install.sh";
                                ssh -t -t "root@${App_IPs["$CIndex"]}" "${App_Paths[$CIndex]}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-install.sh $MyPassword";
                            elif [[ "$This_Install_Type" -eq 2 ]]; then
                                #ssh -t -t "root@${App_IPs["$CIndex"]}" 'bash -s' < "${CONFIG_PATH}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-haproxy-install.sh";
                                # @FIX make sure haproxy takes password parameter 
                                ssh -t -t "root@${App_IPs["$CIndex"]}" "${App_Paths[$CIndex]}/Scripts/${Farm_Name}/${Server_Names[$CIndex]}-haproxy-install.sh $MyPassword";
                            else
                                print_caution "MAIN-MENU-FARM-NI" "${Server_Names["$CIndex"]}";
                                continue; 
                            fi
                            if [[ "$?" -ne 0 ]]; then
                                print_error "MAIN-MENU-INSTALL-FAILED" "${Server_Names["$CIndex"]}";
                                write_error "MAIN-MENU-INSTALL-FAILED" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            fi
                        done
                    fi
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                4)  # Push Master to Slave Server: Upload, Restore
                    Menu_Checks[$((S_OPT - 1))]=1;
                    print_this "MAIN-MENU-FARM-PUSH" "...";
                    #
                    local -i i_Index=0;
                    for (( i_Index = 1 ; i_Index < ${#App_IPs[@]} ; i_Index++ )); do
                        unpack_bools "${PackedVars[$i_Index]}";
                        do_push "${Base_Storage_Path}/${App_Paths[$i_Index]}/" "${App_Paths[$i_Index]}/" "${User_Names[$i_Index]}" "${App_IPs[$i_Index]}" "${Server_Names[$i_Index]}" "${Rsync_Delete_Push[$i_Index]}" "${IncludePush[$i_Index]}"
                    done
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                5)  # Pull from Slave to Master Server: Backup
                    Menu_Checks[$((S_OPT - 1))]=1;
                    print_title "MAIN-MENU-FARM-PULL" "...";
                    #
                    local -i i_Index=0;
                    for (( i_Index = 1 ; i_Index < ${#App_IPs[@]} ; i_Index++ )); do
                        unpack_bools "${PackedVars[$i_Index]}";
                        if [[ "${IncludePull[$Current_Domain_Index]}" -eq 1 ]]; then
                            print_line;
                            print_this "MAIN-MENU-WORKING" "${Server_Names[$i_Index]}";
                            if [ ! -d "${Base_Storage_Path}/${App_Paths[$i_Index]}/" ]; then
                                print_warning "MAIN-MENU-STORAGE-ERR" "${Base_Storage_Path}/${App_Paths[$i_Index]}/ -> ${Server_Names[$i_Index]} -> ${App_IPs[$i_Index]}";
                                make_dir "${Base_Storage_Path}/${App_Paths[$i_Index]}/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            fi
                            # 0=None,1=SQlite,2=PostgreSql,3=MySql) 2->(User Name)      3->(IP Address)        4->(DB Name)            5->(Db User Name)           6->(Password)             7->(Base Destination Path) 8->(DB Full Path)
                            db_backup "${Db_Type[$i_Index]}" "${User_Names[$i_Index]}" "${App_IPs[$i_Index]}" "${DB_Names[$i_Index]}" "${DB_User_Names[$i_Index]}" "${DB_Passwords[$i_Index]}" "$Base_Storage_Path" "${DB_Full_Paths[$i_Index]}"; # Create Db Dump in backup path
                            #
                            if is_online "${App_IPs[$i_Index]}" ; then
                                #
                                if [[ "${Rsync_Delete_Pull[$i_Index]}" -eq 1 ]]; then
                                    rsync -av --delete -e ssh -t -t "${User_Names[$i_Index]}@${App_IPs[$i_Index]}:${App_Paths[$i_Index]}/" "${Base_Storage_Path}/${App_Paths[$i_Index]}/";
                                else
                                    rsync -av -e ssh -t -t "${User_Names[$i_Index]}@${App_IPs[$i_Index]}:${App_Paths[$i_Index]}/" "${Base_Storage_Path}/${App_Paths[$i_Index]}/";
                                fi
                                if [[ "$?" -eq 0 ]]; then
                                    print_this "MAIN-MENU-FARM-DONE" "${Server_Names[$i_Index]}";
                                else
                                    print_warning "MAIN-MENU-INSTALL-FAILED" "${App_IPs[$i_Index]}";
                                    write_error "MAIN-MENU-INSTALL-FAILED" "${App_IPs[$i_Index]}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                fi
                            else
                                print_warning "MAIN-MENU-OFFLINE" "${App_IPs[$i_Index]}";
                                write_error "MAIN-MENU-OFFLINE" "${App_IPs[$i_Index]}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            fi
                        fi # End Y Pull
                    done
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                6)  # Load Farm @FIX change farm
                    Menu_Checks[$((S_OPT - 1))]=1;
                    #
                    shopt -s dotglob
                    shopt -s nullglob
                    local -a FarmFolders=( "${CONFIG_PATH}/Scripts/"*/ );
                    local -i ff_total="${#FarmFolders[@]}";
                    local -i ff_counter=0;
                    for MyFarmName in "${FarmFolders[@]}"; do
                        MyFarmName=$(strip_trailing_char "$MyFarmName" '/');
                        FarmFolders[$((ff_counter++))]="${MyFarmName##*/}";
                    done
                    if [[ "$ff_total" -eq 1 ]]; then
                        OPTION=1;
                    elif [[ "$" -gt 1 ]]; then
                        if [[ "$ff_total" -gt 0 ]]; then
                            get_input_option "FarmFolders[@]" "1" 1; # FIX make 0 based
                        fi
                    else
                        break; # Nothing here to change to
                    fi
                    Farm_Name="${FarmFolders[$((OPTION-1))]}";
                    if [ -f "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" ]; then
                        load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
                    else
                        print_error "MAIN-MENU-FARM-FNF" "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db";
                    fi
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=$(echo $(localize "MAIN-MENU-FARM-REC") $ff_total);
                    ;;
                7)  # Farm Config
                    Menu_Checks[$((S_OPT - 1))]=1;
                    load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
                    farm_config;
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                8)  # update_system
                    Menu_Checks[$((S_OPT - 1))]=1;
                    for (( i_Index = 0 ; i_Index < ${#App_IPs[@]} ; i_Index++ )); do
                        update_system $(string_split "${Server_OS[$CIndex]}" ":" 2) 0 "${App_IPs[$i_Index]}"; # 1->(redhat,archlinux,debian) 2->(Use Single Command line to do updates) 3->(IP Address)
                    done
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                9)  # Required_Wizard
                    Menu_Checks[$((S_OPT - 1))]=1;
                    load_packages "${Server_OS[0]}" "${Install_Arch[$CIndex]}";               # 
                    eval $( package_type 0 "${Required_Wizard}" "${Server_OS[0]}" );
                    pause_function "" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
               10)  # Clear Password
                    Menu_Checks[$((S_OPT - 1))]=1;
                    MyPassword='MyPassword';
                    save_default_config;
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
               11)  # Debug Mode
                    Menu_Checks[$((S_OPT - 1))]=1;
                    if [[ "$DEBUGGING" -eq 1 ]]; then
                        DEBUGGING=0;
                    else
                        DEBUGGING=1;
                    fi
                    Status_Bar_1=$(localize "MAIN-MENU-SB-$S_OPT");
                    Status_Bar_2=": $S_OPT";
                    ;;
                *)  # Catch all
                    if [[ $(to_lower_case "$S_OPT") == $(to_lower_case "$Breakable_Key") ]]; then
                        if [ -n "$Master_UN" ]; then
                            chown -R "$Master_UN:$Master_UN" "${FULL_SCRIPT_PATH}"
                        fi
                        S_OPT="$Breakable_Key";
                        break;
                    fi
                    invalid_option "$S_OPT";
                    Status_Bar_1=$(localize "INVALID_OPTION");
                    ;;
            esac
        done
        is_breakable "$S_OPT" "$Breakable_Key";
    done
}
# -----------------------------------------------------------------------------
# FARM CONFIG {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="farm_config";
    USAGE="farm_config";
    DESCRIPTION="$(localize "FARM-CONFIG-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "FARM-CONFIG-DESC"  "Create/Edit Farm Configuration." "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "FARM-CONFIG-TITLE"  "Farm Configuration" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-INFO-1" "You must answer all the Questions." "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-INFO-2" "Farm Configuration" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-FIRST"  "Record 1 holds Local Machine Install" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-USER"   "to Create Account to hold Application, normally the same as the folder i.e. /home/USERNAME/." "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-SB"     "Choose Option" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "FARM-CONFIG-MENU-1"    "List Records" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-1-SB"        "Records Listed" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-2"    "Add Record" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-2-SB"        "Record Added" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-3"    "Edit Record" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-3-SB"        "Record Edited" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-4"    "Delete Record" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-4-SB"        "Record Deleted" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-5"    "Show Record" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-5-SB"        "Show Record" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-6"    "Test Records" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-MENU-6-SB"        "Test Records" "Comment: farm_config @ $(basename $BASH_SOURCE) : $LINENO";
    # test_Records
    localize_info "FARM-CONFIG-PING-PASS"  "PING Passed" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-PING-FAIL"  "PING Failed" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-IP-PASS"    "IP Address Passed" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-IP-FAIL"    "IP Address do not Match DNS for URL" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-KEY-PASS"   "SSH Key Passed" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FARM-CONFIG-KEY-FAIL"   "SSH Key Failed" "Comment: test_Records @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
farm_config()
{
    #
    local -r menu_name="FarmMenu";    # You must define Menu Name here
    local Breakable_Key="D";           # Q=Quit, D=Done, B=Back
    #
    OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
    local -a Menu_Checks=( $(create_data_array 0 0 ) );
    IFS="$OLD_IFS";
    #
    Status_Bar_1="FARM-CONFIG-SB";
    Status_Bar_2="";
    #
    # -----------------------------------
    #{{{
    # edit_Farm_Record 1->(Current_Domain_Index) 2->(Mode: 1=Add, 2=Edit (not used? @Fix) )
    edit_Farm_Record()
    {
        Current_Domain_Index="$1";
        local -i total="${#Server_Names[@]}"; # If 0 database is Blank and this is a New Record
        if [[ "$total" -eq 0 ]]; then
            print_title "FARM-CONFIG-FIRST";
            print_info "FARM-CONFIG-INFO-1";
            Current_Domain_Index=0;
            Server_Names["$Current_Domain_Index"]="localhost";
        else
            if [[ "$Current_Domain_Index" -eq 0 ]]; then
                Server_Names["$Current_Domain_Index"]="localhost";
            else
                # Get Server Name
                get_server_name;          # Server_Names["$Current_Domain_Index"]
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_server_name : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            fi
        fi
        # Server OS
        get_server_os;            # Server_OS["$Current_Domain_Index"]
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_server_os : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # App Name
        get_app_name;             # App_Names["$Current_Domain_Index"]
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_app_name : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # User Name
        if [[ "$total" -eq 0 ]]; then
            USERNAME="$(to_lower_case "$(whoami)")";
        else
            USERNAME="$(to_lower_case "${App_Names["$Current_Domain_Index"]}")";
        fi
        get_user_name "$(gettext -s "FARM-CONFIG-USER")";       # $USERNAME
        User_Names["$Current_Domain_Index"]="$USERNAME";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_user_name : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # User Password
        local -i p_total="${#Passwords[@]}";
        if [[ "$p_total" -eq 0 ]]; then
            USERPASSWD="$(random_password 16 0)";
        elif [[ "$Current_Domain_Index" -eq "$p_total" ]]; then # Add
            USERPASSWD="$(random_password 16 0)";
        else
            USERPASSWD="${Passwords["$Current_Domain_Index"]}";
        fi
        get_user_password;        # USERPASSWD
        Passwords["$Current_Domain_Index"]="$USERPASSWD";
        # Root Password 
        USERNAME="root";
        p_total="${#Root_Passwords[@]}";
        if [[ "$p_total" -eq 0 ]]; then
            USERPASSWD="$(random_password 16 0)";
        elif [[ "$Current_Domain_Index" -eq "$p_total" ]]; then # Add
            USERPASSWD="$(random_password 16 0)";
        else
            USERPASSWD="${Root_Passwords["$Current_Domain_Index"]}";
        fi
        get_user_password;        # USERPASSWD
        Root_Passwords["$Current_Domain_Index"]="$USERPASSWD";
        # App Domain
        get_domain;               # App_Domains["$Current_Domain_Index"]="$OPTION", App_IPs["$Current_Domain_Index"]="$OPTION" and App_Ports["$Current_Domain_Index"]="$OPTION"
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_domain : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # App Destination Path and Folder
        get_app_destination_root; # App_Paths["$Current_Domain_Index"] and App_Folder
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_app_destination_root : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Database Name, User Name, Password and Full Path
        get_db_name;              #  DB_Names, DB_User_Names, DB_Passwords, DB_Full_Paths["$Current_Domain_Index"]
        # Static Path for Resources
        get_static_path;           # Static_Path
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_static_path : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install Moses
        do_Install_Moses;         # Install_Moses
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_Moses : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install Wt
        do_install_wt;        # Install_Wt
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_install_wt : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install Witty Wizard Wt Application
        do_Install_wittywizard;   # Install_WittyWizard
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_wittywizard : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install or Remove Apache 
        do_install_apache;        # Install_Apache
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_install_apache : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install PostgreSQL
        do_Install_postgresql;    # Install_PostgreSQL
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_postgresql : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install SQLite
        do_Install_sqlite;        # Install_SQlite
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_sqlite : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install PDF
        do_install_pdf;     # Install_PDF
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_install_pdf : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install FTP
        do_Install_FTP;        # Install_FTP
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_FTP : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install Type
        do_install_type;        # Install_Type
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_install_type : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install from Repository
        do_repo_install;     # Repo_Install
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_repo_install : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Create User
        do_create_user;           # Create_User
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_create_user : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Create SSH Key
        do_create_key;            # Create_Key
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_create_key : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Use Delete in SSH rsync Push
        do_rsync_delete_push_pull;     # Rsync_Delete_Push
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_rsync_delete_push_pull : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install Monit
        do_Install_monit;         # Install_Monit
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_monit : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        # Install haproxy
        do_Install_haproxy;       # Install_HaProxy}
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "do_Install_haproxy : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        #
        save_farm;
    } 
    #}}}
    # -----------------------------------
    #{{{
    list_Records()
    {
        local -i total="${#Server_Names[@]}";  local -i c_Index=0;
        clear;
        print_line;
        local -i sn_Pad=5;    local -i an_Pad=5; local -i ad_Pad=5; local -i ai_Pad=5; local -i ap_Pad=5; 
        local -i aDest_Pad=5; local -i ar_Pad=5; local -i un_Pad=5; local -i dn_Pad=5; local -i os_Pad=5;
        for (( c_Index=0; c_Index<total; c_Index++ )); do
            if [[ "$(string_len "${Server_Names[$c_Index]}")"     -gt "${sn_Pad}" ]];    then sn_Pad="$(string_len "${Server_Names[$c_Index]}")"; fi
            if [[ "$(string_len "${App_Names[$c_Index]}")"        -gt "${an_Pad}" ]];    then an_Pad="$(string_len "${App_Names[$c_Index]}")";    fi
            if [[ "$(string_len "${App_Domains[$c_Index]}")"      -gt "${ad_Pad}" ]];    then ad_Pad="$(string_len "${App_Domains[$c_Index]}")";  fi
            if [[ "$(string_len "${App_IPs[$c_Index]}")"          -gt "${ai_Pad}" ]];    then ai_Pad="$(string_len "${App_IPs[$c_Index]}")";      fi
            if [[ "$(string_len "${App_Ports[$c_Index]}")"        -gt "${ap_Pad}" ]];    then ap_Pad="$(string_len "${App_Ports[$c_Index]}")";    fi
            if [[ "$(string_len "${App_Paths[$c_Index]}")"        -gt "${aDest_Pad}" ]]; then aDest_Pad="$(string_len "${App_Paths[$c_Index]}")"; fi
            if [[ "$(string_len "${App_Folder[$c_Index]}")"       -gt "${ar_Pad}" ]];    then ar_Pad="$(string_len "${App_Folder[$c_Index]}")";   fi
            if [[ "$(string_len "${User_Names[$c_Index]}")"       -gt "${un_Pad}" ]];    then un_Pad="$(string_len "${User_Names[$c_Index]}")";   fi
            if [[ "$(string_len "${DB_Names[$c_Index]}")"         -gt "${dn_Pad}" ]];    then dn_Pad="$(string_len "${DB_Names[$c_Index]}")";     fi
            #if [[ "$(string_len "${Server_OS[$c_Index]}")"        -gt "${os_Pad}" ]];    then os_Pad="$(string_len "${Server_OS[$c_Index]}")";    fi
            os_Pad=10;
        done
        printf "|   # | %-${sn_Pad}s | %-${an_Pad}s | %-${ad_Pad}s | %-${ai_Pad}s | %-${ap_Pad}s | %-${aDest_Pad}s | %-${ar_Pad}s | %-${un_Pad}s | %-${dn_Pad}s | %-${os_Pad}s | %-s\n" "Server" "Name" "Domain" "IP" "Port" "Destination" "Root" "User" "DB Name" "OS" "Type"; 
        print_line;
        for (( c_Index=0; c_Index<total; c_Index++ )); do 
            printf "| %3d | %-${sn_Pad}s | %-${an_Pad}s | %-${ad_Pad}s | %-${ai_Pad}s | %-${ap_Pad}s | %-${aDest_Pad}s | %-${ar_Pad}s | %-${un_Pad}s | %-${dn_Pad}s | %-${os_Pad}s | %-s\n" "$((c_Index+1))" "${Server_Names[$c_Index]}" "${App_Names[$c_Index]}" "${App_Domains[$c_Index]}" "${App_IPs[$c_Index]}" "${App_Ports[$c_Index]}" "${App_Paths[$c_Index]}" "${App_Folder[$c_Index]}" "${User_Names[$c_Index]}" "${DB_Names[$c_Index]}" "${Server_OS[$c_Index]:0:10}" "${Install_Types[${Install_Type[$c_Index]}]}"; 
        done | column
        pause_function "farm_config : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    }
    #}}}
    # -----------------------------------
    #{{{
    #
    show_Record()
    {
        Install_Script_Types=( "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-1")" "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-2")" "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-3")" );
        local -i total="${#Server_Names[@]}";  local -i c_Index=0;
        clear;
        print_line;
        echo "Server_Names        = ${Server_Names[$Current_Domain_Index]}";         #  0. Server Name: Default hostname
        echo "App_Names           = ${App_Names[$Current_Domain_Index]}";            #  1. Application Names
        echo "App_Domains         = ${App_Domains[$Current_Domain_Index]}";          #  2. Web Domain Name: url.tdl
        echo "App_IPs             = ${App_IPs[$Current_Domain_Index]}";              #  3. Web IP Address: 0.0.0.0
        echo "App_Ports           = ${App_Ports[$Current_Domain_Index]}";            #  4. Application Starting Port
        echo "App_Paths           = ${App_Paths[$Current_Domain_Index]}";            #  5. Application Path: /home/UserName ~/ or Root
        echo "App_Folder          = ${App_Folder[$Current_Domain_Index]}";           #  6. Application Root: /home/UserName/public
        echo "User_Names          = ${User_Names[$Current_Domain_Index]}";           #  7. User Name
        echo "Passwords           = ${Passwords[$Current_Domain_Index]}";            #  8. Password
        echo "Root_Passwords      = ${Root_Passwords[$Current_Domain_Index]}";       #  9. Root Password
        echo "Db_Type             = ${Db_Types[${Db_Type[$Current_Domain_Index]}]}";            # 10. Database Types: 0=None,1=SQlite,2=PostgreSql,3=MySql
        echo "DB_Names            = ${DB_Names[$Current_Domain_Index]}";             # 11. Database Name
        echo "DB_Root_PW          = ${DB_Root_PW[$Current_Domain_Index]}";           # 12. Database Password
        echo "DB_User_Names       = ${DB_User_Names[$Current_Domain_Index]}";        # 13. Database User Name
        echo "DB_Passwords        = ${DB_Passwords[$Current_Domain_Index]}";         # 14. Database Password
        echo "DB_Full_Paths       = ${DB_Full_Paths[$Current_Domain_Index]}";        # 15. Database Full Path
        echo "Server_OS           = ${Server_OS[$Current_Domain_Index]}";            # 16. Server OS, used to set the OS for Server Install
        echo "Static_Path         = ${Static_Path[$Current_Domain_Index]}";          # 17. Static Path: resources, static, media - media.domain.com; where static content is located
        echo "Install_Apache      = ${Install_Apache[$Current_Domain_Index]}";       # 18. If no, then Remove Apache
        echo "Install_Wt          = ${Install_Wt[$Current_Domain_Index]}";           # 19. If no, then do nothing
        echo "Install_WittyWizard = ${Install_WittyWizard[$Current_Domain_Index]}";  # 20. 1=True, else install Custom Application
        echo "Install_PostgreSQL  = ${Install_PostgreSQL[$Current_Domain_Index]}";   # 21. Install PostgreSQL
        echo "Install_SQlite      = ${Install_SQlite[$Current_Domain_Index]}";       # 22. Install SQlite
        echo "Install_HaProxy     = ${Install_HaProxy[$Current_Domain_Index]}";      # 23. Install HaProxy
        echo "Install_Monit       = ${Install_Monit[$Current_Domain_Index]}";        # 24. Install Monit
        echo "Install_FTP         = ${Install_FTP[$Current_Domain_Index]}";          # 25. Install FTP
        echo "Install_PDF         = ${Install_PDF[$Current_Domain_Index]}";          # 26. 1=True install haru
        echo "Install_Moses       = ${Install_Moses[$Current_Domain_Index]}";        # 27. Install Moses: This is only for the Master Server
        echo "Install_Arch        = $( [[ "${Install_Arch[$Current_Domain_Index]}" -eq 1 ]] && echo '64 bit' || echo '32 bit' )";  # 28. 1=x64 | 0=x32
        echo "Install_Type        = ${Install_Types[${Install_Type[$Current_Domain_Index]}]}"; # 29. Install Type: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
        echo "Create_User         = ${Create_User[$Current_Domain_Index]}";          # 30. Create User
        echo "Create_Key          = ${Create_Key[$Current_Domain_Index]}";           # 31. Create ssh Key
        echo "Rsync_Delete_Push   = ${Rsync_Delete_Push[$Current_Domain_Index]}";    # 32. rsynce --delete 
        echo "IncludePush         = ${IncludePush[$Current_Domain_Index]}";          # 33. Include in Auto Push
        echo "Rsync_Delete_Pull   = ${Rsync_Delete_Pull[$Current_Domain_Index]}";    # 34. rsynce --delete 
        echo "IncludePull         = ${IncludePull[$Current_Domain_Index]}";          # 35. Include in Auto Pull
        echo "Repo_Install        = ${Repo_Install[$Current_Domain_Index]}";         # 36. Repository Install = 1, Compile = 0
        echo "Is_Keyed            = ${Is_Keyed[$Current_Domain_Index]}";             # 37. Is SSH Key installed
        echo "Server_Threads      = ${Server_Threads[$Current_Domain_Index]}";       # 38. Number of HTTP Servers or Threads you run on each IP
        echo "Is_WWW              = ${Is_WWW[$Current_Domain_Index]}";               # 39. If www.domain.com
        echo "Global_Maxconn      = ${Global_Maxconn[$Current_Domain_Index]}";       # 40. Global maxconn
        echo "Default_Maxconn     = ${Default_Maxconn[$Current_Domain_Index]}";      # 41. Global maxconn
        echo "Install_Script_Type = ${Install_Script_Types[${Install_Script_Type[$Current_Domain_Index]}]}"; # 42. 0=Not-Installed, 1=Full-Install, 2=haproxy
        echo "FTP_Server          = ${FTP_Servers[${FTP_Server[$Current_Domain_Index]}]}";     # 43. FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
        echo "HA_User_Names       = ${HA_User_Names[$Current_Domain_Index]}";        # 44. haproxy stats access User Name
        echo "HA_Passwords        = ${HA_Passwords[$Current_Domain_Index]}";         # 45. haproxy stats access Password
        echo "PackedVars          = ${PackedVars[$Current_Domain_Index]}";           # 46. Packed Vars: IncludePush=1:IncludePull=0
        pause_function "$(gettext -s 'FARM-CONFIG-MENU-5')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        print_line;
    }
    #}}}
    # -----------------------------------
    #{{{
    #
    test_Records()
    {
        local -i total="${#Server_Names[@]}";  local -i c_Index=0;
        clear;
        print_line;
        local -i sn_Pad=5;    local -i an_Pad=5; local -i ad_Pad=5; local -i ai_Pad=5; local -i ap_Pad=5; 
        local -i aDest_Pad=5; local -i ar_Pad=5; local -i un_Pad=5; local -i dn_Pad=5; local -i os_Pad=5;
        for (( c_Index=0; c_Index<total; c_Index++ )); do
            if [[ "$(string_len "${Server_Names[$c_Index]}")" -gt "${sn_Pad}" ]];    then sn_Pad="$(string_len "${Server_Names[$c_Index]}")"; fi
            if [[ "$(string_len "${App_Names[$c_Index]}")"    -gt "${an_Pad}" ]];    then an_Pad="$(string_len "${App_Names[$c_Index]}")";    fi
            if [[ "$(string_len "${App_Domains[$c_Index]}")"  -gt "${ad_Pad}" ]];    then ad_Pad="$(string_len "${App_Domains[$c_Index]}")";  fi
            if [[ "$(string_len "${App_IPs[$c_Index]}")"      -gt "${ai_Pad}" ]];    then ai_Pad="$(string_len "${App_IPs[$c_Index]}")";      fi
            if [[ "$(string_len "${App_Ports[$c_Index]}")"    -gt "${ap_Pad}" ]];    then ap_Pad="$(string_len "${App_Ports[$c_Index]}")";    fi
            if [[ "$(string_len "${App_Paths[$c_Index]}")"    -gt "${aDest_Pad}" ]]; then aDest_Pad="$(string_len "${App_Paths[$c_Index]}")"; fi
            if [[ "$(string_len "${App_Folder[$c_Index]}")"   -gt "${ar_Pad}" ]];    then ar_Pad="$(string_len "${App_Folder[$c_Index]}")";   fi
            if [[ "$(string_len "${User_Names[$c_Index]}")"   -gt "${un_Pad}" ]];    then un_Pad="$(string_len "${User_Names[$c_Index]}")";   fi
            if [[ "$(string_len "${DB_Names[$c_Index]}")"     -gt "${dn_Pad}" ]];    then dn_Pad="$(string_len "${DB_Names[$c_Index]}")";     fi
            #if [[ "$(string_len "${Server_OS[$c_Index]}")"     -gt "${os_Pad}" ]];    then os_Pad="$(string_len "${Server_OS[$c_Index]}")";    fi
            os_Pad=10;
        done
        printf "|   # | %-${sn_Pad}s | %-${an_Pad}s | %-${ad_Pad}s | %-${ai_Pad}s | %-${ap_Pad}s | %-${aDest_Pad}s | %-${ar_Pad}s | %-${un_Pad}s | %-${dn_Pad}s | %-${os_Pad}s | %-s\n" "Server" "Name" "Domain" "IP" "Port" "Destination" "Root" "User" "DB Name" "OS" "Type"; 
        print_line;
        for (( c_Index=1; c_Index<total; c_Index++ )); do 
            printf "| %3d | %-${sn_Pad}s | %-${an_Pad}s | %-${ad_Pad}s | %-${ai_Pad}s | %-${ap_Pad}s | %-${aDest_Pad}s | %-${ar_Pad}s | %-${un_Pad}s | %-${dn_Pad}s | %-${os_Pad}s | %-s\n" "$((c_Index+1))" "${Server_Names[$c_Index]}" "${App_Names[$c_Index]}" "${App_Domains[$c_Index]}" "${App_IPs[$c_Index]}" "${App_Ports[$c_Index]}" "${App_Paths[$c_Index]}" "${App_Folder[$c_Index]}" "${User_Names[$c_Index]}" "${DB_Names[$c_Index]}" "${Server_OS[$c_Index]:0:10}" "${Install_Types[${Install_Type[$c_Index]}]}"; 
            # Ping it
            if is_online "${App_Domains[$c_Index]}" ; then
                print_warning "FARM-CONFIG-PING-PASS" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$(get_ip_from_url "${App_Domains[$c_Index]}")" == "${App_IPs[$c_Index]}" ]]; then
                    print_warning "FARM-CONFIG-IP-PASS" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                else                
                    if [[ "${App_Domains[$c_Index]}" == 'localhost' && "$(get_ip_from_url "${App_Domains[$c_Index]}")" == "127.0.0.1" ]]; then
                        print_warning "FARM-CONFIG-IP-PASS" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    else
                        print_warning "FARM-CONFIG-IP-FAIL" "$FUNCNAME [${App_Domains[$c_Index]} = ${App_IPs[$c_Index]} ~ ${App_Domains[$c_Index]} > $(get_ip_from_url "${App_Domains[$c_Index]}")] @ $(basename $BASH_SOURCE) : $LINENO";
                        pause_function "$(gettext -s 'FARM-CONFIG-IP-FAIL')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    fi
                fi
            else
                print_error "FARM-CONFIG-PING-FAIL" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "$(gettext -s 'FARM-CONFIG-PING-FAIL')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
            # Key it
            if [[ "${Create_Key["$c_Index"]}" -eq 1 ]]; then
                if key_website "${User_Names[$c_Index]}" "${App_IPs[$c_Index]}" "${Passwords[$c_Index]}" "${Root_Passwords[$c_Index]}" "${App_Paths[$c_Index]}" "${App_Folder[$c_Index]}" "${Create_User[$c_Index]}"; then 
                    print_warning "FARM-CONFIG-KEY-PASS"; 
                    Is_Keyed["$c_Index"]="1";
                    save_farm;
                    # fix save
                else
                    print_error "FARM-CONFIG-KEY-FAIL"; 
                    pause_function "$(gettext -s 'FARM-CONFIG-KEY-FAIL')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                fi
            fi
            # test MySQL and Postgree Database
        done 
        pause_function "$(gettext -s 'FARM-CONFIG-MENU-6')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    }
    #}}}
    # -----------------------------------
    #{{{
    pick_Record()
    {
        print_line;
        select MyServer in "${Server_Names[@]}"; do
            if contains_element "$MyServer" "${Server_Names[@]}"; then
              if is_in_array "Server_Names[@]" "$MyServer" ; then
                Current_Domain_Index="$ARR_INDEX";
              else
                print_error "Error in Array";
              fi
              break;
            else
              invalid_option "$REPLY";
            fi
        done
    }
    #}}}
    # -----------------------------------
    # Set Localized List of Install Types
    Install_Types=( "$(gettext -s 'DO-INSTALL-TYPES-0')" "$(gettext -s 'DO-INSTALL-TYPES-1')" "$(gettext -s 'DO-INSTALL-TYPES-2')" "$(gettext -s 'DO-INSTALL-TYPES-3')" "$(gettext -s 'DO-INSTALL-TYPES-4')" "$(gettext -s 'DO-INSTALL-TYPES-5')" "$(gettext -s 'DO-INSTALL-TYPES-6')" );
    #
    local -i total_Records="${#Server_Names[@]}"; # if 0 its a blank database
    #
    if [[ "$total_Records" -eq 0 ]]; then
        print_title "FARM-CONFIG-FIRST";
        Current_Domain_Index=0;
        edit_Farm_Record "$Current_Domain_Index" 1; # Current_Domain_Index = 0, Add Record before Starting Menu
    fi
    #
    while [[ 1 ]]; do
        # 
        load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword"; # Load Farm
        #
        total_Records="${#Server_Names[@]}"; # if 0 its a blank database
        #
        print_title "FARM-CONFIG-TITLE";
        print_info "FARM-CONFIG-INFO-2";
        print_caution "${Status_Bar_1}" "${Status_Bar_2}";
        #
        local -a Menu_Items=(); local -a Menu_Info=(); RESET_MENU=1; # Reset
        local -i ThisMenuItem=1;
        #
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 1
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 2
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 3
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 4
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 5
        add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "FARM-CONFIG-MENU-$ThisMenuItem" "" "" ""  "MenuTheme[@]"; ((ThisMenuItem++)); # 6
        #
        print_menu "Menu_Items[@]" "Menu_Info[@]" "$Breakable_Key";
        #
        read_input_options " " "$Breakable_Key";
        #            
        for S_OPT in "${OPTIONS[@]}"; do
            case "$S_OPT" in
                1)  # List Records
                    Menu_Checks[$((S_OPT - 1))]=1;
                    list_Records;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                2)  # Add Record
                    Menu_Checks[$((S_OPT - 1))]=1;
                    edit_Farm_Record $((total_Records)) 1;
                    #
                    load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
                    list_Records;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                3)  # Edit Record
                    Menu_Checks[$((S_OPT - 1))]=1;
                    pick_Record;
                    edit_Farm_Record "$Current_Domain_Index" 2;
                    #
                    load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
                    list_Records;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                4)  # Delete Record
                    Menu_Checks[$((S_OPT - 1))]=1;
                    pick_Record;
                    Current_Domain_Index="$((Current_Domain_Index+1))";
                    sed -i "${Current_Domain_Index}"'d' "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db";
                    #cat "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" | sed -e "$Current_Domain_Index"'d' > "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db";
                    #
                    load_farm "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db" "$MyPassword";
                    list_Records;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                5)  # show_Record
                    Menu_Checks[$((S_OPT - 1))]=1;
                    pick_Record;
                    show_Record;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                6)  # Test Records
                    Menu_Checks[$((S_OPT - 1))]=1;
                    test_Records;
                    Status_Bar_1=$(localize "FARM-CONFIG-MENU-${S_OPT}-SB");
                    Status_Bar_2="";
                    ;;
                *)  # Not programmed key
                    if [[ "$S_OPT" == $(to_lower_case "$Breakable_Key") ]]; then
                        S_OPT="$Breakable_Key";
                        break;
                    else
                        invalid_option "$S_OPT";
                    fi
                    ;;
            esac
        done
        is_breakable "$S_OPT" "$Breakable_Key";
    done
}
#}}}

# -----------------------------------------------------------------------------
# SET FARM DEFAULTS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="set_farm_defaults";
    USAGE="set_farm_defaults";
    DESCRIPTION="$(localize "SET-FARM-DEFAULTS")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SET-FARM-DEFAULTS"  "Save Farm Database." "Comment: set_farm_defaults @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
set_farm_defaults()
{
    Server_Names=();         #  0. Server Name: Default hostname
    App_Names=();            #  1. Application Names
    App_Domains=();          #  2. Web Domain Name: url.tdl
    App_IPs=();              #  3. Web IP Address: 0.0.0.0
    App_Ports=();            #  4. Application Starting Port
    App_Paths=();            #  5. Application Path: /home/UserName ~/ or Root
    App_Folder=();           #  6. Application Root: /home/UserName/public
    User_Names=();           #  7. User Name
    Passwords=();            #  8. Password
    Root_Passwords=();       #  9. Root Password
    Db_Type=();              # 10. Database Types: 0=None,1=SQlite,2=PostgreSql,3=MySql
    DB_Names=();             # 11. Database Name
    DB_Root_PW=();           # 12. Database root Password
    DB_User_Names=();        # 13. Database User Name
    DB_Passwords=();         # 14. Database Password
    DB_Full_Paths=();        # 15. Database Full Path
    Server_OS=();            # 16. Server OS, used to set the OS for Server Install
    Static_Path=();          # 17. Static Path: resources, static, media - media.domain.com; where static content is located
    Install_Apache=();       # 18. If no, then Remove Apache
    Install_Wt=();           # 19. If no, then do nothing
    Install_WittyWizard=();  # 20. 1=True, else install Custom Application
    Install_PostgreSQL=();   # 21. Install PostgreSQL
    Install_SQlite=();       # 22. Install SQlite
    Install_HaProxy=();      # 23. Install HaProxy
    Install_Monit=();        # 24. Install Monit
    Install_FTP=();          # 25. Install FTP
    Install_PDF=();          # 26. 1=True install haru
    Install_Moses=();        # 27. Install Moses: This is only for the Master Server
    Install_Arch=();         # 28. 1=x64 | 0=x32
    Install_Type=();         # 29. Install Type: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
    Create_User=();          # 30. Create User
    Create_Key=();           # 31. Create ssh Key
    Rsync_Delete_Push=();    # 32. rsynce --delete 
    IncludePush=();          # 33. Include in Auto Push
    Rsync_Delete_Pull=();    # 34. rsynce --delete 
    IncludePull=();          # 35. Include in Auto Pull
    Repo_Install=();         # 36. Repository Install = 1, Compile = 0
    Is_Keyed=();             # 37. Is SSH Key installed
    Server_Threads=();       # 38. Number of HTTP Servers or Threads you run on each IP
    Is_WWW=();               # 39. If www.domain.com
    Global_Maxconn=();       # 40. Global maxconn
    Default_Maxconn=();      # 41. Global maxconn
    Install_Script_Types=(); # 42. 0=Not-Installed, 1=Full-Install, 2=haproxy
    FTP_Server=();           # 43. FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
    HA_User_Names=();        # 44. haproxy stats access User Name
    HA_Passwords=();         # 45. haproxy stats access Password
    PackedVars=();           # 46. Packed Vars: IncludePush=1:IncludePull=0

    Server_Names[0]='localhost';
    App_Names[0]='WittyWizard';
    App_Domains[0]='mydomain.com';
    App_IPs[0]='0.0.0.0';
    App_Ports[0]='8080';
    App_Paths[0]='/home/mydomain';
    App_Folder[0]='public';
    User_Names[0]='wittywizard';
    Passwords[0]='PasswordWittyWizard';
    Root_Passwords[0]='RootPasswordWittyWizard';
    Db_Type[0]='0';
    DB_Names[0]='wittywizard';
    DB_Root_PW[0]='DbRootPasswordWittyWizard';
    DB_User_Names[0]='DbUserNameWittyWizard';
    DB_Passwords[0]='DbPasswordWittyWizard';
    DB_Full_Paths[0]='/home/mydomain/database';
    Server_OS[0]='linux:debian:LMDE:lmde:0';
    Static_Path[0]='resources';
    Install_Apache[0]='0';
    Install_Wt[0]='0';
    Install_WittyWizard[0]='0';
    Install_PostgreSQL[0]='0';
    Install_SQlite[0]='0';
    Install_HaProxy[0]='0';
    Install_Monit[0]='0';
    Install_FTP[0]='0';
    Install_PDF[0]='0';
    Install_Moses[0]='0';
    Install_Arch[0]='0';
    Install_Type[0]='0';
    Create_User[0]='0';
    Create_Key[0]='0';
    Rsync_Delete_Push[0]='0';
    IncludePush[0]='0';
    Rsync_Delete_Pull[0]='0';
    IncludePull[0]='0';
    Repo_Install[0]='0';
    Is_Keyed[0]='0';
    Server_Threads[0]='1';
    Is_WWW[0]='1';
    Global_Maxconn[0]='4096';
    Default_Maxconn[0]='2048';
    Install_Script_Types[0]='0';
    FTP_Server[0]='0';
    HA_User_Names[0]='admin';
    HA_Passwords[0]='HaPasswordWittyWizard';
    PackedVars[0]='MyVar=0:MyNextVar=1';
    #
    Server_Names[1]='vps-wo';
    App_Names[1]='WittyWizard';
    App_Domains[1]='domain.com';
    App_IPs[1]='192.168.0.1';
    App_Ports[1]='9090';
    App_Paths[1]='/home/domain';
    App_Folder[1]='public';
    User_Names[1]='binarybitflesh';
    Passwords[1]='PasswordBinaryBitFlesh';
    Root_Passwords[1]='RootPasswordBinaryBitFlesh';
    Db_Type[1]='0';
    DB_Names[1]='BinaryBitFlesh';
    DB_Root_PW[1]='DbRootPasswordBinaryBitFlesh';
    DB_User_Names[1]='DbUserNameBinaryBitFlesh';
    DB_Passwords[1]='DbPasswordBinaryBitFlesh';
    DB_Full_Paths[1]='/home/domain/database';
    Server_OS[1]='linux:debian:LMDE:lmde:0';
    Static_Path[1]='resources';
    Install_Apache[1]='0';
    Install_Wt[1]='0';
    Install_WittyWizard[1]='0';
    Install_PostgreSQL[1]='0';
    Install_SQlite[1]='0';
    Install_HaProxy[1]='0';
    Install_Monit[1]='0';
    Install_FTP[1]='0';
    Install_PDF[1]='0';
    Install_Moses[1]='0';
    Install_Arch[1]='0';
    Install_Type[1]='0';
    Create_User[1]='0';
    Create_Key[1]='0';
    Rsync_Delete_Push[1]='0';
    IncludePush[1]='0';
    Rsync_Delete_Pull[1]='0';
    IncludePull[1]='0';
    Repo_Install[1]='0';
    Is_Keyed[1]='0';
    Server_Threads[1]='1';
    Is_WWW[1]='1';
    Global_Maxconn[1]='4096';
    Default_Maxconn[1]='2048';
    Install_Script_Types[1]='1';
    FTP_Server[1]='0';
    HA_User_Names[1]='admin';
    HA_Passwords[1]='HaPasswordBinaryBitFlesh';
    PackedVars[1]='MyVar=0:MyNextVar=1';

    save_farm;
}
# -----------------------------------------------------------------------------
# SAVE FARM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="save_farm";
    USAGE="save_farm";
    DESCRIPTION="$(localize "SAVE-FARM-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SAVE-FARM-DESC"  "Save Farm Database." "Comment: save_farm @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
save_farm()
{
    local OLD_IFS="$IFS"; IFS=$' '; # Very Important
    local -i this_index=0;
    local -i v_index=0;
    #
    touch "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db";
    local -i total="${#Server_Names[@]}"; 
    #
    local -i i_total=0;
    local MyValue='';
    local MyVarName='';
    #
    local -i VTotal="${#MySaveVars[@]}"; 
    echo "#" > "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db"
    #
    for (( v_index=0; v_index<VTotal; v_index++ )); do  # Iterate Array
        #
        MyVarName="${MySaveVars[$v_index]}";
        echo "${MyVarName}=();" >> "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db"; # MyVar=();
        #
        for (( this_index=0; this_index<total; this_index++ )); do  # Iterate Array
            if   [[ "$MyVarName" == 'User_Names' ]]; then
                MyValue=$(password_safe "${User_Names[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'Passwords' ]]; then
                MyValue=$(password_safe "${Passwords[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'Root_Passwords' ]]; then
                MyValue=$(password_safe "${Root_Passwords[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'DB_User_Names' ]]; then
                MyValue=$(password_safe "${DB_User_Names[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'DB_Passwords' ]]; then
                MyValue=$(password_safe "${DB_Passwords[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'DB_Root_PW' ]]; then
                MyValue=$(password_safe "${DB_Root_PW[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'HA_User_Names' ]]; then
                MyValue=$(password_safe "${HA_User_Names[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'HA_Passwords' ]]; then
                MyValue=$(password_safe "${HA_Passwords[$this_index]}" "$MyPassword" 'encrypt');
            elif [[ "$MyVarName" == 'App_Paths' ]]; then
                # Ensure it does not ends with a slash / 
                App_Paths[$this_index]=$(strip_trailing_char "${App_Paths[$this_index]}" "/");
                MyValue=$(strip_trailing_char "${App_Paths[$this_index]}" "/");
            elif [[ "$MyVarName" == 'App_Folder' ]]; then
                # Ensure it does not start with a slash / 
                App_Folder[$this_index]=$(strip_leading_char "${App_Folder[$this_index]}" "/");
                MyValue=$(strip_leading_char "${App_Folder[$this_index]}" "/");
            elif [[ "$MyVarName" == 'Is_Keyed' ]]; then
                i_total="${#Is_Keyed[@]}";
                if [[ "$i_total" -eq 0 || "$this_index" -eq "$i_total" ]]; then
                    Is_Keyed["$this_index"]=0; # Make sure Is_Keyed is set
                fi 
                MyValue="${Is_Keyed[$this_index]}";
            else            
                eval "MyValue=\${$MyVarName[$this_index]}";
            fi
            echo "${MyVarName}[$this_index]=\"${MyValue}\";" >> "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-farm.db"; # MyVar[0]="This";
        done
    done
} 
#}}}
# -----------------------------------------------------------------------------
# LOAD FARM  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="load_farm";
    USAGE="$(localize "LOAD-FARM-USAGE")";
    DESCRIPTION="$(localize "LOAD-FARM-DESC")";
    NOTES="$(localize "LOAD-FARM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "LOAD-FARM-USAGE"  "load_farm 1->(/Full/Path/My-farm.db) 2->(Password)" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-FARM-DESC"   "Load Farm" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-FARM-NOTES"  "x-farm.db format starting at 1: 1->(Server_Names) 2->(App_Names) 3->(App_Domains) 4->(App_IPs) 5->(App_Ports) 6->(App_Paths) 7->(App_Folder) 8->(User_Names) 9->(Passwords) 10->(Root_Passwords) 11->(Db_Type) 12->(DB_Names) 13->(DB_Root_PW) 14->(DB_User_Names) 15->(DB_Passwords) 16->(DB_Full_Paths) 17->(Server_OS) 18->(Static_Path) 19->(Install_Apache) 20->(Install_Wt) 21->(Install_WittyWizard) 22->(Install_PostgreSQL) 23->(Install_SQlite) 24->(Install_HaProxy) 25->(Install_Monit) 26->(Install_FTP) 27->(Install_PDF) 28->(Install_Moses) 29->(Install_Arch) 30->(Install_Type) 31->(Create_User) 32->(Create_Key) 33->(Rsync_Delete_Push) 34->(IncludePush) 35->(Rsync_Delete_Pull) 36->(IncludePull) 37->(Repo_Install) 38->(Is_Keyed) 39->(Server_Threads) 40->(Is_WWW) 41->(Global_Maxconn) 42->(Default_Maxconn) 43->(Install_Script_Type) 44->(FTP_Server) 45->(HA_User_Names) 46->(HA_Passwords) 47->(PackedVars)" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "LOAD-FARM-TITLE"  "Load Farm" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-FARM-LOAD"   "Loading" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-FARM-MF"     "Missing file" "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
    
    #
    localize_info "LOAD-FARM-MP"  "Missing Parameter"     "Comment: load_farm @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
#
load_farm()
{
    local OLD_IFS="$IFS"; IFS=$' '; # Very Important
    #
    Server_Names=();         #  0. Server Name: Default hostname
    App_Names=();            #  1. Application Names
    App_Domains=();          #  2. Web Domain Name: url.tdl
    App_IPs=();              #  3. Web IP Address: 0.0.0.0
    App_Ports=();            #  4. Application Starting Port
    App_Paths=();            #  5. Application Path: /home/UserName ~/ or Root
    App_Folder=();           #  6. Application Root: /home/UserName/public
    User_Names=();           #  7. User Name
    Passwords=();            #  8. Password
    Root_Passwords=();       #  9. Root Password
    Db_Type=();              # 10. Database Types: 0=None,1=SQlite,2=PostgreSql,3=MySql
    DB_Names=();             # 11. Database Name
    DB_Root_PW=();           # 12. Database root Password
    DB_User_Names=();        # 13. Database User Name
    DB_Passwords=();         # 14. Database Password
    DB_Full_Paths=();        # 15. Database Full Path
    Server_OS=();            # 16. Server OS, used to set the OS for Server Install
    Static_Path=();          # 17. Static Path: resources, static, media - media.domain.com; where static content is located
    Install_Apache=();       # 18. If no, then Remove Apache
    Install_Wt=();           # 19. If no, then do nothing
    Install_WittyWizard=();  # 20. 1=True, else install Custom Application
    Install_PostgreSQL=();   # 21. Install PostgreSQL
    Install_SQlite=();       # 22. Install SQlite
    Install_HaProxy=();      # 23. Install HaProxy
    Install_Monit=();        # 24. Install Monit
    Install_FTP=();          # 25. Install FTP
    Install_PDF=();          # 26. 1=True install haru
    Install_Moses=();        # 27. Install Moses: This is only for the Master Server
    Install_Arch=();         # 28. 1=x64 | 0=x32
    Install_Type=();         # 29. Install Type: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL
    Create_User=();          # 30. Create User
    Create_Key=();           # 31. Create ssh Key
    Rsync_Delete_Push=();    # 32. rsynce --delete 
    IncludePush=();          # 33. Include in Auto Push
    Rsync_Delete_Pull=();    # 34. rsynce --delete 
    IncludePull=();          # 35. Include in Auto Pull
    Repo_Install=();         # 36. Repository Install = 1, Compile = 0
    Is_Keyed=();             # 37. Is SSH Key installed
    Server_Threads=();       # 38. Number of HTTP Servers or Threads you run on each IP
    Is_WWW=();               # 39. If www.domain.com
    Global_Maxconn=();       # 40. Global maxconn
    Default_Maxconn=();      # 41. Global maxconn
    Install_Script_Types=(); # 42. 0=Not-Installed, 1=Full-Install, 2=haproxy
    FTP_Server=();           # 43. FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
    HA_User_Names=();        # 44. haproxy stats access User Name
    HA_Passwords=();         # 45. haproxy stats access Password
    PackedVars=();           # 46. Packed Vars: IncludePush=1:IncludePull=0
    #
    if [[ -f "$1" ]]; then
        source "$1";
        local -i VTotal="${#MySaveVars[@]}";  # 
        local -i total="${#Server_Names[@]}"; # 
        local -i this_index=0;
        local -i v_index=0;
        #        
        for (( v_index=0; v_index<VTotal; v_index++ )); do  # Iterate Array
            for (( this_index=0; this_index<total; this_index++ )); do  # Iterate Array
                if   [[ "${MySaveVars[$v_index]}" == 'User_Names' ]]; then
                    User_Names[$this_index]=$(password_safe "${User_Names[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'Passwords' ]]; then
                    Passwords[$this_index]=$(password_safe "${Passwords[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'Root_Passwords' ]]; then
                    Root_Passwords[$this_index]=$(password_safe "${Root_Passwords[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'DB_User_Names' ]]; then
                    DB_User_Names[$this_index]=$(password_safe "${DB_User_Names[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'DB_Passwords' ]]; then
                    DB_Passwords[$this_index]=$(password_safe "${DB_Passwords[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'DB_Root_PW' ]]; then
                    DB_Root_PW[$this_index]=$(password_safe "${DB_Root_PW[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'HA_User_Names' ]]; then
                    HA_User_Names[$this_index]=$(password_safe "${HA_User_Names[$this_index]}" "$2" 'decrypt');
                elif [[ "${MySaveVars[$v_index]}" == 'HA_Passwords' ]]; then
                    HA_Passwords[$this_index]=$(password_safe "${HA_Passwords[$this_index]}" "$2" 'decrypt');
                fi
            done            
        done
    fi
    IFS="$OLD_IFS";
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "load_farm : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
}
# -----------------------------------------------------------------------------
# CREATE CONFIG {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="create_config";
    USAGE="create_config";
    DESCRIPTION="$(localize "CREATE-CONFIG-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CREATE-CONFIG-DESC"  "Create Configuration files for Last Config." "Comment: create_config @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
create_config()
{
    # Get Farm Name
    get_farm_name;
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_farm_name : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    # Get Master User Name
    get_master_user_name;     # $Master_UN
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_master_user_name : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    #
    get_editor;               # $EDITOR
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_editor : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    #
    get_ssh_keygen_type;
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_ssh_keygen_type : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    #
    get_my_password;
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_my_password : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    #
    save_default_config;
}
#}}}
# -----------------------------------------------------------------------------
# GET FARM NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_farm_name";
    USAGE="get_farm_name";
    DESCRIPTION="$(localize "GET-FARM-NAME-DESC")";
    NOTES="$(localize "GET-FARM-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-FARM-NAME-DESC"   "Get Farm Name."   "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-FARM-NAME-NOTES"  "Sets Farm Name."  "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-FARM-NAME-TITLE"  "Farm Name: Configuration File Name for Multiple Project." "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-FARM-NAME-INFO-1" "Alphanumeric [0-9 A-z -] and Dash only, No Special Characters, No Spaces." "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-FARM-NAME-INFO-2" "Enter Farm Name." "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-FARM-NAME-VD"     "Farm Name"        "Comment: get_farm_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_farm_name()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-FARM-NAME-TITLE"; 
    print_info  "GET-FARM-NAME-INFO-1";
    print_info  "GET-FARM-NAME-INFO-2";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    if [ -z "${Farm_Name}" ]; then
        Farm_Name="WittyWizard";
    fi
    verify_input_default_data "GET-FARM-NAME-VD" "${Farm_Name}" 1 1; # 1 = Alphanumeric
    Farm_Name="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET MY PASSWORD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_my_password";
    USAGE="get_my_password";
    DESCRIPTION="$(localize "GET-MY-PASSWORD-DESC")";
    NOTES="$(localize "GET-MY-PASSWORD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-MY-PASSWORD-DESC"   "Get Password."   "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MY-PASSWORD-NOTES"  "If Blank, will ask."  "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MY-PASSWORD-TITLE"  "Password for all Password Encryption and Decryption." "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MY-PASSWORD-INFO-1" "Alphanumeric [0-9 A-z -] and Dash only, No Special Characters, No Spaces." "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MY-PASSWORD-INFO-2" "Enter Password." "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MY-PASSWORD-VD"     "Password"        "Comment: get_my_password @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_my_password()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-MY-PASSWORD-TITLE"; 
    print_info  "GET-MY-PASSWORD-INFO-1";
    print_info  "GET-MY-PASSWORD-INFO-2";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    if [ -z "${Farm_Name}" ]; then
        Farm_Name="WittyWizard";
    fi
    verify_input_default_data "GET-MY-PASSWORD-VD" "${MyPassword}" 1 8; # 8 = Password
    MyPassword="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# SHOW LAST LOADED {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="show_last_config";
    USAGE="show_last_config";
    DESCRIPTION="$(localize "SHOW-LAST-LOADED-DESC")";
    NOTES="$(localize "SHOW-LAST-LOADED-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="12 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SHOW-LAST-LOADED-DESC"               "Show Loaded Variables" "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-NOTES"              "Localized." "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "SHOW-LAST-LOADED-LAST-CONFIG"        "Last Configuration Database contain User specific Settings." "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-LOAD-USER-CONFIG"   "Yes to Load Last User Configuration Database, No will create new one." "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-FAILED"             "Last Config Failed to load at line" "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-BELOW"              "Editing the below Configuration Settings requires re-running Installation." "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-USER-NAME"          "You can just change User Name (Y), or whole configuration (N)." "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-CHANGE-USER-NAME"   "Do you wish to change User Name" "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-EDIT"               "Do you wish to edit these settings" "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-LAST-LOADED-MISSING-CONFIG"     "Missing Configuration File" "Comment: show_last_config @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
show_last_config()
{
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    get_farm_name;
    if [ ! -f "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db" ]; then
        pause_function "SHOW-LAST-LOADED-MISSING-CONFIG" "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db"        
        create_config;
    fi
    print_title "SHOW-LAST-LOADED-LAST-CONFIG";
    read_input_yn "SHOW-LAST-LOADED-LOAD-USER-CONFIG" " " 1;
    if [[ "YN_OPTION" -eq 1 ]]; then
        load_default_config;
        if [[ "$IS_LAST_CONFIG_LOADED" -eq 0 ]]; then
            print_error "SHOW-LAST-LOADED-FAILED" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            create_config;
        fi
        print_title "SHOW-LAST-LOADED-LAST-CONFIG";
        # @FIX replace with better localized descriptions
        echo -e " ";
        print_this "SHOW-LAST-LOADED-BELOW";
        echo -e "";
        print_this "" "${BWhite}MyPassword           = ${Red} ${MyPassword}              ${White}";
        print_this "" "${BWhite}Master_UN            = ${BYellow} ${Master_UN}           ${White}";
        print_this "" "${BWhite}Farm_Name            = ${BWhite} ${Farm_Name}            ${White}";
        print_this "" "${BWhite}EDITOR               = ${BWhite} ${EDITOR}               ${White}";
        print_this "" "${BWhite}SSH_Keygen_Type      = ${BWhite} ${SSH_Keygen_Type}      ${White}";
        print_this "" "${BWhite}Test_SSH_User        = ${BYellow} ${Test_SSH_User}       ${White}";
        print_this "" "${BWhite}Test_SSH_PASSWD      = ${Red} ${Test_SSH_PASSWD}         ${White}";
        print_this "" "${BWhite}Test_SSH_Root_PASSWD = ${Red} ${Test_SSH_Root_PASSWD}    ${White}";
        print_this "" "${BWhite}Test_SSH_URL         = ${BWhite} ${Test_SSH_URL}         ${White}";
        print_this "" "${BWhite}Test_SSH_IP          = ${BWhite} ${Test_SSH_IP}          ${White}";
        print_this "" "${BWhite}Test_App_Path        = ${BWhite} ${Test_App_Path}        ${White}";
        print_this "" "${BWhite}Test_App_Folder      = ${BWhite} ${Test_App_Folder}      ${White}";
        print_this "" "${BWhite}Base_Storage_Path    = ${BWhite} ${Base_Storage_Path}    ${White}";
        echo -e " ";
        #
        print_info "SHOW-LAST-LOADED-USER-NAME";
        read_input_yn "SHOW-LAST-LOADED-CHANGE-USER-NAME" " " 0;
        if [[ "$YN_OPTION" -eq 1 ]]; then
            change_user;
        fi       
        read_input_yn "SHOW-LAST-LOADED-EDIT" " " 0
        if [[ "$YN_OPTION" -eq 1 ]]; then
            create_config;
            pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    else
        create_config;
        pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    BYPASS="$Old_BYPASS"; # Restore Bypass
    #if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi            
}
#}}}
# -----------------------------------------------------------------------------
# CHANGE USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="change_user";
    USAGE="change_user";
    DESCRIPTION="$(localize "CHANGE-USER-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CHANGE-USER-DESC"  "Change user in Configuration files." "Comment: change_user @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
change_user()
{
    load_default_config;
    get_master_user_name;
    #get_user_name $(gettext -s "FARM-CONFIG-USER");             # ${User_Names["$Current_Domain_Index"]}
    save_default_config;
}
#}}}
# -----------------------------------------------------------------------------
# Start of Add/Edit Functions
# -----------------------------------------------------------------------------
# GET SERVER NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_server_name";
    USAGE="get_server_name";
    DESCRIPTION="$(localize "GET-SERVER-NAME-DESC")";
    NOTES="$(localize "GET-SERVER-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-SERVER-NAME-DESC"   "Get Server Name."   "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-NAME-NOTES"  "Sets Server Name."  "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-SERVER-NAME-TITLE"  "Server Name: Normally hostname." "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-NAME-INFO-1" "Alphanumeric, No Special Characters, No Spaces, Dash not at start or end." "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-NAME-INFO-2" "Enter Server Name" "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-NAME-VD"     "Server Name"       "Comment: get_server_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_server_name()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-SERVER-NAME-TITLE"; 
    print_info  "GET-SERVER-NAME-INFO-1";
    print_info  "GET-SERVER-NAME-INFO-2";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    #
    local -i totalNames="${#Server_Names[@]}";     # Total in Array
    if [[ "$totalNames" -eq 0 ]]; then
        Server_Names["$Current_Domain_Index"]="$(hostname)";
    elif [[ "$Current_Domain_Index" -eq "$totalNames" ]]; then # do this if its an Add
        Server_Names["$Current_Domain_Index"]="WittyWizard-$Current_Domain_Index";
    fi
    #
    verify_input_default_data "GET-SERVER-NAME-VD" "${Server_Names["$Current_Domain_Index"]}" 1 3; # 3 = Domain Name
    Server_Names["$Current_Domain_Index"]="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET SERVER OS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_server_os";
    USAGE="get_server_os";
    DESCRIPTION="$(localize "GET-SERVER-OS-DESC")";
    NOTES="$(localize "GET-SERVER-OS-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-SERVER-OS-DESC"         "Get Server OS."   "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-NOTES"        "Sets Server OS."  "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-SERVER-OS-TITLE"        "Server OS for"      "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-CHG"          "Change OS"          "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-INFO-1"       "Local OS is"        "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-INFO-2"       "Choose Number from OS list for this Server." "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-INFO-3"       "Change Server OS"   "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-ARCH-TITLE"   "Installation Architecture 64 Bit or 32 Bit." "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-ARCH-INFO"    "Yes = 64 Bit, No = 32 Bit" "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SERVER-OS-ARCH-INSTALL" "Yes = 64 Bit"        "Comment: get_server_os @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_server_os()
{
    local -i so_total="${#Server_OS[@]}";
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    # if 0 then Server_Names = localhost;
    print_title "GET-SERVER-OS-TITLE" "${Server_Names["$Current_Domain_Index"]}"; 
    print_info  "GET-SERVER-OS-INFO-1" "$My_OS - $My_DIST : $My_PSUEDONAME";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    if [[ "$so_total" -eq 0 || "$Current_Domain_Index" -eq "$so_total" ]]; then
        YN_OPTION=1;
        Install_Arch["$Current_Domain_Index"]=1;
    else
        YN_OPTION=0;
        print_info  "GET-SERVER-OS-INFO-3" ": [${Server_OS["$Current_Domain_Index"]}]";
        read_input_yn "GET-SERVER-OS-CHG" "[${Server_OS["$Current_Domain_Index"]}]" "0";
    fi  
    #
    if [[ "$YN_OPTION" -eq 1 ]]; then
        print_info  "GET-SERVER-OS-INFO-2";
        select My_Distro in "${OS_Distros[@]}"; do
            if contains_element "$My_Distro" ${OS_Distros[@]}; then
                Server_OS["$Current_Domain_Index"]="$My_Distro";
                # echo "Server_OS=${Server_OS["$Current_Domain_Index"]}"; pause_function "Server_OS";
                break;
            else
                invalid_option "$My_Distro";
            fi
        done
    fi  
    # FIX Should I validate it?
    #    
    print_line;
    print_info "GET-SERVER-OS-ARCH-TITLE";
    print_info "GET-SERVER-OS-ARCH-INFO";
    if [[ "$Current_Domain_Index" -eq 0 ]]; then
        if [[ "$My_ARCH" == "x86_64" ]]; then
            Install_Arch["$Current_Domain_Index"]=1;
        else
            Install_Arch["$Current_Domain_Index"]=0;
        fi
    fi
    read_input_yn "GET-SERVER-OS-ARCH-INSTALL" " " "${Install_Arch["$Current_Domain_Index"]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_Arch["$Current_Domain_Index"]=1;
    else
        Install_Arch["$Current_Domain_Index"]=0;
    fi
    #    
    BYPASS="$Old_BYPASS"; # Restore Bypass
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET APP NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_app_name";
    USAGE="get_app_name";
    DESCRIPTION="$(localize "GET-APP-NAME-DESC")";
    NOTES="$(localize "GET-APP-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="17 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-APP-NAME-DESC"   "Get App Name." "Comment: get_app_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-NAME-NOTES"  "Sets App Name." "Comment: get_app_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-APP-NAME-TITLE"  "Applications Name if Wt or Name of Service if not." "Comment: get_app_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-NAME-INFO-1" "Enter Applications Name (Alphanumeric, No Spaces, Dash not at start or end)." "Comment: get_app_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-NAME-VD"     "App Name" "Comment: get_app_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_app_name()
{
    print_title "GET-APP-NAME-TITLE"; 
    print_info  "GET-APP-NAME-INFO-1";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    local -i i_total="${#App_Names[@]}";     # Total in Array
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        App_Names["$Current_Domain_Index"]="WittyWizard";
    fi
    verify_input_default_data "GET-APP-NAME-VD" "${App_Names["$Current_Domain_Index"]}" 1 3; # 3 = Domain Name
    App_Names["$Current_Domain_Index"]="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET DOMAIN {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_domain";
    USAGE="get_domain";
    DESCRIPTION="$(localize "GET-DOMAIN-DESC")";
    NOTES="$(localize "GET-DOMAIN-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="17 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-DOMAIN-DESC"   "Get Domain Name or URL, IP address and Port number for Web Site." "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-NOTES"  "Domain Name or URL: domain-name.tdl" "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DOMAIN-TITLE"  "Get Domain Name or URL (domain-name.tdl), IP address and Port number for Web Site." "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-INFO-1" "Enter Domain Name (domain-name.tdl)"     "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-VD-1"     "Domain Name"                           "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-INFO-2" "Enter Domain IP Address (0.0.0.0)."      "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-VD-2"     "Domain IP Address"                     "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-INFO-3" "Enter Domain IP Port Address (8080)."    "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DOMAIN-VD-3"     "Domain IP Port Address"                "Comment: get_domain @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_domain()
{
    Old_BYPASS="$BYPASS"; BYPASS=0;
    print_title "GET-DOMAIN-TITLE"; 
    print_info  "GET-DOMAIN-INFO-1";
    #    
    local -i totalDomains="${#App_Domains[@]}";     # Total in Array
    if [[ "$totalDomains" -eq 0 ]]; then
        App_Domains[0]="localhost";
        App_IPs[0]="0.0.0.0";
        App_Ports[0]='8080';
    elif [[ "$Current_Domain_Index" -eq "$totalDomains" ]]; then # Add
        App_Domains["$Current_Domain_Index"]="${User_Names["$Current_Domain_Index"]}.com";
        App_IPs["$Current_Domain_Index"]="0.0.0.0";
        App_Ports["$Current_Domain_Index"]='8080';
    fi
    #
    verify_input_default_data "GET-DOMAIN-VD-1" "${App_Domains["$Current_Domain_Index"]}" 1 3; # 3 = Domain Name
    App_Domains["$Current_Domain_Index"]="$OPTION";
    # 
    print_line;
    print_info  "GET-DOMAIN-INFO-2";
    verify_input_default_data "GET-DOMAIN-VD-2" "${App_IPs["$Current_Domain_Index"]}" 1 2; # 2 = IP Address
    App_IPs["$Current_Domain_Index"]="$OPTION";
    # App_Ports
    print_line;
    print_info  "GET-DOMAIN-INFO-3";
    verify_input_default_data "GET-DOMAIN-VD-3" "${App_Ports["$Current_Domain_Index"]}" 1 0; # 1 = Numeric
    App_Ports["$Current_Domain_Index"]="$OPTION";
    #
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET APP DESTINATION ROOT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_app_destination_root";
    USAGE="get_app_destination_root";
    DESCRIPTION="$(localize "GET-APP-DESTINATION-ROOT-DESC")";
    NOTES="$(localize "GET-APP-DESTINATION-ROOT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="17 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-APP-DESTINATION-ROOT-DESC"   "Get App Destination Root: Application Destination is normally /home/USERNAME and App Root is where the Applications Root folder is located in relation to its home folder, public or public/myapp, i.e. /home/USERNAME/public" "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-DESTINATION-ROOT-NOTES"  "Sets Destination and Root ~ Destination:Root." "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-APP-DESTINATION-ROOT-TITLE"  "Destination is normally /home/USERNAME and App Root is where the Applications Root folder is located in relation to its home folder, public or public/myapp, i.e. /home/USERNAME/public." "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-DESTINATION-ROOT-INFO-1" "Enter Destination (Alphanumeric only, No Spaces, Dash not at start or end.)" "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-DESTINATION-ROOT-VD-1"       "Destination"    "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-DESTINATION-ROOT-INFO-2" "Enter App Root in relationship to Destination i.e. 'public' or 'public/myapp' (Alphanumeric only, No Spaces, Dash not at start or end.)"    "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-APP-DESTINATION-ROOT-VD-2"       "App Root"       "Comment: get_app_destination_root @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_app_destination_root()
{
    Old_BYPASS="$BYPASS"; BYPASS=0;
    print_title "GET-APP-DESTINATION-ROOT-TITLE"; 
    #
    local -i i_total="${#App_Paths[@]}";     # Total in Array
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        App_Paths["$Current_Domain_Index"]="/home/${User_Names["$Current_Domain_Index"]}";
        App_Folder["$Current_Domain_Index"]="public";
    fi
    #
    print_info  "GET-APP-DESTINATION-ROOT-INFO-1";
    verify_input_default_data "GET-APP-DESTINATION-ROOT-VD-1" "${App_Paths["$Current_Domain_Index"]}" 1 4; # 4 = Path
    App_Paths["$Current_Domain_Index"]="$OPTION";
    #
    print_line;
    print_info  "GET-APP-DESTINATION-ROOT-INFO-2" ": ${App_Paths["$Current_Domain_Index"]}/${App_Folder["$Current_Domain_Index"]}";
    verify_input_default_data "GET-APP-DESTINATION-ROOT-VD-2" "${App_Folder["$Current_Domain_Index"]}" 1 5; # 5 = Folder
    App_Folder["$Current_Domain_Index"]="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET DB NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_db_name";
    USAGE="get_db_name";
    DESCRIPTION="$(localize "GET-DB-NAME-DESC")";
    NOTES="$(localize "GET-DB-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="17 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-DB-NAME-DESC"   "Get Database Name, User Name and Password."  "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-NOTES"  "Sets Database Name." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-TITLE"  "Database Name is the Applications Database Name." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-0" "Enter Database Type: 0=None,1=SQlite,2=PostgreSql,3=MySql." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-1" "Enter Database Name (Alphanumeric only, No Spaces)." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-VD-1"     "Database Name" "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-2" "Enter Database root Password (Alphanumeric only, No Spaces, Dash not at start or end)." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-VD-2"     "root Password" "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-3" "Enter Database User Name (Alphanumeric and underscore _ only, it can not start or end with an _, No Spaces, maximum 16 characters)." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-VD-3"     "Database User Name" "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-4" "Enter Database Password (Alphanumeric only, No Spaces, maximum 16 characters)." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-VD-4"     "Database Password" "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-DB-NAME-INFO-5" "Enter Database Full Path (Alphanumeric only, No Spaces, Dash not at start or end)." "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-DB-NAME-VD-5"     "Database Full Path" "Comment: get_db_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_db_name()
{
    print_title "GET-DB-NAME-TITLE"; 
    print_info  "GET-DB-NAME-INFO-1";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    local -i total="${#DB_Names[@]}";     # Total in Array
    if [[ "$total" -eq 0 ]]; then
        DB_Names["$Current_Domain_Index"]="${User_Names["$Current_Domain_Index"]}";
        DB_Root_PW["$Current_Domain_Index"]="$(random_password 16 0)";
        DB_User_Names["$Current_Domain_Index"]="${User_Names["$Current_Domain_Index"]}_user";
        DB_Passwords["$Current_Domain_Index"]="$(random_password 16 0)";
        DB_Full_Paths["$Current_Domain_Index"]="/home/${User_Names["$Current_Domain_Index"]}/databases";
        Db_Type["$Current_Domain_Index"]="0";
    elif [[ "$Current_Domain_Index" -eq "$total" ]]; then # Must be adding a new Record
        DB_Names["$Current_Domain_Index"]="${User_Names["$Current_Domain_Index"]}";
        DB_Root_PW["$Current_Domain_Index"]="$(random_password 16 0)";
        DB_User_Names["$Current_Domain_Index"]="${User_Names["$Current_Domain_Index"]}_user";
        DB_Passwords["$Current_Domain_Index"]="$(random_password 16 0)";
        DB_Full_Paths["$Current_Domain_Index"]="/home/${User_Names["$Current_Domain_Index"]}/databases";
        Db_Type["$Current_Domain_Index"]="3";
    fi
    #
    print_line;
    print_info "GET-DB-NAME-INFO-0";
    get_input_option "Db_Types[@]" "${Db_Type[$Current_Domain_Index]}" 0; # Database Types: 0=None,1=SQlite,2=PostgreSql,3=MySql 
    Db_Type[$Current_Domain_Index]="$OPTION";
    # Database Names
    print_line;
    verify_input_default_data "GET-DB-NAME-VD-1" "${DB_Names["$Current_Domain_Index"]}" 1 10; # 10=Variable
    DB_Names["$Current_Domain_Index"]="$OPTION";
    # Database root Password
    print_line;
    print_info  "GET-DB-NAME-INFO-2";
    verify_input_default_data "GET-DB-NAME-VD-2" "${DB_Root_PW["$Current_Domain_Index"]}" 1 8; # 8 = Password
    DB_Root_PW["$Current_Domain_Index"]="$OPTION";
    # Database User Names
    print_line;
    print_info  "GET-DB-NAME-INFO-3";
    verify_input_default_data "GET-DB-NAME-VD-3" "${DB_User_Names["$Current_Domain_Index"]}" 1 10; # 10=Variable
    DB_User_Names["$Current_Domain_Index"]="$OPTION";
    # Database Passwords
    print_line;
    print_info  "GET-DB-NAME-INFO-4";
    verify_input_default_data "GET-DB-NAME-VD-4" "${DB_Passwords["$Current_Domain_Index"]}" 1 8; # 8 = Password
    DB_Passwords["$Current_Domain_Index"]="$OPTION";
    # Database Full Path
    print_line;
    print_info  "GET-DB-NAME-INFO-5";
    verify_input_default_data "GET-DB-NAME-VD-5" "${DB_Full_Paths["$Current_Domain_Index"]}" 1 4; # 4 = Path
    DB_Full_Paths["$Current_Domain_Index"]="$OPTION";
    #
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET HA NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_ha_name";
    USAGE="get_ha_name";
    DESCRIPTION="$(localize "GET-HA-NAME-DESC")";
    NOTES="$(localize "GET-HA-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="17 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-HA-NAME-DESC"   "Get haproxy stats Access User Name and Password."  "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-HA-NAME-NOTES"  "Sets haproxy stats Access User Name and Password." "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-HA-NAME-TITLE"  "haproxy stats Access page User Name and Password." "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-HA-NAME-INFO-1" "Enter haproxy stats Access User Name (Alphanumeric only, No Spaces)." "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-HA-NAME-VD-1"     "User Name" "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-HA-NAME-INFO-2" "Enter haproxy stats Access Password (Alphanumeric and underscore _ only, it can not start or end with an _, No Spaces, maximum 16 characters)." "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-HA-NAME-VD-2"     "haproxy stats Access Password" "Comment: get_ha_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_ha_name()
{
    print_title "GET-HA-NAME-TITLE"; 
    Old_BYPASS="$BYPASS"; BYPASS=0;
    local -i total="${#HA_User_Names[@]}";     # Total in Array
    if [[ "$total" -eq 0 || "$Current_Domain_Index" -eq "$total" ]]; then
        HA_User_Names["$Current_Domain_Index"]="$DEFAULT_HA_USERNAME"; # DEFAULT_HA_USERNAME='admin';
        HA_Passwords["$Current_Domain_Index"]="$DEFAULT_HA_PASSWORD";  # DEFAULT_HA_PASSWORD='opensaidme';
    fi
    #
    print_info  "GET-HA-NAME-INFO-1";
    verify_input_default_data "GET-HA-NAME-VD-1" "${HA_User_Names["$Current_Domain_Index"]}" 1 10; # 10=Variable
    HA_User_Names["$Current_Domain_Index"]="$OPTION";
    #
    print_line;
    print_info  "GET-HA-NAME-INFO-2";
    verify_input_default_data "GET-HA-NAME-VD-2" "${HA_Passwords["$Current_Domain_Index"]}" 1 10; # 10=Variable
    HA_Passwords["$Current_Domain_Index"]="$OPTION";
    #
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET STATIC PATH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_static_path";
    USAGE="get_static_path";
    DESCRIPTION="$(localize "GET-STATIC-PATH-DESC")";
    NOTES="$(localize "GET-STATIC-PATH-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="7 May 2013";
    REVISION="7 May 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-STATIC-PATH-DESC"   "Get Static Content Path: where all Static Content is, i.e. Videos, CSS, HTML, Scripts, Images and so on." "Comment: get_static_path @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-STATIC-PATH-NOTES"  "Sets Static Content Path." "Comment: get_static_path @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-STATIC-PATH-TITLE"  "Static Content Path: where all Static Content is, i.e. Videos, CSS, HTML, Scripts, Images and so on." "Comment: get_static_path @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-STATIC-PATH-INFO-1" "Enter Static Content Path (Alphanumeric, No Spaces, - Dash (Not to start or End Folder Name), Path is Relative to Root Folder i.e. ." "Comment: get_static_path @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-STATIC-PATH-VD"     "Static Path" "Comment: get_static_path @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_static_path()
{
    Old_BYPASS="$BYPASS"; BYPASS=0;
    local -i i_total="${#Static_Path[@]}";     # Total in Array
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Static_Path["$Current_Domain_Index"]='resources';
    elif [[ "$Current_Domain_Index" -eq "$i_total" ]]; then # Must be adding a new Record
        Static_Path["$Current_Domain_Index"]='resources';
    fi
    print_title "GET-STATIC-PATH-TITLE"; 
    print_info  "GET-STATIC-PATH-INFO-1" "${App_Paths["$Current_Domain_Index"]}/${App_Folder["$Current_Domain_Index"]}/${Static_Path["$Current_Domain_Index"]}";
    verify_input_default_data "GET-STATIC-PATH-VD" "${Static_Path["$Current_Domain_Index"]}" 1 5; # 5 = Folder
    Static_Path["$Current_Domain_Index"]="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL MOSES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_Moses";
    USAGE="do_Install_Moses";
    DESCRIPTION="$(localize "DO-INSTALL-MOSES-DESC")";
    NOTES="$(localize "DO-INSTALL-MOSES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-MOSES-DESC"     "Install Moses, Machine Translation <a href='http://www.statmt.org/moses/' target='_blank' >Moses</a>" "Comment: do_Install_Moses @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MOSES-NOTES"    "Install Moses on Master Server Only." "Comment: do_Install_Moses @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-MOSES-TITLE"    "Installation of Moses: Machine Translation http://www.statmt.org/moses/" "Comment: do_Install_Moses @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MOSES-INFO"     "Install Moses on Master Server Only, Not Slave." "Comment: do_Install_Moses @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MOSES-INSTALL"  "Install Moses" "Comment: do_Install_Moses @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_Moses()
{
    local -i i_total="${#Install_Moses[@]}";
    if [[ "$i_total" -eq 0 ]]; then
        Install_Moses["$Current_Domain_Index"]=1;
    elif [[ "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_Moses["$Current_Domain_Index"]=0;
    fi    
    print_title "DO-INSTALL-MOSES-TITLE";
    print_info "DO-INSTALL-MOSES-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-MOSES-INSTALL" " " "${Install_Moses["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_Moses["$Current_Domain_Index"]=1;
    else
        Install_Moses["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL WT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install_wt";
    USAGE="do_install_wt";
    DESCRIPTION="$(localize "DO-INSTALL-WT-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-WT-DESC"     "Install Wt Library and Dependencies." "Comment: do_install_wt @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-WT-TITLE"    "Install Wt Library and Dependencies" "Comment: do_install_wt @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-WT-INFO"     "Install Wt" "Comment: do_install_wt @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-WT-INSTALL"  "Install Wt" "Comment: do_install_wt @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_install_wt()
{
    local -i i_total="${#Install_Wt[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_Wt["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-WT-TITLE";
    print_info "DO-INSTALL-WT-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-WT-INSTALL" " " "${Install_Wt["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_Wt["Current_Domain_Index"]=1;
    else
        Install_Wt["Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL WITTYWIZARD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_wittywizard";
    USAGE="do_Install_wittywizard";
    DESCRIPTION="$(localize "DO-INSTALL-APACHE-DESC")";
    NOTES="$(localize "DO-INSTALL-WITTYWIZARD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-WITTYWIZARD-DESC"     "Install Witty Wizard CMS or Custom Application." "Comment: do_Install_wittywizard @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-WITTYWIZARD-NOTES"    "Create a file called custom-witty-wizard-install.sh and define custom_witty_wizard_install to run Custom Installation." "Comment: do_Install_wittywizard @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-WITTYWIZARD-TITLE"    "Installation of Witty Wizard CMS" "Comment: do_Install_wittywizard @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-WITTYWIZARD-INFO"     "Install Witty Wizard CMS, in no it will install Custom Installation." "Comment: do_Install_wittywizard @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-WITTYWIZARD-INSTALL"  "Install Witty Wizard CMS" "Comment: do_Install_wittywizard @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_wittywizard()
{
    local -i i_total="${#Install_WittyWizard[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_WittyWizard["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-WITTYWIZARD-TITLE";
    print_info "DO-INSTALL-WITTYWIZARD-NOTES";
    print_info "DO-INSTALL-WITTYWIZARD-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-WITTYWIZARD-INSTALL" " " "${Install_WittyWizard["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_WittyWizard["Current_Domain_Index"]=1;
    else
        Install_WittyWizard["Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL APACHE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install_apache";
    USAGE="do_install_apache";
    DESCRIPTION="$(localize "DO-INSTALL-APACHE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-APACHE-DESC"     "Install Apache" "Comment: do_install_apache @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-APACHE-TITLE"    "Install Apache" "Comment: do_install_apache @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-APACHE-INFO"     "Install Apache: Note if you pick No it will remove it" "Comment: do_install_apache @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-APACHE-INSTALL"  "Install Apache" "Comment: do_install_apache @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_install_apache()
{
    local -i i_total="${#Install_Apache[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        if [[ "${Install_Wt["$Current_Domain_Index"]}" -eq 1 ]]; then
            Install_Apache["$Current_Domain_Index"]=0;
        else
            Install_Apache["$Current_Domain_Index"]=1;
        fi
    fi    
    print_title "DO-INSTALL-APACHE-TITLE";
    print_info "DO-INSTALL-APACHE-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-APACHE-INSTALL" " " "${Install_Apache["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_Apache["$Current_Domain_Index"]=1;
    else
        Install_Apache["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL POSTGRESQL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_postgresql";
    USAGE="do_Install_postgresql";
    DESCRIPTION="$(localize "DO-INSTALL-POSTGRESQL-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-POSTGRESQL-DESC"     "Install PostgreSQL Database Engine." "Comment: do_Install_postgresql @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-POSTGRESQL-TITLE"    "Installation of PostgreSQL Database Engine." "Comment: do_Install_postgresql @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-POSTGRESQL-INFO"     "Install PostgreSQL Database Engine." "Comment: do_Install_postgresql @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-POSTGRESQL-INSTALL"  "Install PostgreSQL" "Comment: do_Install_postgresql @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_postgresql()
{
    local -i i_total="${#Install_PostgreSQL[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_PostgreSQL["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-POSTGRESQL-TITLE";
    print_info "DO-INSTALL-POSTGRESQL-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-POSTGRESQL-INSTALL" " " "${Install_PostgreSQL["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_PostgreSQL["Current_Domain_Index"]=1;
    else
        Install_PostgreSQL["Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL SQLITE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_sqlite";
    USAGE="do_Install_sqlite";
    DESCRIPTION="$(localize "DO-INSTALL-SQLITE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-SQLITE-DESC"     "Install SQlite" "Comment: do_Install_sqlite @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-SQLITE-TITLE"    "Installation of SQlite Database Engine." "Comment: do_Install_sqlite @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SQLITE-INFO"     "Install SQlite Database Engine"          "Comment: do_Install_sqlite @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-SQLITE-INSTALL"  "Install SQlite"                          "Comment: do_Install_sqlite @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_sqlite()
{
    local -i i_total="${#Install_SQlite[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_SQlite["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-SQLITE-TITLE";
    print_info "DO-INSTALL-SQLITE-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-SQLITE-INSTALL" " " "${Install_SQlite["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_SQlite["Current_Domain_Index"]=1;
    else
        Install_SQlite["Current_Domain_Index"]=0;
    fi
}
#}}}
# 
# -----------------------------------------------------------------------------
# DO INSTALL PDF {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install_pdf";
    USAGE="do_install_pdf";
    DESCRIPTION="$(localize "DO-INSTALL-PDF-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-PDF-DESC"     "Install PDF Document Support using haru." "Comment: do_install_pdf @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-PDF-TITLE"    "Install PDF Document Support using haru." "Comment: do_install_pdf @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-PDF-INFO"     "Install PDF Document Support using haru" "Comment: do_install_pdf @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-PDF-INSTALL"  "Install haru" "Comment: do_install_pdf @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_install_pdf()
{
    local -i i_total="${#Install_PDF[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_PDF["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-PDF-TITLE";
    print_info "DO-INSTALL-PDF-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-PDF-INSTALL" " " "${Install_PDF["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_PDF["$Current_Domain_Index"]=1;
    else
        Install_PDF["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL FTP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_FTP";
    USAGE="do_Install_FTP";
    DESCRIPTION="$(localize "DO-INSTALL-FTP-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-FTP-DESC"     "Install FTP" "Comment: do_Install_FTP @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-FTP-TITLE"    "Installation of FTP not recommended, ssh rsync is more secure." "Comment: do_Install_FTP @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-FTP-INFO"     "Yes to install FTP, no to Remove it." "Comment: do_Install_FTP @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-FTP-INSTALL"  "Install FTP" "Comment: do_Install_FTP @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_FTP()
{
    local -i i_total="${#Install_FTP[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_FTP["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-FTP-TITLE";
    print_info "DO-INSTALL-FTP-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-FTP-INSTALL" " " "${Install_FTP["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_FTP["Current_Domain_Index"]=1;
    else
        Install_FTP["Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL TYPE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_install_type";
    USAGE="do_install_type";
    DESCRIPTION="$(localize "DO-INSTALL-APACHE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-TYPE-DESC"   "Install Type: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-TYPE-TITLE"  "Install Types: 0=Wthttpd Server, 1=Web Server, 2=Static Content, 3=SSL, 4=Email Server, 5=Database Engine PostgreSQL, 6=Database Engine MySQL" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPE-INFO-1" "Install Type" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPE-CHG"    "Change Install Type" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-TYPES-0"     "Wt App" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-1"     "Web Server" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-2"     "Static Content" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-3"     "SSL" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-4"     "Email Server" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-5"     "Database Engine PostgreSQL" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-TYPES-6"     "Database Engine MySQL" "Comment: do_install_type @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_install_type()
{
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    local -i installed_Type=0;
    print_title "DO-INSTALL-TYPE-TITLE";
    local -i i_total="${#Install_Type[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_Type["$Current_Domain_Index"]=0;
        YN_OPTION=1;
    else
        read_input_yn "DO-INSTALL-TYPE-CHG" "[$((${Install_Type[$Current_Domain_Index]})) = ${Install_Types[${Install_Type[$Current_Domain_Index]}]}]" "0";
    fi    
    if [[ "$YN_OPTION" -eq 1 ]]; then
        print_info  "DO-INSTALL-TYPE-INFO-1" ": ${Install_Types[${Install_Type[$Current_Domain_Index]}]}";
        get_input_option "Install_Types[@]" "${Install_Type["$Current_Domain_Index"]}" 0;
        Install_Type["$Current_Domain_Index"]="$OPTION";
    fi
    BYPASS="$Old_BYPASS"; # Restore Bypass
}
#}}}
#
# -----------------------------------------------------------------------------
# DO REPO INSTALL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_repo_install";
    USAGE="do_repo_install";
    DESCRIPTION="$(localize "DO-REPO-INSTALL-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-REPO-INSTALL-DESC"     "Repository Or Compile Installation" "Comment: do_repo_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-REPO-INSTALL-TITLE"    "Yes for Repository Or No for Compile Installation."    "Comment: do_repo_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-REPO-INSTALL-INFO"     "Repository Install is normally an older version but more stable." "Comment: do_repo_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-REPO-INSTALL-INSTALL"  "Repository Install" "Comment: do_repo_install @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_repo_install()
{
    local -i i_total="${#Repo_Install[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Repo_Install["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-REPO-INSTALL-TITLE";
    print_info "DO-REPO-INSTALL-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-REPO-INSTALL-INSTALL" " " "${Repo_Install["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Repo_Install["$Current_Domain_Index"]=1;
    else
        Repo_Install["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO CREATE USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_create_user";
    USAGE="do_create_user";
    DESCRIPTION="$(localize "DO-CREATE-USER-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-CREATE-USER-DESC"     "Create User" "Comment: do_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-CREATE-USER-TITLE"    "Create User for Slave Application" "Comment: do_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CREATE-USER-INFO"     "Create User" "Comment: do_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CREATE-USER-INSTALL"  "Create User" "Comment: do_create_user @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_create_user()
{
    local -i i_total="${#Create_User[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Create_User["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-CREATE-USER-TITLE";
    print_info "DO-CREATE-USER-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-CREATE-USER-INSTALL" " " "${Create_User["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Create_User["$Current_Domain_Index"]=1;
    else
        Create_User["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO CREATE KEY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_create_key";
    USAGE="do_create_key";
    DESCRIPTION="$(localize "DO-CREATE-KEY-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-CREATE-KEY-DESC"     "Create Key for ssh" "Comment: do_create_key @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-CREATE-KEY-TITLE"    "Create Key for ssh Application Authentication for Automated Scripting." "Comment: do_create_key @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CREATE-KEY-INFO"     "Create Key" "Comment: do_create_key @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CREATE-KEY-INSTALL"  "Create Key" "Comment: do_create_key @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_create_key()
{
    local -i i_total="${#Create_Key[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Create_Key["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-CREATE-KEY-TITLE";
    print_info "DO-CREATE-KEY-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-CREATE-KEY-INSTALL" " " "${Create_Key["$Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Create_Key["$Current_Domain_Index"]=1;
    else
        Create_Key["$Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO RSYNC DELETE PUSH PULL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_rsync_delete_push_pull";
    USAGE="do_rsync_delete_push_pull";
    DESCRIPTION="$(localize "DO-RSYNC-DELETE-PUSH-PULL-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-DESC"     "Use --delete with rsync for Push." "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-TITLE-1"    "Use --delete with rsync for Push." "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-INFO-1"     "Use --delete for Push" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-INSTALL-1"  "Use --delete" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-TITLE-2"    "Use --delete with rsync for Push." "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-INFO-2"     "Use --delete for Pull" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-INSTALL-2"  "Use --delete" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-INCLUDE"    "Include in Automatic Push or Pull" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IPUSH"      "Include in Push" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IPULL"      "Include in Pull" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IST"        "Install Type: Yes to Run Full-Install, No for haproxy only" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IST-1"      "Do Not install." "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IST-2"      "Full-Install" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-IST-3"      "haproxy" "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-RSYNC-DELETE-PUSH-PULL-FTP"        "Install FTP Server." "Comment: do_rsync_delete_push_pull @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_rsync_delete_push_pull()
{
    local -i Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    i_total="${#Rsync_Delete_Push[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Rsync_Delete_Push["$Current_Domain_Index"]=0;
        IncludePush["$Current_Domain_Index"]=0;
        IncludePull["$Current_Domain_Index"]=0;
        Install_Script_Type["$Current_Domain_Index"]=1;
        FTP_Server["$Current_Domain_Index"]=0;
        PackedVars[$Current_Domain_Index]="MyVar=0"; # @FIX
    fi    
    print_title "DO-RSYNC-DELETE-PUSH-PULL-TITLE-1";
    print_info "DO-RSYNC-DELETE-PUSH-PULL-INFO-1";
    read_input_yn "DO-RSYNC-DELETE-PUSH-PULL-INSTALL-1" " " "${Rsync_Delete_Push["$Current_Domain_Index"]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Rsync_Delete_Push["$Current_Domain_Index"]=1;
    else
        Rsync_Delete_Push["$Current_Domain_Index"]=0;
    fi
    #
    print_line;
    i_total="${#Rsync_Delete_Pull[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Rsync_Delete_Pull["$Current_Domain_Index"]=0;
    fi    
    print_info "DO-RSYNC-DELETE-PUSH-PULL-TITLE-2";
    print_info "DO-RSYNC-DELETE-PUSH-PULL-INFO-2";
    read_input_yn "DO-RSYNC-DELETE-PUSH-PULL-INSTALL-2" " " "${Rsync_Delete_Pull[$Current_Domain_Index]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Rsync_Delete_Pull["$Current_Domain_Index"]=1;
    else
        Rsync_Delete_Pull["$Current_Domain_Index"]=0;
    fi
    #
    unpack_bools "${PackedVars[$Current_Domain_Index]}";
    print_line;
    read_input_yn "DO-RSYNC-DELETE-PUSH-PULL-IPUSH" " " "${IncludePush[$Current_Domain_Index]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        IncludePush["$Current_Domain_Index"]=1;
    else
        IncludePush["$Current_Domain_Index"]=0;
    fi
    print_line;
    read_input_yn "DO-RSYNC-DELETE-PUSH-PULL-IPULL" " " "${IncludePull[$Current_Domain_Index]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        IncludePull["$Current_Domain_Index"]=1;
    else
        IncludePull["$Current_Domain_Index"]=0;
    fi
    #
    print_line;
    Install_Script_Types=( "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-1")" "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-2")" "$(gettext -s "DO-RSYNC-DELETE-PUSH-PULL-IST-3")" );
    get_input_option "Install_Script_Types[@]" "${Install_Script_Type[$Current_Domain_Index]}" 0; 
    Install_Script_Type["$Current_Domain_Index"]="$OPTION";
    #
    if [[ "${Install_FTP[$Current_Domain_Index]}" -eq 1 ]]; then
        print_line;
        print_info "DO-RSYNC-DELETE-PUSH-PULL-FTP";
        get_input_option "FTP_Servers[@]" "${FTP_Server[$Current_Domain_Index]}" 0; # FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP 
        FTP_Server[$Current_Domain_Index]="$OPTION";
    fi
    # 
    BYPASS="$Old_BYPASS"; # Restore Bypass
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL MONIT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_monit";
    USAGE="do_Install_monit";
    DESCRIPTION="$(localize "DO-INSTALL-MONIT-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-MONIT-DESC"     "Install Monit" "Comment: do_Install_monit @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-MONIT-TITLE"    "Installation of Monit will Monitor HTTP Server Threads and restart them if needed." "Comment: do_Install_monit @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MONIT-INFO"     "Install Monit for a more Robust Installation and it works with haproxy." "Comment: do_Install_monit @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-MONIT-INSTALL"  "Install Monit" "Comment: do_Install_monit @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_monit()
{
    local -i i_total="${#Install_Monit[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_Monit["$Current_Domain_Index"]=1;
    fi    
    print_title "DO-INSTALL-MONIT-TITLE";
    print_info "DO-INSTALL-MONIT-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-MONIT-INSTALL" " " "${Install_Monit["Current_Domain_Index"]}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_Monit["Current_Domain_Index"]=1;
    else
        Install_Monit["Current_Domain_Index"]=0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DO INSTALL HAPROXY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_Install_haproxy";
    USAGE="do_Install_haproxy";
    DESCRIPTION="$(localize "DO-INSTALL-HAPROXY-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-INSTALL-HAPROXY-DESC"     "Install haproxy" "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-INSTALL-HAPROXY-TITLE"    "Installation of haproxy is for Load Balancing and Farms." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-INFO"     "Install haproxy if you want a more Robust Installation and it works with monit." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-INSTALL"  "Install haproxy"             "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-INFO-1"   "Enter Global maxconn."       "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-VD-1"       "Global maxconn"            "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-INFO-2"   "Enter Default maxconn."      "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-VD-2"       "Default maxconn"           "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-INFO-3"   "Does URL start with www."    "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-VD-3"       "www"                       "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-TITLE"    "HTTP Servers Instances or Threads per IP address per Domain." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-INFO-1"   "Number of HTTP Servers or Threads per IP address per Domain." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-INFO-2"   "Each Domain uses its own Threads, and can vary just like this record." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-INFO-3"   "Current Number of Threads Total" "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-NUMBER"   "Greater then 0 and Limited by Memory." "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-INSTALL"  "Threads per Domain" "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-INSTALL-HAPROXY-THREADS-CHANGE"   "Change number of Threads from" "Comment: do_Install_haproxy @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_Install_haproxy()
{
    local -i i_total="${#Install_HaProxy[@]}";
    if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
        Install_HaProxy["$Current_Domain_Index"]=1;
        Server_Threads["$Current_Domain_Index"]=2;
        HA_User_Names["$Current_Domain_Index"]="$DEFAULT_HA_USERNAME"; # DEFAULT_HA_USERNAME='admin';
        HA_Passwords["$Current_Domain_Index"]="$DEFAULT_HA_PASSWORD";  # DEFAULT_HA_PASSWORD='opensaidme';
    fi    
    print_title "DO-INSTALL-HAPROXY-TITLE";
    print_info "DO-INSTALL-HAPROXY-INFO";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-HAPROXY-INSTALL" " " "${Install_HaProxy["Current_Domain_Index"]}";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        Install_HaProxy["Current_Domain_Index"]=1;
    else
        Install_HaProxy["Current_Domain_Index"]=0;
    fi
    if [[ "${Install_HaProxy["Current_Domain_Index"]}" -eq 1 ]]; then
        i_total="${#Global_Maxconn[@]}";
        if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
            Global_Maxconn["$Current_Domain_Index"]=4096;
        fi    
        print_line;
        print_info "DO-INSTALL-HAPROXY-INFO-1";
        verify_input_default_data "DO-INSTALL-HAPROXY-VD-1" "${Global_Maxconn["Current_Domain_Index"]}" 1 0; # 1 = Numeric
        Global_Maxconn["Current_Domain_Index"]="$OPTION";
        #
        i_total="${#Default_Maxconn[@]}";
        if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
            Default_Maxconn["$Current_Domain_Index"]=2048;
        fi    
        print_line;
        print_info "DO-INSTALL-HAPROXY-INFO-2";
        verify_input_default_data "DO-INSTALL-HAPROXY-VD-2" "${Default_Maxconn["Current_Domain_Index"]}" 1 0; # 1 = Numeric
        Default_Maxconn["Current_Domain_Index"]="$OPTION";
        #        
        i_total="${#Is_WWW[@]}";
        if [[ "$i_total" -eq 0 || "$Current_Domain_Index" -eq "$i_total" ]]; then
            Is_WWW["$Current_Domain_Index"]=2048;
        fi    
        print_line;
        print_info "DO-INSTALL-HAPROXY-INFO-3";
        read_input_yn "DO-INSTALL-HAPROXY-VD-3" " " "${Is_WWW["Current_Domain_Index"]}";
        if [[ "$YN_OPTION" -eq 1 ]]; then
            Is_WWW["Current_Domain_Index"]=1;
        else
            Is_WWW["Current_Domain_Index"]=0;
        fi
    fi
    #
    print_line;
    print_info "DO-INSTALL-HAPROXY-THREADS-TITLE";
    local -i c_Index=0;
    local -i st_total=0;
    for (( c_Index=0; c_Index<i_total; c_Index++ )); do
        st_total=$(( ${Server_Threads[$c_Index]} + st_total )); # Test
    done
    #
    print_info "DO-INSTALL-HAPROXY-THREADS-INFO-1"; 
    print_info "DO-INSTALL-HAPROXY-THREADS-INFO-2"; 
    print_caution "DO-INSTALL-HAPROXY-THREADS-INFO-3" "$st_total"; 
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "DO-INSTALL-HAPROXY-THREADS-CHANGE" "${Server_Threads["$Current_Domain_Index"]}" "0";
    if [[ "$YN_OPTION" -eq 1 ]]; then
        YN_OPTION=0;
        while [[ "$YN_OPTION" -ne 1 ]]; do
            read_input_default "DO-INSTALL-HAPROXY-THREADS-NUMBER" "${Server_Threads["$Current_Domain_Index"]}"
            if [[ $OPTION =~ ^-?[0-9]+$ ]]; then
                read_input_yn "DO-INSTALL-HAPROXY-THREADS-INSTALL" "${Server_Threads["$Current_Domain_Index"]}" "1";
                BYPASS="$Old_BYPASS"; # Restore Bypass
                if [[ "$YN_OPTION" -eq 1 ]]; then
                    Server_Threads["$Current_Domain_Index"]="$OPTION";
                    break;
                fi
            fi
        done  
    fi
    #
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "${Install_HaProxy["Current_Domain_Index"]}" -eq 1 ]]; then
        get_ha_name;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# GET MASTER USER NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_master_user_name";
    USAGE="get_master_user_name";
    DESCRIPTION="$(localize "GET-MASTER-USER-NAME-DESC")";
    NOTES="$(localize "GET-MASTER-USER-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-MASTER-USER-NAME-DESC"   "Get Master User Name." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-NOTES"  "Sets Master_UN." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-TITLE"  "Master User Name: Normally logged on user, not root. Used to set Permissions and Run Commands." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-INFO"   "No Special Characters or Spaces." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-1" "Enter Master User Name." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-1"   "Master User Name" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-2" "Test SSH Account i.e. User Name." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-2"   "Test SSH Account"  "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-3" "Test SSH Password for" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-3"   "Test SSH Password" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-4" "Test SSH root Password for" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-4"   "Test SSH root Password" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-5" "Test SSH URL i.e. domain.tdl." "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-5"   "Test SSH URL" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-6" "Test SSH IP Address i.e. 192.168.1.1" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-6"   "Test SSH IP" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-7" "Test SSH IP Application Path: i.e. /home/USERNAME/" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-7"   "Test SSH Application Path" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-8" "Test SSH Folder: i.e. /home/USERNAME/public/" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-8"   "Test SSH Folder" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-MASTER-USER-NAME-INFO-9" "Base Storage Path: i.e. /home/USERNAME/WebApps/" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-MASTER-USER-NAME-VD-9"   "Base Storage Path" "Comment: get_master_user_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_master_user_name()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-MASTER-USER-NAME-TITLE"; 
    Old_BYPASS="$BYPASS"; BYPASS=0;
    if [ -z "${Master_UN}" ]; then
        Master_UN="$(whoami)";
    fi
    #
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-1";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-1" "${Master_UN}" 1 1; # 1 = Alphanumeric
    Master_UN="$OPTION";
    #    
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-2";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-2" "${Test_SSH_User}" 1 1; # 1 = Alphanumeric
    Test_SSH_User="$OPTION";
    # 
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-3" "${Test_SSH_User}";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-3" "${Test_SSH_PASSWD}" 1 8; # 8 = Password
    Test_SSH_PASSWD="$OPTION";
    # 
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-4" "root";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-4" "${Test_SSH_Root_PASSWD}" 1 8; # 8 = Password
    Test_SSH_Root_PASSWD="$OPTION";
    #
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-5";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-5" "${Test_SSH_URL}" 1 3; # 3 = Domain Name
    Test_SSH_URL="$OPTION";
    #
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-6";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-6" "${Test_SSH_IP}" 1 2; # 2 = IP Address
    Test_SSH_IP="$OPTION";
    #
    if [[ "$Test_App_Path" == "" ]]; then
        Test_App_Path="/home/${Test_SSH_User}/";
    fi
    if [[ "$Test_App_Folder" == "" ]]; then
        Test_App_Folder="public";
    fi
    #
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-7";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-7" "${Test_App_Path}" 1 4; # 4 = Path
    Test_App_Path="$OPTION";
    #
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-8";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-8" "${Test_App_Folder}" 1 5; # 5 = Folder
    Test_App_Folder="$OPTION";
    # 
    if [[ "${Base_Storage_Path}" == '' ]]; then
        Base_Storage_Path="/home/${Master_UN}/WebApps";
    fi
    print_line;
    print_info  "GET-MASTER-USER-NAME-INFO";
    print_info  "GET-MASTER-USER-NAME-INFO-9";
    verify_input_default_data "GET-MASTER-USER-NAME-VD-9" "${Base_Storage_Path}" 1 5; # 5 = Folder
    Base_Storage_Path="$OPTION";
    #
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET SSH KEYGEN TYPE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_ssh_keygen_type";
    USAGE="get_ssh_keygen_type";
    DESCRIPTION="$(localize "GET-SSH-KEYGEN-TYPE-DESC")";
    NOTES="$(localize "GET-SSH-KEYGEN-TYPE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "GET-SSH-KEYGEN-TYPE-DESC"   "Get SSH Keygen Type: rsa or dsa." "Comment: get_ssh_keygen_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SSH-KEYGEN-TYPE-NOTES"  "Sets Master_UN." "Comment: get_ssh_keygen_type @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-SSH-KEYGEN-TYPE-TITLE"  "SSH Keygen Type: rsa or dsa." "Comment: get_ssh_keygen_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SSH-KEYGEN-TYPE-INFO-1" "SSH Keygen Type: rsa else dsa." "Comment: get_ssh_keygen_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-SSH-KEYGEN-TYPE-VD"     "SSH Keygen Type rsa" "Comment: get_ssh_keygen_type @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_ssh_keygen_type()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-SSH-KEYGEN-TYPE-TITLE"; 
    print_info  "GET-SSH-KEYGEN-TYPE-INFO-1";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    if [ -z "${SSH_Keygen_Type}" ]; then
        SSH_Keygen_Type="rsa";
    fi
    local -i Is_RSA=1;
    if [[ "${SSH_Keygen_Type}" == 'rsa' ]]; then
        Is_RSA=1;
    else
        Is_RSA=0;
    fi
    read_input_yn "GET-SSH-KEYGEN-TYPE-VD" " " "$Is_RSA";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        SSH_Keygen_Type='rsa';
    else
        SSH_Keygen_Type='dsa';
    fi
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# CLEAR ERROR LOGS  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="clear_error_logs";
    USAGE="clear_error_logs";
    DESCRIPTION="$(localize "CLEAR-ERROR-LOGS-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CLEAR-ERROR-LOGS-DESC"  "Clear Error Logs" "Comment: clear_error_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAR-ERROR-LOGS-TITLE" "Clearing Error Logs" "Comment: clear_error_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAR-ERROR-LOGS-LOAD"  "Loading" "Comment: clear_error_logs @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
clear_error_logs()
{
    print_this "CLEAR-ERROR-LOGS-TITLE" "...";
    clear_logs;
}
#}}}
# -----------------------------------------------------------------------------
# LOAD LAST CONFIG {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="load_default_config";
    USAGE="load_default_config";
    DESCRIPTION="$(localize "LOAD-LAST-CONFIG-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "LOAD-LAST-CONFIG-DESC" "Last Configuration is User Specific Settings like User_Name, LOCALE, HOSTNAME, KEYMAP COUNTRY, TIMEZONE and more." "Comment: load_default_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-LAST-CONFIG-FNF"  "File Not Found" "Comment: load_default_config @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-LAST-CONFIG-PNM"  "Default Password Failed to decrypt Secret." "Comment: load_default_config @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
load_default_config()
{
    #
    local Last_IFS="$IFS"; IFS=$' ';
    if [[ -f "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db" ]]; then
        #        
        MyPassword='';
        Master_UN='';
        EDITOR='';
        SSH_Keygen_Type='';
        Test_SSH_User='';
        Test_SSH_PASSWD='';
        Test_SSH_Root_PASSWD='';
        Test_SSH_URL='';
        Test_SSH_IP='';
        Test_App_Path='';
        Test_App_Folder='';
        Base_Storage_Path='';
        source "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db";
        local -i VTotal="${#MyDefaultSaveVars[@]}";  # 
        local -i this_index=0;
        local -i v_index=0;
        #
        for (( v_index=0; v_index<VTotal; v_index++ )); do  # Iterate Array
            if   [[ "${MyDefaultSaveVars[$v_index]}" == 'MyPassword' ]]; then
                MyPassword=$(password_safe "$MyPassword" "$MyDefaultPassword" 'decrypt');
            elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Master_UN' ]]; then
                Master_UN=$(password_safe "$Master_UN" "$MyDefaultPassword" 'decrypt');
            elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_User' ]]; then
                Test_SSH_User=$(password_safe "$Test_SSH_User" "$MyDefaultPassword" 'decrypt');
            elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_PASSWD' ]]; then
                Test_SSH_PASSWD=$(password_safe "$Test_SSH_PASSWD" "$MyDefaultPassword" 'decrypt');
            elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_Root_PASSWD' ]]; then
                Test_SSH_Root_PASSWD=$(password_safe "$Test_SSH_Root_PASSWD" "$MyDefaultPassword" 'decrypt');
            fi
            if [[ "$?" -eq 1 ]]; then
                echo "LOAD-LAST-CONFIG-PNM" "load_default_config @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        done
        IS_LAST_CONFIG_LOADED=1;
    else
        echo "$(gettext -s "LOAD-LAST-CONFIG-FNF") ${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db";
        read -e -sn 1 -p "load_default_config $(basename $BASH_SOURCE) : $LINENO";
    fi
    IFS="$Last_IFS";    
}
#}}}
# -----------------------------------------------------------------------------
# SAVE FARM CONFIG {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="save_default_config";
    USAGE="save_default_config";
    DESCRIPTION="$(localize "SAVE-FARM-CONFIG-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SAVE-FARM-CONFIG-DESC"  "Save Farm Configuration file." "Comment: save_default_config @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
save_default_config()
{
    make_dir "${CONFIG_PATH}/${Farm_Name}/" "save_default_config @ $(basename $BASH_SOURCE) : $LINENO"; 
    touch "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db";
    local -i VTotal="${#MyDefaultSaveVars[@]}"; 
    echo "#" > "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db"
    #
    for (( v_index=0; v_index<VTotal; v_index++ )); do  # Iterate Array
        #
        MyVarName="${MyDefaultSaveVars[$v_index]}";
        if   [[ "${MyDefaultSaveVars[$v_index]}" == 'MyPassword' ]]; then
            MyValue=$(password_safe "$MyPassword" "$MyDefaultPassword" 'encrypt'); # @FIX MyPassword DefaultPassword
        elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Master_UN' ]]; then
            MyValue=$(password_safe "$Master_UN" "$MyDefaultPassword" 'encrypt');
        elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_User' ]]; then
            MyValue=$(password_safe "$Test_SSH_User" "$MyDefaultPassword" 'encrypt');
        elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_PASSWD' ]]; then
            MyValue=$(password_safe "$Test_SSH_PASSWD" "$MyDefaultPassword" 'encrypt');
        elif [[ "${MyDefaultSaveVars[$v_index]}" == 'Test_SSH_Root_PASSWD' ]]; then
            MyValue=$(password_safe "$Test_SSH_Root_PASSWD" "$MyDefaultPassword" 'encrypt');
        else            
            eval "MyValue=\$$MyVarName";
        fi
        echo "${MyDefaultSaveVars[$v_index]}=\"${MyValue}\";" >> "${CONFIG_PATH}/${Farm_Name}/${Farm_Name}-config.db"; # 
    done
    #
    IS_LAST_CONFIG_LOADED=1;
    # Write to Default file
    # Farm_Name
    set_defaults;
}
#}}}
# -----------------------------------------------------------------------------
#
# Help File
# -----------------------------------------------------------------------------
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then 
    localize_info "SHOW-CUSTOM-HELP-INFO-1"  "Witty Wizard Content Management System (CMS)" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-2"  "ssh into your new VPS server, keep in mind this script is not written to run on an existing system, but a new one, DO NOT INSTALL this on an existing server, unless you know what you are doing." "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-3"  "&nbsp;&nbsp;&nbsp;&nbsp; Worst case scenario: it fails to create a user if one exist, no problem, it ask you for a password, this will change it, even if its the same, so ctrl-c once, twice will kill the script" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-4"  "&nbsp;&nbsp;&nbsp;&nbsp; Now it will overwrite a few config files, and overwrite what is in the folder specified, so I do not see any real harm in this, just a warning that you know what you are doing." "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-5"  "&nbsp;&nbsp;&nbsp;&nbsp; ssh root@IP-ADDRESS" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-6"  "&nbsp;&nbsp;&nbsp;&nbsp; Password" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-7"  "&nbsp;&nbsp;&nbsp;&nbsp; Change USERNAME for the actual users name" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-8"  "wget https://github.com/WittyWizard/install/archive/master.zip; unzip master.zip; cd install-master; mv -v * ..; cd ..; rm -rf install-master; rm -f master.zip;" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-CUSTOM-HELP-INFO-9"  "./WittyWizard-install.sh -a USERNAME  RootFolder AppName" "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
    
    #localize_info "SHOW-CUSTOM-HELP-INFO-1" "&nbsp;&nbsp;&nbsp;&nbsp; " "Comment: show_custom_help @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -----------------------------------------------------------------------------
show_custom_help()
{
    echo -e "<hr />";
    echo -e "<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-1")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-2")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-3")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-4")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-5")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-6")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-7")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-8")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-9")<br />";
    return 0
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-10")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-11")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-12")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-13")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-14")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-15")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-16")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-17")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-18")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-19")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-20")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-21")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-22")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-23")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-24")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-25")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-26")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-27")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-28")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-29")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-30")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-31")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-32")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-33")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-34")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-35")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-36")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-37")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-38")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-39")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-40")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-41")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-42")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-43")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-44")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-45")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-46")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-47")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-48")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-49")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-50")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-51")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-52")<br />";
    echo -e "$(gettext -s "SHOW-CUSTOM-HELP-INFO-53")<br />";
    return 0;
}
# *****************************************************************************
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "WIZ-BYY"    "Exit Witty Wizard"             "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RUN-TEST"   "Run Self-Test"                 "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAIN-WIZ-1" "AUTOMAN Install Witty Wizard." "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
fi
#
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then # Run Localizer
    SILENT_MODE=1;
    localize_save;
    SILENT_MODE=0;
elif [[ "$RUN_HELP" -eq 1 ]]; then    # Run Help
    SILENT_MODE=1;
    print_help;
    SILENT_MODE=0;
elif [[ "$RUN_TEST" -eq 1 ]]; then    # Run Test 1
    print_info "RUN-TEST";
elif [[ "$RUN_TEST" -eq 2 ]]; then    # Run Test 2
    print_info "RUN-TEST";
elif [[ "$RUN_TEST" -eq 3 ]]; then    # Run Test 3
    print_info "RUN-TEST";
elif [[ "$AUTOMAN" -eq 1 ]]; then
    BYPASS=0; # Do Not Allow Bypass
    cls;
    clear_error_logs;
    print_warning "MAIN-WIZ-MODE-3";
    do_install;       
else
    cls;
    clear_error_logs;
    show_last_config;
    main_menu;
fi
if [[ "$CleanUp" -eq 1 ]]; then
    history -c;
    # @FIX clear ssh history?
fi
print_this "WIZ-BYY";
# ************************************* END OF SCRIPT *************************

