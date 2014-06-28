#!/bin/bash
#
declare LAST_UPDATE="8 Jun 2014 16:33";
declare SCRIPT_VERSION="1.0.1.A";
if [ -z "${SCRIPT_NAME}" ]; then
    declare SCRIPT_NAME="wizard.sh";
fi
#
#-------------------------------------------------------------------------------
# This script will install Arch Linux, although it could be adapted to install any Linux distro that uses the same package names.
# This Script Assumes you wish GPT disk format, and gives you the choice to use UEFI, BIOS or no boot loader.
# The first time you use it, configure settings for Software and Configuration, you can use debugging help if needed, this will start the Wizard, follow instructions.
# You have the Option of Installing Software, this is just a list of Configuration files, and will save a series of files for later use.
# After reboot you have the option to run -i to install software; you can load the Software list if you already saved it; or create a new one.
# If after reboot you have no Internet access, run the Script with a -n and pick option 1 to setup network, then the option to ping.
#-------------------------------------------------------------------------------
# Programmers:
# 1. Created by helmuthdu mailto: helmuthdu[at]gmail[dot]com prior to Nov 2012
# 2. Re-factored and Added Functionality by Jeffrey Scott Flesher to make it a Wizard.
#-------------------------------------------------------------------------------
# Changes:
#-------------------------------------------------------------------------------
# @FIX
# 1. Localization
# 2. Save all installed and removed into file for testing
# 3. Finish Menu load and save option.
# 4. Custom Install
# 5. Ask what drive to save log files to; only if live mode, case running from root, and want logs on flash drive.
#-------------------------------------------------------------------------------
# This Program is under the Free License. It is Free of any License or Laws Governing it.
# You are Free to apply what ever License you wish to it below this License.
# The Free License means that the End User has total Freedom while using the License,
# whereas all other License types fall short due to the Laws governing them,
# Free License is not covered by any Law, all programmers writing under the Free License,
# take an oath that the Software Contains No Malice: Viruses, Malware, or Spybots...
# and only does what it was intended to do, notifying End Users before doing it.
# All Programmers and End Users are Free to Distribute or Modify this script,
# as long as they list themselves as Programmers and Document Changes.
# Free License is also Free of any Liability or Legal Actions, Freedom starts with Free.
#-------------------------------------------------------------------------------
# Other LICENSES:
# 1. GNU
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Things to Fix
# Check for USERNAME in all Log functions and replace it with $USERNAME
# Add function to ssh into account and get hostname; pull_hostname
#
shopt -s expand_aliases;
alias cls='printf "\033c"';
cls;
#
declare -i USE_PARALLEL=0; # Parallel Package Installation, 0 means to use the standard Package Installer
# Get current Device Script is Executing from
declare SCRIPT_DEVICE="";
if [[ "$EUID" -eq 0 ]]; then
    SCRIPT_DEVICE="$(df | grep -w "$FULL_SCRIPT_PATH" | awk {'print $1'})";
fi
declare SCRIPT_DEVICE="${SCRIPT_DEVICE:5:4}";
declare MENU_PATH="${FULL_SCRIPT_PATH}/MENU";
# Debugging
declare -i SET_DEBUGGING=0; # Used in set_debugging_mode
declare -i SILENT_MODE=0;   # Used to Silence Logging and warnings
declare -i SHOW_PAUSE=1;    # For Automation
declare -i E_BADARGS=65;    # Return Bad Args
# Localization
declare -a LOCALIZE_ID=();       # Localize ID for po file
declare -a LOCALIZE_MSG=();      # Localize MSG for po file
declare -a LOCALIZE_COMMENT=();  # Localize Comment for po file
# Help
declare -a HELP_ARRAY=();
# Configuration File Signatures
declare -r FILE_SIGNATURE="# ARCH WIZARD ID Signature"; # Copy this into file to test for changes made by this script
# Helper Global Variables
declare MyString='';          # Used in Testing
# Network Detection
declare PingHost1="google.com";
declare PingHost2="wikipedia.org";
declare check_eth0=" ";
declare check_eth1=" ";
declare check_eth2=" ";
declare -i ActiveAdapter=0;   # Active Network Adapter Index for NIC
declare ActiveNetAdapter="";  # Active Network Adapter Name: same as NIC
declare -a NIC=();            # Nic Name: eth0, eth1...
declare -a EthAddress=();     # Nic Address
declare -a EthReverseDNS=();  # Nic Reverse DNS Address
declare -i ETH0_ACTIVE=0;     # Detect NIC 1
declare -i ETH1_ACTIVE=0;     # Detect NIC 2
declare -i ETH2_ACTIVE=0;     # Detect NIC 3
# Note: Make sure to void these out on exit or reboot to clear them.
declare USERNAME="$(whoami)"; # User Name
declare USERPASSWD='';        # User Password
declare Root_Password='';     # Root Password
#
declare BTICK='`';            # Back Tick used in SQL
declare TICK="'";             # Tick used in Bash
#
declare -a USER_GROUPS=();
# SSH
declare SSH_Keygen_Type='rsa';  # dsa
#
declare -a PACKAGES=( "" );
declare -a AUR_PACKAGES=( "" );
declare -a PACKMANAGER=( "" );
declare -a PACKMANAGER_NAME=( "" );
#
declare -a PACKAGE_CHECK_FAILURES=( "mate" "mate-extras" "base-devel" );
declare -a PACKAGE_FAILURES_CHECK=( "mate/libmate" "mate/mate-media" "core/gcc" );
#
declare -a TASKMANAGER=( "" );
declare -a TASKMANAGER_NAME=( "" );
#
#
declare -a AUR_HELPERS=("yaourt" "packer" "pacaur");
declare AUR_HELPER="yaourt";
#
declare -a LOCALE_ARRAY=( "" );
declare -a LIST_DEVICES=( "" );
declare -i REFRESH_REPO=1;
declare -i REFRESH_AUR=1;
declare -i IS_CUSTOM_NAMESERVER=0;
declare CUSTOM_NS1="192.168.1.1";
declare CUSTOM_NS2="192.168.0.1";
declare CUSTOM_NS_SEARCH="localhost";
#
declare -a CORE_INSTALL=();
declare -a FAILED_CORE_INSTALL=();
declare -a AUR_INSTALL=();
declare -a FAILED_AUR_INSTALL=();
#
declare CUSTOM_PACKAGES_NAME="Packages";
declare AUR_REPO_NAME="AUR-Packages"; # ${USERNAME}
declare CUSTOM_PACKAGES="${FULL_SCRIPT_PATH}/${CUSTOM_PACKAGES_NAME}"; # mount path of script: /root/usb/Packages
declare AUR_CUSTOM_PACKAGES="${FULL_SCRIPT_PATH}/${AUR_REPO_NAME}"; # if Boot Mode /root/usb/AUR-Packages, if Live Mode /mnt/AUR-Packages
declare PACMAN_CACHE="/var/cache/pacman/pkg";
declare CUSTOM_REPO_NAME="custom";
#
declare AUR="Arch User Repository (AUR)";
declare MAYBE_AUR="May Use AUR";
declare SOME_AUR="Some AUR";
declare -i PACMAN_OPTIMIZER=0;
declare -i PACMAN_REPO_TYPE=1; # 0=None, 1=Server, 2=Client
declare -i INSTALL_NO_INTERNET=0;
declare -i AUR_REPO=0;
declare -i IS_PHTHON3_AUR=0; # install python3-aur
declare PACMAN_OPTIMIZE_PACKAGES="rsync";
declare -i SIMULATE=0; # Simulate Install, create Scripts for importing
#
declare EXCLUDE_FILE_WARN=( "${CONFIG_NAME}-1-taskmanager-name.db" "${CONFIG_NAME}-1-taskmanager.db" "${CONFIG_NAME}-0-packagemanager-name.db" "${CONFIG_NAME}-0-packagemanager.db" "${CONFIG_NAME}-2-packages.db" "${CONFIG_NAME}-2-aur-packages.db" "${CONFIG_NAME}-3-user-groups.db" "${CONFIG_NAME}-4-software-config.db" );
#
declare OPTION=" ";           # Options - Used in Input
declare -a OPTIONS=();        # Array of Options - Used in Input
declare -i INSTALL_WIZARD=0;  # Install Wizard - Setup default list to execute; do it in code so recording Macro's is not needed.
declare -i AUTOMAN=0;         # Automatic / Manual
declare -i BYPASS=1;          # Allow Bypass in Input
declare MyReturn='';          # Can be used to return data from functions
declare MyReturn1='';         # Can be used to return data from functions
# Formatting
declare SPACE='\x20';
declare HELP_TAB="&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
# Editors
declare EDITOR=nano;
declare -a EDITORS=("nano" "emacs" "vi" "vim" "joe");
# AUTOMATICALLY DETECTS THE SYSTEM LANGUAGE {{{
# automatically detects the system language based on your locale
declare LANGUAGE="$(locale | sed '1!d' | sed 's/LANG=//' | cut -c1-5)"; # en_US
declare LOCALE="$LANGUAGE"; # en_US
declare -a COUNTRIES=("Australia" "Belarus" "Belgium" "Brazil" "Bulgaria" "Canada" "Chile" "China" "Colombia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "India" "Ireland" "Israel" "Italy" "Japan" "Kazakhstan" "Korea" "Macedonia" "Netherlands" "New Caledonia" "New Zealand" "Norway" "Poland" "Portugal" "Romania" "Russian Federation" "Serbia" "Singapore" "Slovakia" "South Africa" "Spain" "Sri Lanka" "Sweden" "Switzerland" "Taiwan" "Ukraine" "United Kingdom" "United States" "Uzbekistan" "Viet Nam");
declare -a COUNTRY_CODES=("AU" "BY" "BE" "BR" "BG" "CA" "CL" "CN" "CO" "CZ" "DK" "EE" "FI" "FR" "DE" "GR" "HU" "IN" "IE" "IL" "IT" "JP" "KZ" "KR" "MK" "NL" "NC" "NZ" "NO" "PL" "PT" "RO" "RU" "RS" "SG" "SK" "ZA" "ES" "LK" "SE" "CH" "TW" "UA" "GB" "US" "UZ" "VN");
declare COUNTRY_CODE=${LOCALE#*_}; # en_US = en-US = US
declare COUNTRY="United States";
declare LANGUAGE_LO="en-US";
declare LANGUAGE_HS="en";
declare LANGUAGE_AS="en";
declare LANGUAGE_KDE="en_gb";
declare LANGUAGE_FF="en-us"; # af ak ar as ast be bg bn-bd bn-in br bs ca cs csb cy da de el en-gb en-us en-za eo es-ar es-cl es-es es-mx et eu fa ff fi fr fy-nl ga-ie gd gl gu-in he hi-in hr hu hy-am id is it ja kk km kn ko ku lg lij lt lv mai mk ml mr nb-no nl nn-no nso or pa-in pl pt-br pt-pt rm ro ru si sk sl son sq sr sv-se ta ta-lk te th tr uk vi zh-cn zh-tw zu
declare LANGUAGE_CALLIGRA="en";
declare KEYBOARD="us"; # used to drill down into more specific layouts for some; not the same as KEYMAP necessarily
declare KEYMAP="us";
declare ZONE="America";
declare SUBZONE="Los_Angeles";
# OS Info
declare My_OS='';                        # OS: Linux, FreeBSD, MAC, Windows
declare My_DIST='';                      # CentOS, Arch Linux, Debian, Redhat
declare My_PSUEDONAME='';                # PSUEDONAME
declare My_ARCH='';                      # x86 or x86_64
declare My_Ver='';                       # OS Version
declare My_Ver_Major='';                 # Major Version Number
declare My_Ver_Minor='';                 # Major Version Number
declare My_OS_Update="";              # Patch Number
declare My_OS_Package="";
# Video
declare -i VIDEO_CARD=7;
declare -a VIDEO_CARDS=( "nVidia" "Nouveau" "Intel" "ATI" "Vesa" "Virtualbox" "Skip" );
# Menu Global's
declare -i LAST_MENU_ITEM=0;
declare BREAKABLE_KEY="";
#
declare -i T_COLS=0; # Used in Printing to the Screen
#
declare prompt1="$(gettext -s  "ENTER-OPTION")";
declare prompt2="$(gettext -s  "ENTER-OPTIONS")";
declare Status_Bar_1="$(gettext -s  "Make-Choose")";
declare Status_Bar_2=" ";
# COLORS {{{
# Text color variables
# Regular Colors
declare Black='\e[0;30m';        # Black
declare Blue='\e[0;34m';         # Blue
declare Cyan='\e[0;36m';         # Cyan
declare Green='\e[0;32m';        # Green
declare Purple='\e[0;35m';       # Purple
declare Red='\e[0;31m';          # Red
declare White='\e[0;37m';        # White
declare Yellow='\e[0;33m';       # Yellow
# Bold
declare BBlack='\e[1;30m';       # Black
declare BBlue='\e[1;34m';        # Blue
declare BCyan='\e[1;36m';        # Cyan
declare BGreen='\e[1;32m';       # Green
declare BPurple='\e[1;35m';      # Purple
declare BRed='\e[1;31m';         # Red
declare BWhite='\e[1;37m';       # White
declare BYellow='\e[1;33m';      # Yellow
# Background
declare BgBlack='\e[0;40m';      # Black
declare BgBlue='\e[0;44m';       # Blue
declare BgCyan='\e[0;46m';       # Cyan
declare BgGreen='\e[0;42m';      # Green
declare BgPurple='\e[0;45m';     # Purple
declare BgRed='\e[0;41m';        # Red
declare BgWhite='\e[0;47m';      # White
declare BgYellow='\e[0;43m';     # Yellow
#}}}
# Menu Theme
declare -a MenuTheme=( "${BYellow}" "${White}" ")" );
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    echo -e "\t${BYellow}Start wizard.sh Test ${White} @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -----------------------------------------------------------------------------
declare -i CREATE_HELP=1
#
# CREATE HELP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="create_help";
    USAGE="$(gettext -s  "CREATE-HELP-USAGE")";
    DESCRIPTION="$(gettext -s  "CREATE-HELP-DESC")";
    NOTES="$(gettext -s  "CREATE-HELP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="1 OCT 2012";
    REVISION="1 NOV 2012";
fi
# -------------------------------------
create_help()
{
    if [[ "$RUN_HELP" -eq 0 ]]; then return 0; fi
    if [[ "$CREATE_HELP" -eq 1 ]]; then
        echo "$(gettext -s "CREATE-HELP-WORKING")";
        CREATE_HELP=0;
    fi
    echo -n ".";
    #echo "> $1";
    MY_HELP="<p class=\"function\" style=\"font-family:'Courier New'\"><span style=\"color:Crimson\">NAME&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $1</span> <br /><span style=\"color:Blue\">USAGE&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $2  </span><br /><span style=\"color:DarkBlue\">DESCRIPTION: $3  </span><br /><span style=\"color:RoyalBlue\">NOTES&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $4  </span><br /><span style=\"color:Red\">AUTHOR&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $5  </span><br /><span style=\"color:Cyan\">VERSION&nbsp;&nbsp;&nbsp;&nbsp;: $6  </span><br /><span style=\"color:DarkRed\">CREATED&nbsp;&nbsp;&nbsp;&nbsp;: $7  </span><br /><span style=\"color:FireBrick\">REVISION&nbsp;&nbsp;&nbsp;: $8  </span><br /><span style=\"color:Teal\">LINENO&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $9 </span></p>";
    HELP_ARRAY[$[${#HELP_ARRAY[@]}]]="$MY_HELP";
}
if [[ "$RUN_HELP" -eq 1 ]]; then
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
#}}}
# -----------------------------------------------------------------------------
# DEBUGGER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="debugger";
    USAGE="$(gettext -s "DEBUGGER-USAGE")";
    DESCRIPTION="$(gettext -s "DEBUGGER-DESC")";
    NOTES="$(gettext -s "DEBUGGER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
debugger()
{
    if [[ "$1" -eq 1 ]]; then
        set -v; set -x;
    else
        set +v; set +x;
    fi
}
#}}}
# -----------------------------------------------------------------------------
declare -i ARR_INDEX=0;
declare SearchMyArray="";
#
# IS IN ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_in_array";
    USAGE="$(gettext -s "IS-IN-ARRAY-USAGE")";      # is_in_array 1->(Array{@}) 2->(Search)
    DESCRIPTION="$(gettext -s "IS-IN-ARRAY-DESC")";
    NOTES="$(gettext -s "IS-IN-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_in_array()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    [[ -z "$1" ]] && return 1;
    local -a array=("${!1}");          # Cast as Array 'array[@]'
    local -i index=0;
    for index in "${!array[@]}"; do
        if [ "$2" == "${array[$index]}" ]; then
            ARR_INDEX="$index"; # used if you want to know what the index is
            return 0; # Return true
        fi
    done
    return 1; # Return false
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArrary=( "1" "2" "3" );
    if is_in_array "MyArrary[@]" "2" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_in_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_in_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# PRINT HELP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_help";
    USAGE="print_help";
    DESCRIPTION="$(gettext -s "PRINT-HELP-DESC")";
    NOTES="$(gettext -s "PRINT-HELP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="1 OCT 2012";
    REVISION="1 NOV 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_help()
{
    echo "<!DOCTYPE html>" > "${FULL_SCRIPT_PATH}/help.html";
    echo "<html>" >> "${FULL_SCRIPT_PATH}/help.html";
    echo "<body>" >> "${FULL_SCRIPT_PATH}/help.html";
    echo "$(gettext -s "PRINT-HELP-TITLE"): $DATE_TIME" >> "${FULL_SCRIPT_PATH}/help.html";
    show_help  >> "${FULL_SCRIPT_PATH}/help.html";
    show_custom_help >> "${FULL_SCRIPT_PATH}/help.html"; # Must be defined in Custom Script
    echo "<hr />" >> "${FULL_SCRIPT_PATH}/help.html";
    if [[ "${#HELP_ARRAY}" -ne 0 ]]; then
        local -i index=0;
        for index in "${!HELP_ARRAY[@]}"; do
            echo "$(gettext -s "PRINT-HELP-FUNCT") #$index" >> "${FULL_SCRIPT_PATH}/help.html";
            echo "${HELP_ARRAY[$index]}" >> "${FULL_SCRIPT_PATH}/help.html";
            echo "<hr />" >> "${FULL_SCRIPT_PATH}/help.html";
        done
    else
        print_error "PRINT-HELP-ERROR";
    fi
    echo "" >> "${FULL_SCRIPT_PATH}/help.html";
    echo "" >> "${FULL_SCRIPT_PATH}/help.html";
    echo "</body>" >> "${FULL_SCRIPT_PATH}/help.html";
    echo "</html>" >> "${FULL_SCRIPT_PATH}/help.html";
    echo '';
    print_info "Help Printed to ${FULL_SCRIPT_PATH}/help.html";
}
#}}}
# -----------------------------------------------------------------------------
declare progress=( "-" "\\" "|" "/" );
declare -i progresion=0;
declare -i CREATE_LOCALIZER=1
# LOCALIZE INFO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="localize_info";
    USAGE="$(gettext -s "LOCALIZE-INFO-USAGE")";
    DESCRIPTION="$(gettext -s "LOCALIZE-INFO-DESC")";
    NOTES="$(gettext -s "LOCALIZE-INFO-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
localize_info()
{
    # localize_info 1->(Localize ID) 2->(Message to Localize) 3->(Comment)
    [[ "$RUN_LOCALIZER" -eq 0 ]] && return 0;
    if [[ "$CREATE_LOCALIZER" -eq 1 ]]; then
        echo "Localizer Working...";
        CREATE_LOCALIZER=0;
    fi
    echo -en "\b${progress[$((progresion++))]}";
    [[ "$progresion" -ge 3 ]] && progresion=0;
    #
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    [ -z "$1" ] && return 1;
    [ -z "$2" ] && return 1;
    #echo ">: $1"
    # Check to see if its in Array
    if [[ "${#LOCALIZE_ID[*]}" -eq 0 ]]; then
        LOCALIZE_ID[0]="$1";
        LOCALIZE_MSG[0]="$2";
        LOCALIZE_COMMENT[0]="$3";
    else
        if ! is_in_array "LOCALIZE_ID[@]" "$1" ; then
            LOCALIZE_ID[${#LOCALIZE_ID[*]}]="$1";
            LOCALIZE_MSG[${#LOCALIZE_MSG[*]}]="$2";
            LOCALIZE_COMMENT[${#LOCALIZE_COMMENT[*]}]="$3";
        fi
    fi
    # if [[ "$DEBUGGING" -eq 1 ]]; then echo "localize_info (ID = [$1] - Message = [$2] at line number: [$3])"; fi
}
#}}}
# -----------------------------------------------------------------------------
# LOCALIZE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="localize";
    USAGE="localize 1->(Localize ID) 2->(Optional: Print this with no Localization)";
    DESCRIPTION="$(gettext -s "LOCALIZE-DESC")";
    NOTES="$(gettext -s "LOCALIZE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# Help file Localization
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "LOCALIZE-DESC"  "Localize Text, look up ID and return Localized string." "Comment: localize @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOCALIZE-NOTES" "Localized. Used to Centralized the Localization Function, also to add more Functionality." "Comment: localize @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
localize()
{
    if [ "$#" -eq "1" ]; then
        echo -e "$(gettext -s "$1")";
    else
        echo -e "$(gettext -s "$1") $2";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# PRINT LINE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_line";
    USAGE="print_line";
    DESCRIPTION="$(gettext -s "PRINT-LINE-DESC")";
    NOTES="$(gettext -s "PRINT-LINE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-LINE-DESC"  "Prints a line of dashes --- across the screen." "Comment: print_line @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-LINE-NOTES" "None." "Comment: print_line @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_line()
{
    printf "%$(tput cols)s\n" | tr ' ' '-';
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PAUSE FUNCTION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="pause_function";
    USAGE="$(gettext -s "PAUSE-FUNCTION-USAGE")";        # pause_function 1->(Description) 2->(Debugging Information)
    DESCRIPTION="$(gettext -s "PAUSE-FUNCTION-DESC")";
    NOTES="$(gettext -s "PAUSE-FUNCTION-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
pause_function()
{
    print_line;
    tput sgr0;
    if [[ "$#" -eq 1 ]]; then
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE") [$1]...";
    else
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE") [$1] - [$2]...";
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# IS STRING IN FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_string_in_file";
    USAGE="$(gettext -s "IS-STRING-IN-FILE-USAGE")";      # is_string_in_file 1->(/full-path/file) 2->(search for string)
    DESCRIPTION="$(gettext -s "IS-STRING-IN-FILE-DESC")";
    NOTES="$(gettext -s "IS-STRING-IN-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_string_in_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$2" ]; then return 1; fi
    if [[ -e "$1" || -L "$1" || -f "$1" ]]; then # @FIX Do I need to do all this?
        count="$(egrep -ic "$2" "$1")";
        [[ "$count" -gt 0 ]] && return 0;
    else
        # Do not try this; re-cyclic - write_error "IS-STRING-IN-FILE-FNF" "($1) - ($2) -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        echo -e "\t${BRed} $(gettext -s "IS-STRING-IN-FILE-FNF") is_string_in_file ($1) - ($2) ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    fi
    return 1
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_string_in_file "${FULL_SCRIPT_PATH}/wizard.sh" "# DO NOT EDIT THE TEXT ON THIS LINE" ; then # look for this static text
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_string_in_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_string_in_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# WRITE ERROR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="write_error";
    USAGE="$(gettext -s "WRITE-ERROR-USAGE")";
    DESCRIPTION="$(gettext -s "WRITE-ERROR-DESC")";
    NOTES="$(gettext -s "WRITE-ERROR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
write_error()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BYellow} ($#) |$@| ${BWhite} ->  ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]} ${White}"; exit 1; fi
    if [ ! -f "$ERROR_LOG" ]; then
        [[ ! -d "$LOG_PATH" ]] && (mkdir -p "$LOG_PATH");
        touch "$ERROR_LOG";
    fi
    echo "$(gettext -s "$1") ($2)" >> "$ERROR_LOG";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    write_error "MY-ERROR-WRITE-ERROR" "write_error @ $(basename $BASH_SOURCE) : $LINENO";
    if is_string_in_file "${ERROR_LOG}" "MY-ERROR-WRITE-ERROR" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  write_error ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  write_error ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# TRIM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="trim";
    USAGE="trim 1->( String to Trim )";
    DESCRIPTION="$(gettext -s "TRIM-DESC")";
    NOTES="$(gettext -s "TRIM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="21 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
trim()
{
    echo "$(rtrim "$(ltrim "$1")")";
}
#}}}
# -----------------------------------------------------------------------------
# LEFT TRIM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="ltrim";
    USAGE="ltrim 1->( String to Trim )";
    DESCRIPTION="$(gettext -s "LEFT-TRIM-DESC")";
    NOTES="$(gettext -s "LTRIM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
ltrim()
{
    # Remove Left or Leading Space
    echo "$1" | sed 's/^ *//g';
}
#}}}
# -----------------------------------------------------------------------------
# RIGHT TRIM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="rtrim";
    USAGE="$(gettext -s "RIGHT-TRIM-USAGE")";
    DESCRIPTION="$(gettext -s "RIGHT-TRIM-DESC")";
    NOTES="$(gettext -s "RTRIM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
rtrim()
{
    # Remove Right or Trailing Space
    [ -z "$1" ] && return 1;
    echo "$1" | sed 's/ *$//g';
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then  # Test All Trim Functions together
    MY_SPACE=' Left and Right '
    if [[ $(rtrim "$MY_SPACE") == ' Left and Right' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  rtrim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  rtrim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    if [[ $(ltrim "$MY_SPACE") == 'Left and Right ' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ltrim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  ltrim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    if [[ $(trim "$MY_SPACE") == 'Left and Right' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  trim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  trim ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
#
# IS NEEDLE IN HAYSTACK {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_needle_in_haystack";
    USAGE="$(gettext -s "IS-NEEDLE-IN-HAYSTACK-USAGE")";       # is_needle_in_haystack 1->(Needle to search in Haystack) 2->(Haystack to search in) 3->(Type of Search: 1=Exact, 2=Beginning, 3=End, 4=Middle, 5=Anywhere, 6=Anywhere Exactly)
    DESCRIPTION="$(gettext -s "IS-NEEDLE-IN-HAYSTACK-DESC")";
    NOTES="$(gettext -s "IS-NEEDLE-IN-HAYSTACK-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="22 Jan 2013";
    REVISION="22 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_needle_in_haystack()
{
    if [[ "$1" != *"$2"* ]]; then
        if [[ "$2" != *" "* ]]; then # Check to see if it has Spaces, then test it like an Array
            return 1;
        fi
    fi # If it not in the String return 1 for false
    local -i SearchResults=0;
    case $2 in # Haystack
        "$1") SearchResults=1 ;; # Match Exact Haystack String
       "$1"*) SearchResults=2 ;; # Match Beginning of Haystack String
       *"$1") SearchResults=3 ;; # Match End of Haystack String
      *"$1"*) SearchResults=4 ;; # Needle String can be anywhere in the Haystack String
    esac
    if [[ "$SearchResults" -eq "$3" ]]; then # SearchResults=0-4
        return 0;
    else
        if [[ "$3" -ge "5" ]]; then                     # Anywhere in String
            if [[ "$SearchResults" -ne "0" && "$3" -ne "6" ]]; then # SearchResults=0-4 - 0=No Found
                if [[ "$RUN_TEST" -eq 3 ]]; then echo "SearchResults=$SearchResults return at line $LINENO"; fi
                return 0;
            else                                            # Check it like its an Array
                local -a MyNeedle=( $(echo "$1") );         # Create an Array from the Needle
                local -a Haystack=( $(echo "$2") );         # Create an Array from the Haystack
                local -i MyNeedleTotal="${#MyNeedle[@]}";   # 1 or Greater
                local -i index=0;                           # Index
                local -i HayStackIndex=0;                   # Index
                local -i H_Counter=0;                       # H_Counter how many times we find it
                local -a FoundIndex=();                     #
                trak=0
                if [[ "$3" -eq "5" ]]; then                 # Anywhere Exactly in String: Haystack=1ABS 2ABS 1POS 2POS and Needle=ABS POS,
                    for HayStackIndex in "${!Haystack[@]}"; do
                        ((trak++));
                        for index in "${!MyNeedle[@]}"; do
                            local -i SearchResults=0;
                            case ${Haystack[$HayStackIndex]} in # Haystack Array
                                "${MyNeedle[$index]}") SearchResults=1 ;; # Match Exact Haystack String
                               "${MyNeedle[$index]}"*) SearchResults=2 ;; # Match Beginning of Haystack String
                               *"${MyNeedle[$index]}") SearchResults=3 ;; # Match End of Haystack String
                              *"${MyNeedle[$index]}"*) SearchResults=4 ;; # Needle String can be anywhere in the Haystack String
                            esac
                            if [[ "$SearchResults" -ne "0" ]]; then # SearchResults=0-4 - 0=No Found
                                if [[ "${#FoundIndex[@]}" -eq 0 ]]; then
                                    if [[ "$RUN_TEST" -eq 3 ]]; then echo "5. Needle=${MyNeedle[$index]} | SearchResults=$SearchResults | index=$index"; fi
                                    array_push "FoundIndex" "$index";
                                    ((H_Counter++));
                                else
                                    if ! is_in_array "FoundIndex[@]" "$index" ; then
                                        if [[ "$RUN_TEST" -eq 3 ]]; then echo "5. Needle=${MyNeedle[$index]} | SearchResults=$SearchResults | index=$index"; fi
                                        array_push "FoundIndex" "$index";
                                        ((H_Counter++));
                                    fi
                                fi
                            fi
                        done
                    done
                    if [[ "$RUN_TEST" -eq 3 ]]; then echo "H_Counter=$H_Counter and MyNeedleTotal=$MyNeedleTotal"; fi
                    if [[ "$H_Counter" -eq "$MyNeedleTotal" ]]; then   # Keep in mind that we need another
                        return 0;
                    else
                        return 1;
                    fi
                else
                    for index in "${!MyNeedle[@]}"; do
                        if is_in_array "Haystack[@]" "${MyNeedle[$index]}" ; then
                            if [[ "$RUN_TEST" -eq 3 ]]; then echo "Found ${MyNeedle[$index]}"; fi
                            if [[ "$3" -eq "6" ]]; then        # Anywhere Exactly in String: Haystack=12 13 and Needle=1 3,
                                if [[ "$RUN_TEST" -eq 3 ]]; then echo "6. Needle=${MyNeedle[$index]} | SearchResults=$SearchResults | ARR_INDEX=$ARR_INDEX"; fi
                                ((H_Counter++));
                            fi
                        else
                            if [[ "$RUN_TEST" -eq 3 ]]; then echo "Not Found ${MyNeedle[$index]}"; fi
                        fi
                    done
                    if [[ "$RUN_TEST" -eq 3 ]]; then echo "H_Counter=$H_Counter and MyNeedleTotal=$MyNeedleTotal"; fi
                    if [[ "$H_Counter" -eq "$MyNeedleTotal" ]]; then   # Keep in mind that we need another
                        return 0;
                    else
                        return 1;
                    fi
                fi
            fi
        else
            return 1;
        fi
    fi
    return 1; # We should never make it, but if we do, its an error
}
#}}}
# -----------------------------------------------------------------------------
#
# STRING LEN {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="string_len";
    USAGE="$(gettext -s "STRING-LEN-USAGE")";
    DESCRIPTION="$(gettext -s "STRING-LEN-DESC")";
    NOTES="$(gettext -s "STRING-LEN-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="25 Jan 2013";
    REVISION="25 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
string_len()
{
    echo "${#1}";
    #echo "$(expr "$1" : '.*')"; # Use C Function
    # Fix in old code before removing
    #return $(expr "$1" : '.*'); # Use C Function
    return "${#1}" # Uses Bash
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='A2C4E6';
    if [[ "$(string_len "$MyString")" == '6' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  string_len ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  string_len ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# STRIP LEADING CHAR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="strip_leading_char";
    USAGE="$(gettext -s "STRIP-LEADING-CHAR-USAGE")";
    DESCRIPTION="$(gettext -s "STRIP-LEADING-CHAR-DESC")";
    NOTES="$(gettext -s "STRIP-LEADING-CHAR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="25 Jan 2013";
    REVISION="25 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
strip_leading_char()
{
    echo "${1#${2}}";    #  The "1" refers to "$1" which is string and "2" is Char to remove
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='/A2C4E6'; # Should pass without / in it also
    if [[ "$(strip_leading_char "$MyString" "/")" == 'A2C4E6' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} strip_leading_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  strip_leading_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# STRIP TRAILING CHAR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="strip_trailing_char";
    USAGE="$(gettext -s "STRIP-TRAILING-CHAR-USAGE")";
    DESCRIPTION="$(gettext -s "STRIP-TRAILING-CHAR-DESC")";
    NOTES="$(gettext -s "STRIP-TRAILING-CHAR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="25 Jan 2013";
    REVISION="25 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
strip_trailing_char()
{
    echo "${1%${2}}";    #  The "1" refers to "$1" which is string and "2" is Char to remove
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='/A2C4E6/'; # Should pass without / in it also
    if [[ "$(strip_trailing_char "$MyString" "/")" == '/A2C4E6' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} strip_trailing_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  strip_trailing_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# ADD TRAILING CHAR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_trailing_char";
    USAGE="$(gettext -s "ADD-TRAILING-CHAR-USAGE")";
    DESCRIPTION="$(gettext -s "ADD-TRAILING-CHAR-DESC")";
    NOTES="$(gettext -s "ADD-TRAILING-CHAR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="25 Jan 2013";
    REVISION="25 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_trailing_char()
{
    if [[ "${1#${1%?}}" == $2 ]]; then
        echo "${1}"; #  The "1" refers to "$1" which is string and "2" is Char to remove
    else
        echo "${1}${2}";
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='/A2C4E6'; # Should pass with / in it also
    if [[ "$(add_trailing_char "$MyString" "/")" == '/A2C4E6/' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} add_trailing_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_trailing_char ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# SUB STRING {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="sub_string";
    USAGE="$(gettext -s "SUB-STRING-USAGE")";       # sub_string 1->('String') 2->(Search) 3->(1=Beginning, 2=End, 3=Remove)
    DESCRIPTION="$(gettext -s "SUB-STRING-DESC")";
    NOTES="$(gettext -s "SUB-STRING-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="25 Jan 2013";
    REVISION="25 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
sub_string()
{
    local length="${#2}";
    local index=$(expr index "$1" "$2");
    local beginning=$((index-1));
    local ending=$((beginning+length));
    local MyString='';
    if [[ "$3" -eq 1 ]]; then   # Beginning: 'Beginning Search Ending'
        MyString="${1:0:$beginning}";
    elif [[ "$3" -eq 2 ]]; then # End: 'Beginning Search Ending'
        MyString="${1:$ending}";
    elif [[ "$3" -eq 3 ]]; then # Remove: 'Beginning Search Ending'
        MyString="${1:0:$beginning}${1:$ending}";
    fi
    echo "$MyString";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 || "$RUN_TEST" -eq 2 || "$RUN_TEST" -eq 3 ]]; then
    # 'MainItem 10: SubItem 10'
    MySeperator=":";
    MyStringBeginning='MainItem 10';
    MyStringEnd=' SubItem 10';
    MyStringOriginal="${MyStringBeginning}${MySeperator}${MyStringEnd}";
    MyReturn=$(sub_string "$MyStringOriginal" "$MySeperator" 1);
    if [[ "$MyReturn" == "$MyStringBeginning" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} sub_string [$MyStringOriginal] 1 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED") ${BWhite} sub_string [$MyStringOriginal] 1 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    MyReturn=$(sub_string "$MyStringOriginal" "$MySeperator" 2);
    if [[ "$MyReturn" == "$MyStringEnd" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} sub_string [$MyStringOriginal] 2 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED") ${BWhite} sub_string [$MyStringOriginal] 2 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    MyReturn=$(sub_string "$MyStringOriginal" "$MySeperator" 3);
    if [[ "$MyReturn" == "${MyStringBeginning}${MyStringEnd}" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED") ${BWhite} sub_string [$MyStringOriginal] 3 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED") ${BWhite} sub_string [$MyStringOriginal] 3 <- [${MyReturn}] ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# STRING SPLIT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="string_split";
    USAGE="$(gettext -s "STRING-SPLIT-USAGE")";     # string_split 1->('String') 2->(delimitor) 3->(section:1=First,2=Second...)
    DESCRIPTION="$(gettext -s "STRING-SPLIT-DESC")";
    NOTES="$(gettext -s "STRING-SPLIT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.1";
    CREATED="25 Jan 2013";
    REVISION="26 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
string_split()
{
    OLD_IFS="$IFS"; IFS=$"$2"; # Very Important
    local -i Counter=0; local MySection='';
    local -a MyArr=($(echo "$1")); # Automatically converts it to an Array removing the delimiters
    IFS=$' ';
    for MySection in "${MyArr[@]}" ; do
        ((Counter++));
        if [[ "$Counter" -eq "$3" ]]; then echo "$MySection"; fi
    done
    IFS="$OLD_IFS";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='section-1:section-2:section-3';
    if [[ "$(string_split "$MyString" ":" 1):$(string_split "$MyString" ":" 2):$(string_split "$MyString" ":" 3)" == "$MyString" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  string_split ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  string_split ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# STRING REPLACE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="string_replace";
    USAGE="$(gettext -s "STRING-REPLACE-USAGE")";     # string_replace 1->('String') 2->(Replace) 3->(With this)
    DESCRIPTION="$(gettext -s "STRING-REPLACE-DESC")";
    NOTES="$(gettext -s "STRING-REPLACE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.1";
    CREATED="25 Jan 2013";
    REVISION="26 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
string_replace()
{
    echo "${1//$2/$3}";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='domain.com';
    if [[ "$(string_replace "$MyString" '.' '_')" == 'domain_com' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  string_replace ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  string_replace ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# LOAD 2D ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="load_2d_array";
    USAGE="$(gettext -s "LOAD-2D-ARRAY-USAGE")";
    DESCRIPTION="$(gettext -s "LOAD-2D-ARRAY-DESC")";
    NOTES="$(gettext -s "LOAD-2D-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
load_2d_array()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -f "$1" ]; then
        local lines=();
        local line="";
        local OLD_IFS="$IFS"; IFS=$' '; # You would think you need to use IFS=$'\n\t' since its a file, but what it needs to do is expand the spaces
        while read line; do
            lines=($line); # Stored Data - Do not quote
            echo -e "${lines[$2]}";
        done < "$1"; # Load Array from serialized disk file
        IFS="$OLD_IFS";
    else
        echo -e "${BRed}$(gettext -s "LOAD-2D-ARRAY-MISSING") :${White} $1";
        write_error "LOAD-2D-ARRAY-MISSING" ": $1 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        exit 1;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
    if [ ! -f "${FULL_SCRIPT_PATH}/gtranslate-cc.db" ]; then # Create 2D Array
        echo "Afrikaans af"               > "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Albanian sq"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Arabic ar"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Azerbaijani az"            >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Basque eu"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Bengali bn"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Belarusian be"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Bulgarian bg"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Catalan ca"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Chinese-Simplified zh-CN"  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Chinese-Traditional zh-TW" >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Croatian hr"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Czech cs"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Danish da"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Dutch nl"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "English en"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Esperanto eo"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Estonian et"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Filipino tl"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Finnish fi"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "French fr"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Galician gl"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Georgian ka"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "German de"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Greek el"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Gujarati gu"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Haitian Creole ht"         >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Hebrew iw"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Hindi hi"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Hungarian hu"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Icelandic is"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Indonesian id"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Irish ga"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Italian it"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Japanese ja"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Kannada kn"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Korean ko"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Latin la"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Latvian lv"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Lithuanian lt"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Macedonian mk"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Malay ms"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Maltese mt"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Norwegian no"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Persian fa"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Polish pl"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Portuguese pt"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Romanian ro"               >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Russian ru"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Serbian sr"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Slovak sk"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Slovenian sl"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Spanish es"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Swahili sw"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Swedish sv"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Tamil ta"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Telugu te"                 >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Thai th"                   >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Turkish tr"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Ukrainian uk"              >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Urdu ur"                   >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Vietnamese vi"             >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Welsh cy"                  >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
        echo "Yiddish yi"                >> "${FULL_SCRIPT_PATH}/gtranslate-cc.db";
    fi
    LanguagesTranslate=( $(load_2d_array "${FULL_SCRIPT_PATH}/gtranslate-cc.db" "0" ) ); # 1 is for Country
    if is_in_array "LanguagesTranslate[@]" "English" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  load_2d_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  load_2d_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    LanguagesTranslate=( $(load_2d_array "${FULL_SCRIPT_PATH}/gtranslate-cc.db" "1" ) ); # 1 is for Country Code
    if is_in_array "LanguagesTranslate[@]" "en" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  load_2d_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  load_2d_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    IFS="$OLD_IFS";
fi
#}}}
# -----------------------------------------------------------------------------
#
# LOCALIZE SAVE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="localize_save";
    USAGE="$(gettext -s "LOCALIZE-SAVE-USAGE")";
    DESCRIPTION="$(gettext -s "LOCALIZE-SAVE-DESC")";
    NOTES="$(gettext -s "LOCALIZE-SAVE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sept 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
localize_save()
{
    # http://www.gnu.org/savannah-checkouts/gnu/gettext/manual/html_node/PO-Files.html
    #
    if [[ "$RUN_LOCALIZER" -eq 0 ]]; then return 0; fi
    echo "localize_save..." # No way to Localize this
    if [[ "$LOCALIZED_FILES_SAFE" -eq 0 ]]; then
        if [ -d "${LOCALIZED_PATH}/" ]; then
            remove_folder "${LOCALIZED_PATH}/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    fi
    #
    make_dir "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/LC_MESSAGES/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    #
    echo "# Translation File"    >  "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Overwrite
    echo ""                     >>  "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Appends
    #
    local -i total="${#LOCALIZE_ID[@]}";
    local -i LanguagesIndex=0;
    echo "Localized total=$total";
    #
    for LanguagesIndex in "${!LOCALIZE_ID[@]}"; do
        echo -en "\b${progress[$((progresion++))]}"; [[ "$progresion" -ge 3 ]] && progresion=0;
        echo "# ${LOCALIZE_COMMENT[$LanguagesIndex]} -> ${LOCALIZE_MSG[$LanguagesIndex]}" >> "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Comment
        echo "msgid \"${LOCALIZE_ID[$LanguagesIndex]}\""                                  >> "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Message ID
        echo "msgstr \"${LOCALIZE_MSG[$LanguagesIndex]}\""                                >> "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Message String
        echo ""                                                                           >> "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po"; # Empty Line
    done
    msgfmt -o "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/LC_MESSAGES/${LOCALIZED_FILE}.mo" "${LOCALIZED_PATH}/${DEFAULT_LOCALIZED_LANG}/${DEFAULT_LOCALIZED_LANG}.po";
    #
    TRANSLATOR="simulate"; # moses google bing apertium
    local -a LanguagesTranslate=( "af" "ca" "de" "es" "fr" "ga" "gl" "hi" "it" "lt" "lv" "mt" "nl" "pl" "pt" "sq" );
    if [[ "$TRANSLATOR" == "simulate" ]]; then
        LanguagesTranslate=( "de" );
    elif [[ "$TRANSLATOR" == "google" ]]; then
        LanguagesTranslate=( $(load_2d_array "${FULL_SCRIPT_PATH}/gtranslate-cc.db" "1" ) ); # 1 is for Code
    elif [[ "$TRANSLATOR" == "bing" ]]; then
        echo "Bing Translator";
        # Available for free up to 5,000 queries per month
        # curl 'http://api.apertium.org/json/translate?q=hello%20world&langpair=en%7Ces&callback=foo'
        #       http://api.apertium.org/json/translate?q=QUIT&langpair=en%7Csq
        # %7C = | (vertical bar)
    elif [[ "$TRANSLATOR" == "apertium" ]]; then
        TRANSURL="http://api.apertium.org/json/translate";
        echo "set URL";
        LanguagesTranslate=( "af" "ca" "de" "es" "fr" "ga" "gl" "hi" "it" "lt" "lv" "mt" "nl" "pl" "pt" "sco" "sq" );
        API_Key="$API_KEY_APERTIUM"; # @FIX config add API key
    elif [[ "$TRANSLATOR" == "moses" ]]; then
        LanguagesTranslate=( "af" "ca" "de" "es" "fr" "ga" "gl" "hi" "it" "lt" "lv" "mt" "nl" "pl" "pt" "sco" "sq" );
    fi
    #
    local -i transTotal="${#LanguagesTranslate[@]}";
    #echo "transTotal=$transTotal";
    local LocalePath="";
    local RETURN_TRANS='';
    local -i index=0;
    for LanguagesIndex in "${!LanguagesTranslate[@]}"; do
        #echo "LanguagesIndex=$LanguagesIndex";
        LocalePath="${LOCALIZED_PATH}/${LanguagesTranslate[$LanguagesIndex]}/${LanguagesTranslate[$LanguagesIndex]}.po"; # [/script/locale]/lang/lang.po
        #echo "LocalePath=$LocalePath";
        make_dir "${LOCALIZED_PATH}/${LanguagesTranslate[$LanguagesIndex]}/LC_MESSAGES/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        echo '';
        echo "${LanguagesTranslate[$LanguagesIndex]}";

        for index in "${!LOCALIZE_ID[@]}"; do
            echo -en "\b${progress[$((progresion++))]}"; [[ "$progresion" -ge 3 ]] && progresion=0;
            if [ ! -f "$LocalePath" ]; then touch "$LocalePath"; fi # We do not want to overwrite it
            # This file may exist and may have hand translated entries, so to be safe; only create those entries that do not exist
            # Delete all files prior to calling this, if you want this function to create all new content.
            if ! is_string_in_file "$LocalePath" "msgid \"${LOCALIZE_ID[$index]}\"" ; then
                if [[ "$TRANSLATOR" == "simulate" ]]; then
                    RETURN_TRANS="${LOCALIZE_MSG[$index]}";
                elif [[ "$TRANSLATOR" == "moses" ]]; then
                    # $HOME
                    ~/mosesdecoder/bin/moses -f phrase-model/moses.ini < "${LOCALIZE_MSG[$index]}" > RESPONSE;
                    ~/mosesdecoder/bin/moses -f phrase-model/moses.ini < "Test" > RESPONSE;
                    RETURN_TRANS="$(echo "$RESPONSE" | cut -d ':' -f 3 | cut -d '}' -f 1)";
                elif [[ "$TRANSLATOR" == "google" ]]; then
                    LANGPAIR="en%7C${LanguagesTranslate[$LanguagesIndex]}"; # "en|${LanguagesTranslate[$LanguagesIndex]}"
                    #echo "LANGPAIR=$LANGPAIR";
                    #PSTRING="$(echo "${LOCALIZE_MSG[$index]}" | tr ' ' '%20')"; # +
                    PSTRING=${LOCALIZE_MSG[$index]// /%20};
                    echo "PSTRING=$PSTRING";
                    # PSTRING=Invalid%Option
                    # Get translation
                    echo "URL=${TRANSURL}?q=${PSTRING}&langpair=${LANGPAIR}&key=${API_Key}";
                    # URL=http://api.apertium.org/json/translate?q=Load%20Software:%20Will%20install%20Software%20Packages%20from%20above%20option.&langpair=en%7Ces&key=cwZdfGDhEkATSCydtSVYI7e3LI4
                    RESPONSE="$(/usr/bin/env curl -s -A Mozilla ${TRANSURL}?q=${PSTRING}&langpair=${LANGPAIR}&key=${API_Key})"; # '&langpair='$LANGPAIR'&q='$PSTRING
                    # Parse and clean response, to show only translation.
                    RETURN_TRANS="$(echo "$RESPONSE" | cut -d ':' -f 3 | cut -d '}' -f 1)";
                fi
                #
                echo "# ${LOCALIZE_COMMENT[$index]} -> ${LOCALIZE_MSG[$index]}" >> "$LocalePath"; # Comment
                echo "msgid \"${LOCALIZE_ID[index]}\""                          >> "$LocalePath"; # Message ID
                echo "msgstr \"${RETURN_TRANS}\""                               >> "$LocalePath"; # Message
                echo ""                                                         >> "$LocalePath"; # Empty Line
            fi
        done
        msgfmt -o "${LOCALIZED_PATH}/${LanguagesTranslate[$LanguagesIndex]}/LC_MESSAGES/${LOCALIZED_FILE}.mo" "${LOCALIZED_PATH}/${LanguagesTranslate[$LanguagesIndex]}/${LanguagesTranslate[$LanguagesIndex]}.po";
    done
    echo '';
    print_info "LOCALIZER-COMPLETED";
}
#}}}
# -----------------------------------------------------------------------------
# CLEAN LOGS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="clean_logs";
    USAGE="$(localize "CLEAN-LOGS-USAGE")";
    DESCRIPTION="$(localize "CLEAN-LOGS-DESC")";
    NOTES="$(localize "CLEAN-LOGS-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CLEAN-LOGS-USAGE" "clean_logs 1->(Log-Entry)" "Comment: clean_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAN-LOGS-DESC"  "Clean Log Entry of USERNAME and Passwords." "Comment: clean_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAN-LOGS-NOTES" "None." "Comment: clean_logs @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CLEAN-LOGS-ARG"   "Wrong Number of Arguments passed to clean_logs!" "Comment: clean_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAN-LOGS-TEST"  "Test Log file with USERNAME" "Comment: clean_logs @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
clean_logs()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    local LogString="$1";
    local ReplaceWith='$USERNAME';
    #
    if [[ "$LogString" == *"$USERNAME"* ]]; then
        LogString=${LogString/$USERNAME/$ReplaceWith};
    fi
    #
    if [[ "$LogString" == *"$USERPASSWD"* ]]; then
        ReplaceWith='$USERPASSWD';
        LogString=${LogString/$USERPASSWD/$ReplaceWith};
    fi
    #
    if [[ "$LogString" == *"$Root_Password"* ]]; then
        ReplaceWith='$Root_Password';
        LogString=${LogString/$Root_Password/$ReplaceWith};
    fi
    echo "$LogString";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [[ $(clean_logs "$(gettext -s "WRITE-LOG-TEST") $USERNAME $USERPASSWD $Root_Password MY-TEST -> clean_logs @ $(basename $BASH_SOURCE) : $LINENO")  != *"$USERNAME"* ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  clean_logs ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  clean_logs ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# WRITE LOG {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="write_log";
    USAGE="$(localize "WRITE-LOG-USAGE")";
    DESCRIPTION="$(localize "WRITE-LOG-DESC")";
    NOTES="$(localize "WRITE-LOG-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "WRITE-LOG-USAGE" "write_log 1->(Log) 2->(Debugging Information)" "Comment: write_log @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRITE-LOG-DESC"  "Write Log Entry." "Comment: write_log @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRITE-LOG-NOTES" "Localized." "Comment: write_log @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "WRITE-LOG-ARG"   "Wrong Number of Arguments passed to write_log!" "Comment: write_log @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRITE-LOG-TEST"  "Test Log file with USERNAME" "Comment: write_log @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
write_log()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ ! -f "$ACTIVITY_LOG" ]; then
        [[ ! -d "$LOG_PATH" ]] && (mkdir -p "$LOG_PATH");
        touch "$ACTIVITY_LOG";
    fi
    echo $(clean_logs "$(gettext -s "$1") ${2}")  >> "$ACTIVITY_LOG";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    write_log "WRITE-LOG-TEST" "MY-TEST $USERNAME $USERPASSWD $Root_Password -> write_log @ $(basename $BASH_SOURCE) : $LINENO";
    if is_string_in_file "${ACTIVITY_LOG}" "MY-TEST" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  write_log ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  write_log ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# PRINT TITLE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_title";
    USAGE="$(localize "PRINT-TITLE-USAGE")";
    DESCRIPTION="$(localize "PRINT-TITLE-DESC")";
    NOTES="$(localize "PRINT-TITLE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# Help file Localization
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-TITLE-USAGE" "print_title 1->(Localized Text ID) 2->(Optional Text not Localized)" "Comment: print_title @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-TITLE-DESC"  "This will print a Header and clear the screen" "Comment: print_title @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-TITLE-NOTES" "Localized." "Comment: print_title @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_title()
{
    clear;
    print_line;
    if [ "$#" -eq "1" ]; then
        echo -e "# ${BWhite}$(localize "$1")${White}";
    else
        echo -e "# ${BWhite}$(localize "$1") ${2}${White}";
    fi
    print_line;
    echo "";
}
#}}}
# -----------------------------------------------------------------------------
# PRINT INFO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_info";
    USAGE="$(localize "PRINT-INFO-USAGE")";
    DESCRIPTION="$(localize "PRINT-INFO-DESC")";
    NOTES="$(localize "PRINT-INFO-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-INFO-USAGE" "print_info 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-INFO-DESC"  "Prints information on screen for end users to read, in a Column that is as wide as display will allow." "Comment: print_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-INFO-NOTES" "Localized." "Comment: print_info @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_info()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0;
    echo -ne "${BgBlack}"
    if [ "$#" -eq "1" ]; then
        echo -e "${BWhite}$(localize "$1")${White}\n" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    else
        echo -e "${BWhite}$(localize "$1") ${2}${White}\n" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    fi
    echo -ne '\e[00m';
    tput sgr0;
} #}}}
# -----------------------------------------------------------------------------
# PRINT LIST {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_list";
    USAGE="$(localize "PRINT-LIST-USAGE")";
    DESCRIPTION="$(localize "PRINT-LIST-DESC")";
    NOTES="$(localize "PRINT-LIST-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-LIST-USAGE" "print_list 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_list @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-LIST-DESC"  "Used to print Menu Descriptions, will change colors of text before and after a semi-colon" "Comment: print_list @ $(basename $BASH_SOURCE) : $LINENO"
    localize_info "PRINT-LIST-NOTES" "Localized." "Comment: print_list @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_list()
{
    tput sgr0;
    local T_COLS="$(tput cols)";        # Console width number
    local MyString="$(localize "$1")";
    local MyReturn='';
    if $(is_needle_in_haystack ": " "$MyString" 4) ; then # 4=Middle
        if [ "$#" -eq "1" ]; then
            MyReturn=$(sub_string "$MyString" ":" 1);
            local Beginning="$MyReturn";
            MyReturn=$(sub_string "$(localize "$1")" ":" 2);    # MyString was modified so use original;
            echo -e "${BYellow}${Beginning}: ${BWhite}${MyReturn}${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
        else
            MyReturn=$(sub_string "$MyString" ":" 1);
            local Beginning="$MyReturn";
            MyReturn=$(sub_string "$(localize "$1")" ": " 2);    # MyString was modified so use original;
            echo -e "${BYellow}${Beginning}: ${BWhite}${MyReturn}${White} ${2}${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
        fi
    else
        if [ "$#" -eq "1" ]; then
            echo -e "${BWhite}$MyString${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
        else
            echo -e "${BWhite}$MyString ${2}${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
        fi
    fi
    echo '';
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PRINT THIS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_this";
    USAGE="$(localize "PRINT-THIS-USAGE")";
    DESCRIPTION="$(localize "PRINT-THIS-DESC")";
    NOTES="$(localize "PRINT-THIS-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-THIS-USAGE" "print_this 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_this @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-THIS-DESC"  "Like print_info, without a blank line." "Comment: print_this @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-THIS-NOTES" "Localized." "Comment: print_this @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_this()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0;
    if [ "$#" -eq "1" ]; then
        echo -e "${BWhite}$(localize "$1")${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    else
        echo -e "${BWhite}$(localize "$1") ${2}${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PRINT THAT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_that";
    USAGE="$(localize "PRINT-THAT-USAGE")";
    DESCRIPTION="$(localize "PRINT-THAT-DESC")";
    NOTES="$(localize "PRINT-THAT-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-THAT-USAGE" "print_that 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_that @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-THAT-DESC"  "Like print_info, without a blank line and indented." "Comment: print_that @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-THAT-NOTES" "Localized." "Comment: print_that @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_that()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0;
    if [ "$#" -eq "1" ]; then
        echo -e "\t\t${BWhite}$(localize "$1")${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    else
        echo -e "\t\t${BWhite}$(localize "$1") ${2}${White}" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PRINT INFO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_caution";
    USAGE="$(localize "PRINT-INFO-USAGE")";
    DESCRIPTION="$(localize "PRINT-INFO-DESC")";
    NOTES="$(localize "PRINT-INFO-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-INFO-USAGE" "print_caution 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_caution @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-INFO-DESC"  "Prints information on screen for end users to read, in a Column that is as wide as display will allow." "Comment: print_caution @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-INFO-NOTES" "Localized." "Comment: print_caution @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_caution()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0;
    if [ "$#" -eq "1" ]; then
       echo -e "${BYellow}$(localize "$1")${White}\n" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    else
        echo -e "${BYellow}$(localize "$1") ${2}${White}\n" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t/';
    fi
    tput sgr0;
} #}}}
# -----------------------------------------------------------------------------
# PRINT WARNING {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_warning";
    USAGE="$(localize "PRINT-WARNING-USAGE")";
    DESCRIPTION="$(localize "PRINT-WARNING-DESC")";
    NOTES="$(localize "PRINT-WARNING-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-WARNING-USAGE" "print_warning 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_warning @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-WARNING-DESC"  "Print Warning" "Comment: print_warning @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-WARNING-NOTES" "Localized." "Comment: print_warning @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_warning()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0
    if [ "$#" -eq "1" ]; then
        echo -e "\t${BPurple}$(localize "$1")${White}\n" | fold -sw $(( $T_COLS - 1 ));
    else
        echo -e "\t${BPurple}$(localize "$1") ${2}${White}\n" | fold -sw $(( $T_COLS - 1 ));
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PRINT TEST {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_test";
    USAGE="$(localize "PRINT-TEST-USAGE")";
    DESCRIPTION="$(localize "PRINT-TEST-DESC")";
    NOTES="$(localize "PRINT-TEST-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-TEST-USAGE" "print_test 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_test @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-TEST-DESC"  "Print Test" "Comment: print_test @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-TEST-NOTES" "Localized." "Comment: print_test @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_test()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0;
    if [ "$#" -eq "1" ]; then
        echo -e "\t${BBlue}$(localize "$1")     ${White}" | fold -sw $(( $T_COLS - 1 ));
    else
        echo -e "\t${BBlue}$(localize "$1")${White} ${2}" | fold -sw $(( $T_COLS - 1 ));
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# PRINT ERROR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_error";
    USAGE="$(localize "PRINT-ERROR-USAGE")";
    DESCRIPTION="$(localize "PRINT-ERROR-DESC")";
    NOTES="$(localize "PRINT-ERROR-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-ERROR-USAGE" "print_error 1->(Localized Text ID) 2->(Optional Not Localized Text)" "Comment: print_error @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-ERROR-DESC"  "Print error" "Comment: print_error @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-ERROR-NOTES" "Localized." "Comment: print_error @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_error()
{
    # Console width number
    T_COLS="$(tput cols)";
    tput sgr0
    if [ "$#" -eq "1" ]; then
        echo -e "\t${BRed}$(localize "$1")${White}\n" | fold -sw $(( $T_COLS - 1 ));
    else
        echo -e "\t${BRed}$(localize "$1") ${2}${White}\n" | fold -sw $(( $T_COLS - 1 ));
    fi
    tput sgr0;
}
#}}}
# -----------------------------------------------------------------------------
# CHECK BOX {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="checkbox";
    USAGE="$(localize "CHECK-BOX-USAGE")";
    DESCRIPTION="$(localize "CHECK-BOX-DESC")";
    NOTES="$(localize "CHECK-BOX-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CHECK-BOX-USAGE" "checkbox 1->(0={ }, 1={X}, 2={U})" "Comment: checkbox @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-BOX-DESC"  "Display {X} or { } or {U} in Menus." "Comment: checkbox @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-BOX-NOTES" "Used in Menu System." "Comment: checkbox @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
checkbox()
{
    if [[ "$1" -eq 0 ]]; then
        echo -e "${BBlue}[${White} ${BBlue}]${White}";
    elif [[ "$1" -eq 1 ]]; then
        echo -e "${BBlue}[${BWhite}X${BBlue}]${White}";
    elif [[ "$1" -eq 2 ]]; then
        echo -e "${BBlue}[${BWhite}U${BBlue}]${White}";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# CHECKBOX PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="checkbox_package";
    USAGE="$(localize "CHECKBOX-PACKAGE-USAGE")";
    DESCRIPTION="$(localize "CHECKBOX-PACKAGE-DESC")";
    NOTES="$(localize "CHECKBOX-PACKAGE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CHECKBOX-PACKAGE-USAGE" "checkbox_package 1->(checkboxlist)" "Comment: checkbox_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECKBOX-PACKAGE-DESC"  "check if {X} or { }" "Comment: checkbox_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECKBOX-PACKAGE-NOTES" "None." "Comment: checkbox_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
checkbox_package()
{
    check_package "$1" && checkbox 1 || checkbox 0;
}
# -----------------------------------------------------------------------------
#}}}
# CONTAINS ELEMENT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="contains_element";
    USAGE="$(localize "CONTAINS-ELEMENT-USAGE")";
    DESCRIPTION="$(localize "CONTAINS-ELEMENT-DESC")";
    NOTES="$(localize "CONTAINS-ELEMENT-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CONTAINS-ELEMENT-USAGE"  "contains_element 1->(Search) 2->(&#36;{array[@]})" "Comment: contains_element @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONTAINS-ELEMENT-DESC"  "Array Contains Element" "Comment: contains_element @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONTAINS-ELEMENT-NOTES" "Used to Search Options in Select Statement for Valid Selections." "Comment: contains_element @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
contains_element()
{
    # check if an element exist in a string
    for e in "${@:2}"; do [[ $e == $1 ]] && break; done;
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArrary=( "1" "2" "3" );
    if contains_element "2" "${MyArrary[@]}"; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  contains_element ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  contains_element ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# INVALID OPTION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="invalid_option";
    USAGE="$(localize "INVALID-OPTION-DESC")";
    DESCRIPTION="$(localize "INVALID-OPTION-DESC")";
    NOTES="$(localize "INVALID-OPTION-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INVALID-OPTION-USAGE" "invalid_option 1->(Invalid Option)" "Comment: invalid_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INVALID-OPTION-DESC"  "Invalid option" "Comment: invalid_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INVALID-OPTION-NOTES" "None." "Comment: invalid_option @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "INVALID-OPTION-TEXT-1" "Invalid option" "Comment: invalid_option @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
invalid_option()
{
    print_line
    if [ "$#" -eq 0 ]; then
        print_this "INVALID-OPTION-TEXT-1";
    else
        print_this "INVALID-OPTION-TEXT-1" ": $1";
    fi
    if [[ "$INSTALL_WIZARD" -eq 0 && "$AUTOMAN" -eq 0 ]]; then
        pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
}
# -----------------------------------------------------------------------------
#}}}
# INVALID OPTIONS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="invalid_options";
    USAGE="$(localize "INVALID-OPTIONS-USAGE")";
    DESCRIPTION="$(localize "INVALID-OPTIONS-DESC")";
    NOTES="$(localize "INVALID-OPTIONS-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INVALID-OPTIONS-USAGE" "invalid_options 1->(Invalid Options)" "Comment: invalid_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INVALID-OPTIONS-DESC"  "Invalid options" "Comment: invalid_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INVALID-OPTIONS-NOTES" "Idea was to show all valid options, still in work.." "Comment: invalid_options @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
invalid_options()
{
    print_line;
    if [ -z "$1" ]; then
        print_this "INVALID-OPTION-TEXT";
    else
        print_this "INVALID-OPTION-TEXT" ":$1";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# IS BREAKABLE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_breakable";
    USAGE="$(localize "IS-BREAKABLE-USAGE")";
    DESCRIPTION="$(localize "IS-BREAKABLE-DESC")";
    NOTES="$(localize "IS-BREAKABLE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-BREAKABLE-USAGE" "is_breakable 1->(Breakable Key) 2->(Key)" "Comment: is_breakable @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-BREAKABLE-DESC"  "is breakable checks to see if key input meets exit condition." "Comment: is_breakable @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-BREAKABLE-NOTES" "Used to break out of Loops." "Comment: is_breakable @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_breakable()
{
    local Breakable_Key="$(to_lower_case "$1")";
    local Key="$(to_lower_case "$2")";
    [[ "$Breakable_Key" == "$Key" ]] && break;
}
#}}}
# -----------------------------------------------------------------------------
# TO LOWER CASE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="to_lower_case";
    USAGE="$(localize "TO-LOWER-CASE-USAGE")";
    DESCRIPTION="$(localize "TO-LOWER-CASE-DESC")";
    NOTES="$(localize "TO-LOWER-CASE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "TO-LOWER-CASE-USAGE" "to_lower_case 1->(Word)" "Comment: to_lower_case @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TO-LOWER-CASE-DESC"  "Make all Lower Case." "Comment: to_lower_case @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TO-LOWER-CASE-NOTES" "None." "Comment: to_lower_case @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
to_lower_case()
{
    echo "${1,,}";
    # echo $1 | tr '[A-Z]' '[a-z]'; # Slow and unpredictable with Locale: tr '[:upper:]' '[:lower:]'
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [[ $(to_lower_case "A") == 'a' ]]; then # Only make changes once
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  to_lower_case ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  to_lower_case ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# TO UPPER CASE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="to_upper_case";
    USAGE="$(localize "TO-UPPER-CASE-USAGE")";
    DESCRIPTION="$(localize "TO-UPPER-CASE-DESC")";
    NOTES="$(localize "TO-UPPER-CASE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "TO-UPPER-CASE-USAGE" "to_upper_case 1->(Word)" "Comment: to_upper_case @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TO-UPPER-CASE-DESC"  "Make all Upper Case." "Comment: to_upper_case @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TO-UPPER-CASE-NOTES" "None." "Comment: to_upper_case @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
to_upper_case()
{
    echo "${1^^}";
    # echo $1 | tr '[a-z]' '[A-Z]';  # Slow and unpredictable with Locale: tr '[:upper:]' '[:lower:]'
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [[ $(to_upper_case "a") == 'A' ]]; then # Only make changes once
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  to_upper_case ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  to_upper_case ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# PRINT ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_array";
    USAGE="$(localize "PRINT-ARRAY-USAGE")";
    DESCRIPTION="$(localize "PRINT-ARRAY-DESC")";
    NOTES="$(localize "PRINT-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="21 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-ARRAY-USAGE" "print_array 1->(array{@})" "Comment: print_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-ARRAY-DESC"  "Print Array; normally for Troubleshooting; but could be used to print a list." "Comment: print_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-ARRAY-NOTES" "None." "Comment: print_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-ARRAY-WARN"  "Passed in empty array from" "Comment: print_array @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_array()
{
    if [ -z "$1" ]; then
        print_warning "PRINT-ARRAY-WARN" ": $2";
        exit 0;
    fi
    local OLD_IFS="$IFS"; IFS=$' ';
    local -a myArray=("${!1}");     # Array
    local -i total="${#myArray[@]}";
    echo -e "\t---------------------------------";
    echo -e "\t${BBlue}$1 total=$total ${White}";
    for (( i=0; i<total; i++ )); do
        echo -e "\t${BBlue}$1[$i]=|${myArray[$i]}| ${White}";
    done
    echo -e "\t---------------------------------";
    IFS="$OLD_IFS";
}
#}}}
# -----------------------------------------------------------------------------
# ASSERT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="assert";
    USAGE="$(localize "ASSERT-USAGE")";
    DESCRIPTION="$(localize "ASSERT-DESC")";
    NOTES="$(localize "ASSERT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ASSERT-USAGE" "assert 1->(Called from) 2->(Test] 1->(Debugging Information)" "Comment: assert @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ASSERT-DESC"  "assert for debugging variables" "Comment: assert @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ASSERT-NOTES" "None." "Comment: assert @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
assert()                  #  If condition false,
{                         #+ exit from script with error message.
    E_PARAM_ERR=98;
    E_ASSERT_FAILED=99;
    #
    if [ -z "$3" ]; then      # Not enough parameters passed.
        return $E_PARAM_ERR;   # No damage done.
    fi
    lineno=$3
    if [ ! $2 ]; then
        echo "Assertion failed:  \"$2\"";
        echo "File \"$0\", line $lineno";
        exit $E_ASSERT_FAILED;
    else
        if [[ "$DEBUGGING" -eq 1 ]]; then echo "assert (Passed in [$1] - checking [$2] at line number: [$3])"; fi
        return 1; #  and continue executing script.
    fi
}
#}}}
# -----------------------------------------------------------------------------
# OS INFO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="os_info";
    USAGE="os_info";
    DESCRIPTION="$(localize "OS-INFO-DESC")";
    NOTES="$(localize "OS-INFO-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="10 Apr 2013";
    REVISION="10 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "OS-INFO-DESC"  "OS Information." "Comment: os_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "OS-INFO-NOTES" "None." "Comment: os_info @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
os_info()
{
    My_OS="$(to_lower_case $(uname -s))";  # OS: Linux, FreeBSD, MAC, Windows
    My_OS="${My_OS// /}";                  # Remove all Spaces: Windows Nt becomes WindowsNt
    My_ARCH=$(uname -m);                   # x86 or x86_64
    My_Ver=$(uname -r);                    # OS Version
    #
    if [[ "$My_OS" == "sunos" ]]; then           # Sun OS
        case $(uname -r) in
            4*)  My_OS='sunbsd';    ;;
            5*)  My_OS='solaris';   ;;
             *)  My_OS='solaris';   ;;
        esac
        My_ARCH=$(uname -p);
        My_DIST="$My_OS";
    elif [[ "$My_OS" == "HP-UX" ]]; then         # HP-UX
        My_OS='hp';
        My_DIST='hp';
    elif [[ "$My_OS" == "IRIX" ]]; then          # IRIX
        My_OS='sgi';
        My_DIST='sgi';
    elif [[ "$My_OS" == "OSF1" ]]; then          # OSF1
        My_OS='decosf';
        My_DIST='decosf';
    elif [[ "$My_OS" == "IRIX" ]]; then          # IRIX
        My_OS='sgi';
        My_DIST='sgi';
    elif [[ "$My_OS" == "ULTRIX" ]]; then        # ULTRIX
        My_OS='ultrix';
        My_DIST='ultrix';
    elif [[ "$My_OS" == "aix" ]]; then           # AIX
        My_Ver=$(oslevel -r);
        My_DIST='aix';
    elif [[ "$My_OS" == "freebsd" ]]; then       # Free BSD
        My_DIST='freebsd';
    elif [[ "$My_OS" == "windowsnt" ]]; then     # Windows NT
        My_DIST='windowsnt';
    elif [[ "$My_OS" == "darwin" ]]; then        # MAC
        My_OS='mac';
        My_DIST='mac';
        if [[ -n "$(which sw_vers 2>/dev/null)" ]]; then
            My_PSUEDONAME=$(sw_vers -productName);
            My_Ver=$(sw_vers -productVersion);
            My_OS_Update="${My_Ver##*.}";
            My_Ver="${My_Ver%.*}";

            if [[ "$My_Ver" =~ "10.8" ]]; then
                My_PSUEDONAME="mountain lion";
            elif [[ "$My_Ver" =~ "10.7" ]]; then
                My_PSUEDONAME="lion";
            elif [[ "$My_Ver" =~ "10.6" ]]; then
                My_PSUEDONAME="snow leopard"
            elif [[ "$My_Ver" =~ "10.5" ]]; then
                My_PSUEDONAME="leopard";
            elif [[ "$My_Ver" =~ "10.4" ]]; then
                My_PSUEDONAME="tiger";
            elif [[ "$My_Ver" =~ "10.3" ]]; then
                My_PSUEDONAME="panther";
            elif [[ "$My_Ver" =~ "10.2" ]]; then
                My_PSUEDONAME="jaguar";
            elif [[ "$My_Ver" =~ "10.1" ]]; then
                My_PSUEDONAME="puma";
            elif [[ "$My_Ver" =~ "10.0" ]]; then
                My_PSUEDONAME="cheetah";
            else
                My_PSUEDONAME="unknown";
            fi
        fi
    elif [[ "$My_OS" == "linux" ]]; then                       # Linux
        if [ -f /etc/centos-release ] ; then                                                         # CentOS
            My_DIST='redhat';
            My_PSUEDONAME='CentOS';
            My_Ver_Major=$(cut -d ' ' -f 3 /etc/redhat-release | cut -d '.' -f 1);
            My_Ver_Minor=$(cut -d ' ' -f 3 /etc/redhat-release | cut -d '.' -f 2);
            My_Ver="${My_Ver_Major}.${My_Ver_Minor}"; # $(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//);
            echo "My_Ver=$My_Ver";
            My_OS_Update=$(uname -r);
        elif [ -f /etc/redhat-release ] ; then                                                         # Redhat
            My_DIST='redhat';
            My_PSUEDONAME='Redhat';
            My_Ver_Major=$(cut -d ' ' -f 3 /etc/redhat-release | cut -d '.' -f 1);
            My_Ver_Minor=$(cut -d ' ' -f 3 /etc/redhat-release | cut -d '.' -f 2);
            My_Ver=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//);
        elif [ -f /etc/fedora-release ] ; then                                                         # Fedora
            My_DIST='fedora';
            My_PSUEDONAME='Fedora';
            My_Ver_Major=$(cut -d ' ' -f 3 /etc/fedora-release | cut -d '.' -f 1);
            My_Ver_Minor=$(cut -d ' ' -f 3 /etc/fedora-release | cut -d '.' -f 2);
            My_Ver=$(cat /etc/fedora-release | sed s/.*release\ // | sed s/\ .*//);
        elif [ -f /etc/SuSE-release ] ; then                                                            # SuSE
            My_DIST='suse';
            My_PSUEDONAME='SuSe';
            My_Ver_Major=$(cut -d ' ' -f 3 /etc/SuSE-release | cut -d '.' -f 1);
            My_Ver_Minor=$(cut -d ' ' -f 3 /etc/SuSE-release | cut -d '.' -f 2);
            My_Ver=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //);
        elif [ -f /etc/mandrake-release ] ; then                                                        # Mandrake
            My_DIST='mandrake';
            My_PSUEDONAME="Mandrake";
            My_Ver_Major=$(cut -d ' ' -f 3 /etc/mandrake-release | cut -d '.' -f 1);
            My_Ver_Minor=$(cut -d ' ' -f 3 /etc/mandrake-release | cut -d '.' -f 2);
            My_Ver=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//);
        elif [ -f /etc/debian_version ] ; then                                                          # Debian, Ubuntu, LMDE
            My_DIST='debian';
            if grep -Fxq "Debian" /etc/issue ; then
                My_PSUEDONAME='Debian';
            elif grep -Fxq "Ubuntu" /etc/issue ; then
                My_PSUEDONAME='Ubuntu';
            elif grep -Fxq "Linux Mint Debian Edition" /etc/issue ; then
                My_PSUEDONAME='LMDE';
            elif grep -Fq "LMDE" /etc/issue ; then
                My_PSUEDONAME='LMDE';
            else
                My_PSUEDONAME='Debian';
            fi
            My_Ver="$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')";
        elif [ -f /etc/arch-release ] ; then                                                            # ArchLinux They may drop this like Manjaro did
            My_DIST='archlinux';
            My_PSUEDONAME='Archlinux';
            My_OS_Package="pacman";
            My_Ver_Major='0.8.10';
        elif [ -f /etc/os-release ] ; then                                                              # Manjaro - ArchLinux
            My_DIST='archlinux';
            My_PSUEDONAME='Manjaro';
            My_OS_Package="pacman";
            My_Ver_Major='0.8.10'; # FIXIT read value, not that it matters
        elif [ -f /etc/UnitedLinux-release ] ; then                                                     # United Linux
            My_DIST='unitedlinux';
            My_PSUEDONAME='UnitedLinux';
            My_Ver="$(cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//)";
        elif [[ -x $(which lsb_release 2>/dev/null) ]]; then     # Debian
            #My_PSUEDONAME=$(  lsb_release -i -s);             # LinuxMint
            My_Ver=$( lsb_release -r -s );                     # LMDE=1
            if $(is_needle_in_haystack "." "$My_Ver" 5) ; then # 5=Anywhere
                My_Ver_Major=$(string_split "$My_Ver" "." 1);  # 1=First Half
                My_Ver_Minor=$(string_split "$My_Ver" "." 2);  # 2=Second Half
            else
                My_Ver_Major="$My_Ver";
                My_Ver_Minor='0';
            fi
            My_DIST=$(lsb_release -c -s);                      # debian
            My_OS_Package="rpm";
            if [[ "$My_PSUEDONAME" =~ Debian,Ubuntu ]]; then
                My_OS_Package="deb";
            elif [[ "SUSE LINUX" =~ $My_PSUEDONAME ]]; then
                lsb_release -d -s | grep -q openSUSE;
                if [[ $? -eq 0 ]]; then
                    My_PSUEDONAME="openSUSE";
                fi
            elif [[ $My_PSUEDONAME =~ Red.*Hat ]]; then
                My_PSUEDONAME="Red Hat";
            fi
            if grep -Fxq "Debian" /etc/issue ; then
                My_PSUEDONAME='Debian';
                My_OS_Package="deb";
            elif grep -Fxq "Ubuntu" /etc/issue ; then
                My_PSUEDONAME='Ubuntu';
                My_OS_Package="deb";
            elif grep -Fxq "Linux Mint Debian Edition" /etc/issue ; then
                My_PSUEDONAME='LMDE';
                My_OS_Package="deb";
            elif grep -Fq "LMDE" /etc/issue ; then
                My_PSUEDONAME='LMDE';
                My_OS_Package="deb";
            else
                My_PSUEDONAME='Debian';
                My_OS_Package="deb";
            fi
        fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    os_info;
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_OS=$My_OS        ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_ARCH=$My_ARCH    ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_DIST=$My_DIST    ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_PSUEDONAME=$My_PSUEDONAME ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_Ver=$My_Ver      ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_Ver_Major=$My_Ver_Major ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_Ver_Minor=$My_Ver_Minor ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_OS_Package=$My_OS_Package ${White}";
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BWhite}My_OS_Update=$My_OS_Update ${White} @ $(basename $BASH_SOURCE) : $LINENO";
fi
#}}}
# -----------------------------------------------------------------------------
# IS OS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_os";
    USAGE="$(localize "IS-OS-USAGE")";
    DESCRIPTION="$(localize "IS-OS-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-OS-USAGE" "is_os 1->(os-name)" "Comment: is_os @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-OS-DESC"  "Check to see if OS matches what you think it is" "Comment: is_os @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_os()
{
    if [[ "$My_DIST" == "$1" ]]; then
        return 0;
    else
        return 1;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then # @FIX
    OLD_IFS="$IFS"; IFS=$' '
    echo -e "\tMy_Distros=${My_Distros[@]}"
    for Distro in ${My_Distros[@]}; do
        if is_os "$Distro" ; then
            echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  ${BGreen}is_os($Distro)${White} @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo -e  "\t${BYellow}$(gettext -s "TEST-FUNCTION-FAILED")  ${BWhite}is_os($Distro)${White} @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    done
    IFS="$OLD_IFS";
fi
#}}}
# -----------------------------------------------------------------------------
# GET NETWORK DEVICE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_network_devices";
    USAGE="get_network_devices";
    DESCRIPTION="$(localize "GET-NETWORK-DEVICE-DESC")";
    NOTES="$(localize "GET-NETWORK-DEVICE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-NETWORK-DEVICE-DESC"  "Get Network Devices." "Comment: get_network_devices @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-NETWORK-DEVICE-NOTES" "Holds IP Address if its an Active connection; no test of Internet Access are done." "Comment: get_network_devices @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_network_devices()
{
    # -----------------------------------
    function system_primary_ip
    {
        # returns the primary IP assigned to ethx
        #echo -n $(hostname  -i | cut -f1 -d' ');

        #echo $(ip route get 8.8.8.8 | awk -F: '/src / {print $2}' | awk '{ print $1 }');
        #echo $(ip route get 8.8.8.8 | sed '1!d' | sed s/.*src\ // | sed s/\ .*//);
        #echo $(ifconfig "${1}" | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
        echo $(ip route get 8.8.8.8 | awk '/src / {print $7}' | sed 's/\.$//')
    }
    # -----------------------------------
    function network_adapter_names
    {
        # returns the primary IP assigned to ethx
        local myNet=$(sudo lshw -class network | awk -F: '/logical name: / {print $2}' | awk '{ print $1 }');
            for myNetName in ${myNet[@]}; do
                echo "$myNetName";
        done
    }
    # -----------------------------------
    function get_rdns
    {
        # calls host on an IP address and returns its reverse dns
        if host $1 ; then
                echo $(host $1 | awk '/pointer/ {print $5}' | sed 's/\.$//')
        else
                # not working if Host 13.1.168.192.in-addr.arpa. not found: 3(NXDOMAIN)
                echo "FAIL";
        fi
    }
    # -----------------------------------
    # lspci | egrep -i --color 'network|ethernet'
    OLD_IFS="$IFS"; IFS=$' ';
    local MyEthAddress=$(hostname -i);
    EthAddress=($MyEthAddress);
    for MyIp in ${EthAddress[@]}; do
        if host "$MyIp" >/dev/null ; then
            echo "******************** HERE ******************";
            EthReverseDNS+=( $(get_rdns "$MyIp") );
        else
            EthReverseDNS+=("");
        fi
    done
    ActiveNetAdapter=$(system_primary_ip);
    IFS=$'\n';
    NIC=( $(network_adapter_names) );
    IFS=$' ';
    IFS="$OLD_IFS";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    get_network_devices;
    total="${#EthAddress[@]}";
    for (( MyIndex=0; MyIndex<total; MyIndex++ )); do
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")${BYellow} ${NIC[$MyIndex]}: IP: ${EthAddress[$MyIndex]} | Reverse DNS: [${EthReverseDNS[$MyIndex]}] | Active IP: $ActiveNetAdapter | ${BWhite}get_network_devices ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    done
fi
#}}}
# -----------------------------------------------------------------------------
# SHOW USERS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="show_users";
    USAGE="show_users";
    DESCRIPTION="$(localize "SHOW-USERS-DESC")";
    NOTES="$(localize "SHOW-USERS-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SHOW-USERS-DESC"  "Show Users." "Comment: show_users @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-USERS-NOTES" "Shows users in /etc/passwd." "Comment: show_users @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
show_users()
{
    echo $(gawk -F: '{ print $1 }' /etc/passwd);
}
#}}}
# -----------------------------------------------------------------------------
# DEVICE LIST {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="device_list";
    USAGE="device_list";
    DESCRIPTION="$(localize "DEVICE-LIST-DESC")";
    NOTES="$(localize "DEVICE-LIST-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DEVICE-LIST-DESC"  "Get Device List." "Comment: device_list @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DEVICE-LIST-NOTES" "Used to get Hard Drive Letter, assumes you are running this from a Flash Drive." "Comment: device_list @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
device_list()
{
    local OLD_IFS="$IFS";
    # Get all SD devices
    IFS=$'\n';
    local -a LIST_ALL_DEVICES=( $( ls /dev/sd* ) );
    # List: /dev/sda /dev/sda1 /dev/sda2 /dev/sdb /dev/sdb1
    LIST_DEVICES=();
    IFS=$' ';
    for x in "${LIST_ALL_DEVICES[@]}"; do
        if [[ "${#x}" -eq 8 ]]; then # @FIX /dev/sdx note it might be better to remove number, but then you have duplicates to deal with; what if you have more devices then z
            if [[ "$(cat /sys/block/${x: -3}/removable)" == "1" ]]; then
                if [[ "$SCRIPT_DEVICE" == "${x: -4}" ]]; then
                    LIST_DEVICES[$[${#LIST_DEVICES[@]}]]="${x: -3} Removable Device Script is Executing.";
                    SCRIPT_DEVICE="/dev/${x: -4}";
                else
                    LIST_DEVICES[$[${#LIST_DEVICES[@]}]]="${x: -3} Removable";
                fi
            else
                if [[ "$SCRIPT_DEVICE" == "${x: -4}" ]]; then
                    LIST_DEVICES[$[${#LIST_DEVICES[@]}]]="${x: -3} Device Script is Executing.";
                    SCRIPT_DEVICE="/dev/${x: -4}";
                else
                    LIST_DEVICES[$[${#LIST_DEVICES[@]}]]="${x: -3}";
                fi
            fi
        fi
    done
    IFS="$OLD_IFS";
}
#}}}
# -----------------------------------------------------------------------------
# UMOUNT PARTITION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="umount_partition";
    USAGE="$(localize "UMOUNT-PARTITION-USAGE")";
    DESCRIPTION="$(localize "UMOUNT-PARTITION-DESC")";
    NOTES="$(localize "UMOUNT-PARTITION-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "UMOUNT-PARTITION-USAGE" "umount_partition 1->(Device Name)" "Comment: umount_partition @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UMOUNT-PARTITION-DESC"  "Umount partition." "Comment: umount_partition @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UMOUNT-PARTITION-NOTES" "None." "Comment: umount_partition @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
umount_partition()
{
    swapon -s|grep $1 && swapoff $1; # check if swap is on and umount
    mount|grep $1 && umount $1;      # check if partition is mounted and umount
}
#}}}
# -----------------------------------------------------------------------------
# Keyboard Input Functions
# -----------------------------------------------------------------------------
# IS VALID EMAIL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_valid_email";
    USAGE="$(localize "IS-VALID-EMAIL-USAGE")";
    DESCRIPTION="$(localize "IS-VALID-EMAIL-DESC")";
    NOTES="$(localize "IS-VALID-EMAIL-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-VALID-EMAIL-USAGE" "is_valid_email 1->(value)" "Comment: is_valid_email @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-EMAIL-DESC"  "Is Valid path." "Comment: is_valid_email @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-EMAIL-NOTES" "None." "Comment: is_valid_email @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_valid_email()
{
    local compressed="$(echo $1 | grep -P '^[A-Za-z0-9._&#37;+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$')"
    if [ "$compressed" != "$1" ] ; then
        return 1;
    else
        return 0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# IS VALID PATH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_valid_path";
    USAGE="$(localize "IS-VALID-PATH-USAGE")";
    DESCRIPTION="$(localize "IS-VALID-PATH-DESC")";
    NOTES="$(localize "IS-VALID-PATH-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-VALID-PATH-USAGE" "is_valid_path 1->(value)" "Comment: is_valid_path @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-PATH-DESC"  "Is Valid path." "Comment: is_valid_path @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-PATH-NOTES" "A-Z 0-9 - / (Fix for Windows Drive Letter : and backslash.)" "Comment: is_valid_path @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_valid_path()
{
    local compressed="$(echo $1 | grep -P '/[-_A-Za-z0-9]+(/[-_A-Za-z0-9]*)*')"
    # @FIX what about Windows
    if [ "$compressed" != "$1" ] ; then
        return 1;
    else
        return 0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# IS VALID DOMAIN {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_valid_domain";
    USAGE="$(localize "IS-VALID-DOMAIN-USAGE")";
    DESCRIPTION="$(localize "IS-VALID-DOMAIN-DESC")";
    NOTES="$(localize "IS-VALID-DOMAIN-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-VALID-DOMAIN-USAGE" "is_valid_domain 1->(value)" "Comment: is_valid_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-DOMAIN-DESC"  "Is Valid Domain Name." "Comment: is_valid_domain @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-DOMAIN-NOTES" "None." "Comment: is_valid_domain @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_valid_domain()
{
    local compressed="$(echo $1 | grep -P '(?=^.{5,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')"
    if [ "$compressed" != "$1" ] ; then
        if [[ "$OPTION" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]] ; then # it can be localhost or any name with the .tdl
            return 0;
        else
            return 1;
        fi
    else
        return 0;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# IS VALID IP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_valid_ip";
    USAGE="$(localize "IS-VALID-IP-USAGE")";
    DESCRIPTION="$(localize "IS-VALID-IP-DESC")";
    NOTES="$(localize "IS-VALID-IP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-VALID-IP-USAGE" "is_valid_ip 1->(value)" "Comment: is_valid_ip @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-IP-DESC"  "Is Valid IP Address." "Comment: is_valid_ip @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-VALID-IP-NOTES" "None." "Comment: is_valid_ip @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_valid_ip()
{
    local ip=$1;
    local OIFS=$IFS;
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.';
        ip=($ip);
        IFS=$OIFS;
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    fi
    return "$?";
}
#}}}
# -----------------------------------------------------------------------------
# IS ALPHANUMERIC {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_alphanumeric";
    USAGE="$(localize "IS-ALPHANUMERIC-USAGE")";
    DESCRIPTION="$(localize "IS-ALPHANUMERIC-DESC")";
    NOTES="$(localize "IS-ALPHANUMERIC-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-ALPHANUMERIC-USAGE" "is_alphanumeric 1->(value)" "Comment: is_alphanumeric @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-ALPHANUMERIC-DESC"  "Is Alphanumeric." "Comment: is_alphanumeric @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-ALPHANUMERIC-NOTES" "None." "Comment: is_alphanumeric @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_alphanumeric()
{
    local compressed="$(echo $1 | sed -e 's/[^[:alnum:]]//g')"
    if [ "$compressed" != "$1" ] ; then
        return 1;
    else
        return 0;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if $(is_alphanumeric "1") && $(is_alphanumeric "A") && ! $(is_alphanumeric '!@#') ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_alphanumeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_alphanumeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# IS NUMBER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_number";
    USAGE="$(localize "IS-NUMBER-USAGE")";
    DESCRIPTION="$(localize "IS-NUMBER-DESC")";
    NOTES="$(localize "IS-NUMBER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-NUMBER-USAGE" "is_number 1->(value)" "Comment: is_number @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-NUMBER-DESC"  "Is Number." "Comment: is_number @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-NUMBER-NOTES" "None." "Comment: is_number @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_number()
{
    if [[ "$1" =~ ^[0-9]+$ ]] ; then
        return 0;
    else
        return 1;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if $(is_number "1") && ! $(is_number "A") ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_number ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_number ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# READ INPUT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="read_input";
    USAGE="read_input";
    DESCRIPTION="$(localize "READ-INPUT-DESC")";
    NOTES="$(localize "READ-INPUT-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    # READ INPUT {{{
    localize_info "READ-INPUT-DESC"  "read keyboard input." "Comment: read_input @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-NOTES" "Sets Variable OPTION as return; do not us in AUTOMAN or INSTALL_WIZARD Mode." "Comment: read_input @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
read_input()
{
    echo -ne "\t${BWhite}$prompt1 ${White}";
    read -p "" OPTION;
}
#}}}
# -----------------------------------------------------------------------------
# GET INPUT OPTION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_input_option";
    USAGE="GET-INPUT-OPTION-USAGE";
    DESCRIPTION="$(localize "GET-INPUT-OPTION-DESC")";
    NOTES="$(localize "GET-INPUT-OPTION-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-INPUT-OPTION-USAGE"    "get_input_option 1->(array[@] of options) 2->(default) 3->(Base: 0 or 1) <- return value OPTION" "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INPUT-OPTION-DESC"     "Get Keyboard Input Options between two numbers." "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INPUT-OPTION-NOTES"    "None." "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INPUT-OPTION-CHOOSE-0" "Choose a number between 0 and" "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INPUT-OPTION-CHOOSE-1" "Choose a number between 1 and" "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INPUT-OPTION-DEFAULT"  "Default is" "Comment: get_input_option @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_input_option()
{
    # @FIX Make 0 based, or range based 3->(Base: 0 or 1)
    # Choose a number between x and
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        OPTION="$2";
        return 0;
    fi
    local -i StartBased=0;
    if [[ "$#" -eq "2" ]]; then
        StartBased=1;
    elif [[ "$#" -eq "3" ]]; then
        StartBased="$3";
    fi
    local -a array=("${!1}");
    local -i total="${#array[@]}";
    local -i index=0;
    local -i iPad=0;
    if   [[ "$total" -gt 9 ]];   then iPad=3;
    elif [[ "$total" -gt 99 ]];  then iPad=4;
    elif [[ "$total" -gt 999 ]]; then iPad=5;
    fi
    echo '';
    for var in "${array[@]}"; do
        if [[ "$StartBased" -eq 0 ]]; then
            printf "\t${BYellow}%-${iPad}s${BWhite} %s\n" "$(( index++ ))." "${var}";
        else
            printf "\t${BYellow}%-${iPad}s${BWhite} %s\n" "$(( ++index ))." "${var}";
        fi
    done
    #
    if [[ "$StartBased" -eq 0 ]]; then
        print_warning "GET-INPUT-OPTION-CHOOSE-0" "$((total-1))";
    else
        print_warning "GET-INPUT-OPTION-CHOOSE-1" "$total";
    fi
    local -i DefaultValue="$2";
    if [[ "$StartBased" -eq 0 ]]; then
        print_this    "GET-INPUT-OPTION-DEFAULT" ": $2 (${array[$(( DefaultValue ))]})";
    else
        print_this    "GET-INPUT-OPTION-DEFAULT" ": $2 (${array[$(( DefaultValue - 1 ))]})";
    fi
    YN_OPTION=0;
    while [[ "$YN_OPTION" -ne 1 ]]; do
        read_input;
        if [ -z "$OPTION" ]; then
            OPTION=$2;
            break;
        fi
        if ! [[ "$OPTION" =~ ^[0-9]+$ ]] ; then
            invalid_options "$OPTION";
        elif [[ "$OPTION" -le $total ]]; then
            if [[ "$StartBased" -eq 1 && "$OPTION" -eq "0" ]]; then
                invalid_options "$OPTION";
            else
                break;
            fi
        else
            invalid_options "$OPTION";
        fi
    done
    #if [[ "$StartBased" -eq 0 ]]; then OPTION=$((OPTION-1)); fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 3 ]]; then
    MyArray=('0' '1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12');
    get_input_option "MyArray[@]" 1 1;
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  get_input_option 1 = $OPTION (${MyArray[$((OPTION-1))]}) ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    get_input_option "MyArray[@]" 0 0;
    echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  get_input_option 0 = $OPTION (${MyArray[$((OPTION))]}) ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
fi
#}}}
# -----------------------------------------------------------------------------
# CLEAN INPUT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="clean_input";
    USAGE="$(localize "CLEAN-INPUT-USAGE")";
    DESCRIPTION="$(localize "CLEAN-INPUT-DESC")";
    NOTES="$(localize "CLEAN-INPUT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="26 Jan 2013";
    REVISION="26 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CLEAN-INPUT-USAGE"   "clean_input 1->(Input String) <- return " "Comment: clean_input @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAN-INPUT-DESC"    "Clean Keyboard Input Options:  String of values: 1 2 3 or 1-3 or 1,2,3, replaces Commas with spaces, only allows Alphanumeric, - and space." "Comment: clean_input @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAN-INPUT-NOTES"   "Only Allows: Alphanumeric, 1 space between them, converts commas to spaces, converts all Alpha's to lower case." "Comment: clean_input @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
clean_input()
{
    local CleanInput="$1";                               # Assign
    CleanInput="$(trim "$CleanInput")";                  # Trim
    CleanInput="${CleanInput//,/ }";                     # Replace any Commas with space
    #CleanInput="$(echo -n "$CleanInput" | tr ',' ' ')"; # Replace any Commas with space using tr
    CleanInput="${CleanInput//[^a-zA-Z0-9 -]/}";         # Clean out anything that's not Alphanumeric, comma or a space
    CleanInput="$(to_lower_case "$CleanInput")";         # "$(echo -n $CleanInput | tr A-Z a-z)";   # Lowercase with TR: tr '[:upper:]' '[:lower:]'
    CleanInput="$(trim "$CleanInput")";                  # Trim
    echo "$CleanInput";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 2 ]]; then
    MyString="$(clean_input '1-3,4,5 6 A B C ^!@*')";
    if [[ "$MyString" == '1-3 4 5 6 a b c' ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  clean_input ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  clean_input |$MyString| ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# READ INPUT OPTIONS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="read_input_options";
    USAGE="$(localize "READ-INPUT-OPTIONS-USAGE")";
    DESCRIPTION="$(localize "READ-INPUT-OPTIONS-DESC")";
    NOTES="$(localize "READ-INPUT-OPTIONS-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "READ-INPUT-OPTIONS-USAGE"          "read_input_options 1->(options) 2->(Breakable Key) <- return Array Values in OPTIONS, expanded, duplicates removed and lower case." "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-DESC"           "Read Keyboard Input Options:  String of values: 1 2 3 or 1-3 or 1,2,3" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-NOTES"          "AUTOMAN, INSTALL_WIZARD and BYPASS to easily configure default values, hit 'r' to run Recommended Options." "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-OPTIONS"        "Use Options" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-IT-1"           "read_input_options Return Array" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-IT-2"           "read_input_options Removed Duplicates" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-VERIFY"         "Verify Input" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-INVALID-NUMBER" "Invalid Number Option: Legal values are" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-INVALID-ALPHA"  "Invalid Alpha Option: Legal values are" "Comment: read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
read_input_options()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    # |1|
    # |1 2 3 4,5,6 7-9 Q D B R|
    #debugger 1
    local -a MyArray=();
    local OLD_IFS="$IFS";
    # EXPAND OPTIONS }}}
    # expand_options 1->(Array of Options MyArray=(1 2 3 4,5,6 7-9 Q D B) )
    # MyOptions=( expand_options "MyArray[@]" )
    expand_options()
    {
        local OLD_IFS="$IFS"; IFS=$' ';
        local -a arrayOptions=("${!1}");     # Array
        local -i total="${#arrayOptions[@]}";
        local line="";
        local -a optionsArray=();
        # Fix any problems with input
        local -i total="${#arrayOptions[@]}";
        for (( i=0; i<total; i++ )); do
            if [[ "${arrayOptions[$i]:0:1}" == "-" ]]; then
                arrayOptions[$i]=${arrayOptions[$i]:1};
            fi
        done
        #
        IFS=$' ';
        for line in "${arrayOptions[@]/,/ }"; do
            if [[ ${line/-/} != $line ]]; then
                # @FIX not sure how to fix this: ((i={line%-*}; i<={line#*-}; i++)) or ((i=line%-*; i<=line#*-; i++))
                for ((i=${line%-*}; i<=${line#*-}; i++)); do # Start at line with a - after it (%-*), 1-, then end with the - before it (#*-) -3, then count each item in between it, or expand it
                    [ -n "$i" ] && optionsArray+=("$i");
                done
            else
                optionsArray+=("$line") # This is building an Array; bash you have to love it for allowing this type of declaration; normally only works with strings in other languages; normally in bash: array=($array "new") or array[${#array[*]}]="new"
            fi
        done
        #
        IFS=$'\n\t';
        optionsArray=( $(remove_array_duplicates "optionsArray[@]") );              # Remove Duplicates IFS=$'\n\t';
        #
        IFS=$' ';
        optionsArray=( $(echo "${optionsArray[@]}" | tr '[:upper:]' '[:lower:]') ); # Convert Alpha to Lower Case
        #
        for line in "${optionsArray[@]}"; do
            echo "$line"; # If you use echo "" you will get a line feed so use IFS=$'\n\t', if you use -n you will not, so use IFS=$' '
        done
        IFS="$OLD_IFS";
    }
    #}}}
    # CLEAN IT {{{
    # MyArray=( $(clean_it 1->('1-3,4,5 6 A B C ^!@*') 2->('Defaults') 2->('Breakable-Key') ))
    clean_it()
    {
        local OLD_IFS="$IFS";
        local MyOption="$(clean_input "$1")"; # Pass in a string '1-3,4,5 6 A B C ^!@*', return trimmed string '1-3 4 5 6 a b c' of legal characters
        local MyArray=();
        IFS=$' ';
        if [[ "$MyOption" == 'r' ]]; then  # Recommended Default Options
            if [ -z "$2" ]; then              # Use Breakable
                MyArray=( $( echo -n "$3" ) ); # This should not happen; you should always pass in the breakable key, how to fix it?
            else                              # Not Empty
                MyArray=( $( echo -n "$2" ) ); # Use Defaults
            fi
        else
            MyArray=( $( echo -n "$MyOption" ) );
        fi
        #
        IFS=$'\n\t';
        MyArray=( $(expand_options "MyArray[@]") ); # Expand Options: 1-3 returns 1 2 3
        for line in "${MyArray[@]}"; do
            echo "$line"; # If you use echo "" you will get a line feed so use IFS=$'\n\t', if you use -n you will not, so use IFS=$' '
        done
        IFS="$OLD_IFS";
    }
    #}}}
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        IFS=$' ';
        if [ -z "$1" ]; then
            MyArray=( $( clean_input "$2" ) );             # @FIX this should not happen; you should always pass in the breakable key, how to fix it?
        else
            MyArray=( $( clean_input "$1" ) );
        fi
        IFS=$'\n\t';
        OPTIONS=( $(expand_options "MyArray[@]") ); # Expand Options: 1-3 returns 1 2 3
    else
        OPTION=''                                   # Clear: so we enter the loop
        while [[ -z "$OPTION" ]]; do
            OPTION='';                              # Clear: we have no idea whats in it
            read -p "        $prompt2" OPTION;      # At this point its only going to be what the User types in
            # Now lets test Input
            if [ -n "$OPTION" ]; then               # If not Empty
                IFS=$'\n\t';
                OPTIONS=( $( clean_it "$OPTION" "$1" "$2" ) ); # Clean it, Trim, Replace Commas with Space, remove Illegal Characters.
                # Now test every option...
                local -i total="${#OPTIONS[@]}";
                for (( index=0; index<total; index++ )); do
                    if is_number "${OPTIONS[$index]}" ; then # If Number
                        if [[ "${OPTIONS[$index]}" -gt "$LAST_MENU_ITEM" ]]; then
                            print_warning "READ-INPUT-OPTIONS-INVALID-NUMBER" ": 1-$LAST_MENU_ITEM, $BREAKABLE_KEY, r (${OPTIONS[$index]})";
                            read_input_default "READ-INPUT-OPTIONS-VERIFY" "$OPTION";
                            OPTIONS=( $(clean_it "$OPTION" "$1" "$2" ) ); # Clean it, Trim, Replace Commas with Space, remove Illegal Characters.
                            break;
                        fi
                    else                                     # If Alpha it should = breakable, we tested for r above
                        if [[ "${OPTIONS[$index]}" != $( to_lower_case "$BREAKABLE_KEY" ) ]]; then
                            print_warning "READ-INPUT-OPTIONS-INVALID-ALPHA" ": 1-$LAST_MENU_ITEM, $BREAKABLE_KEY, r (${OPTIONS[$index]})";
                            read_input_default "READ-INPUT-OPTIONS-VERIFY" "$OPTION";
                            OPTIONS=( $(clean_it "$OPTION" "$1" "$2" ) ); # Clean it, Trim, Replace Commas with Space, remove Illegal Characters.
                            break;
                        fi
                    fi
                done
            fi
        done
    fi
    if [[ "$RUN_TEST" -eq 2 ]]; then
        print_test "READ-INPUT-OPTIONS-OPTIONS" "$1"; # Use Options Passed in as is
        print_test "READ-INPUT-OPTIONS-IT-1" ":";     # read_input_options Return Array
        print_array "OPTIONS[@]" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    IFS="$OLD_IFS";
    #debugger 0;
    write_log "read_input_options  $OPTION" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
}
#}}}
# -----------------------------------------------------------------------------
# READ INPUT YN {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="read_input_yn";
    USAGE="$(localize "READ-INPUT-YN-USAGE")";
    DESCRIPTION="$(localize "READ-INPUT-YN-DESC")";
    NOTES="$(localize "READ-INPUT-YN-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="12 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "READ-INPUT-YN-USAGE" "read_input_yn 1->(Question) 2->(None Localize) 3->(Default: 0=No, 1=Yes) <- return value YN_OPTION" "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-YN-DESC"  "Read Keyboard Input for Yes and No." "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-YN-NOTES" "Localized." "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "Wrong-Key-Yn" "Wrong Key, (Y)es or (n)o required." "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "Wrong-Key-Ny" "Wrong Key, (y)es or (N)o required." "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "Wrong-Key-Q"  "Yes or No Question" "Comment: read_input_yn @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
read_input_yn()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        YN_OPTION="$3";
        return 0;
    fi
    local MY_OPTION=0;
    # read_input_yn "Is this Correct" "This" 1
    # GET INPUT YN {{{
    get_input_yn()
    {
        echo "";
        if [[ "$3" == "1" ]]; then
            echo -ne "\t${BWhite}$(localize $1) $2  ${White}[${BWhite}Y${White}/n]:";
            read -n 1 -i "Y";
        else
            echo -ne "\t${BWhite}$(localize $1) $2  ${White}[y/${BWhite}N${White}]:";
            read -n 1 -i "N";
        fi
        YN_OPTION="$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')";
        echo "";
    }
    #}}}
    MY_OPTION=0
    while [[ "$MY_OPTION" -ne 1 ]]; do
        get_input_yn "$1" "$2" "$3";
        if [ -z "$YN_OPTION" ]; then
            MY_OPTION=1;
            YN_OPTION="$3";
        elif [[ "$YN_OPTION" == 'y' ]]; then
            MY_OPTION=1;
            YN_OPTION=1;
        elif [[ "$YN_OPTION" == 'n' ]]; then
            MY_OPTION=1;
            YN_OPTION=0;
        else
            MY_OPTION=0;
            if [[ "$3" -eq 1 ]]; then
                print_error "Wrong-Key-Yn";
            else
                print_error "Wrong-Key-Ny";
            fi
            pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    done
    write_log "read_input_yn [$3] answer $YN_OPTION" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; # Left out data, it could be a password or user name.
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 3 ]]; then
    do_read_input_yn_test()
    {
        read_input_yn "Wrong-Key-Q" "" 1;
        echo -e "\t=$YN_OPTION"
    }
    do_read_input_yn_test;
fi
#}}}
# -----------------------------------------------------------------------------
# READ INPUT DEFAULT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="read_input_default";
    USAGE="$(localize "READ-INPUT-DEFAULT-USAGE")";
    DESCRIPTION="$(localize "READ-INPUT-DEFAULT-DESC")";
    NOTES="$(localize "READ-INPUT-DEFAULT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="15 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "READ-INPUT-DEFAULT-USAGE" "read_input_default 1->(Prompt) 2->(Default Value) <- returns string in OPTION" "Comment: read_input_default @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-DEFAULT-DESC"  "Read Keyboard Input and allow Edit of Default value." "Comment: read_input_default @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-DEFAULT-NOTES" "None." "Comment: read_input_default @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
read_input_default()
{
    # read_input_default "Enter Data" "Default-Date"
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        OPTION="$2";
        return 0;
    fi
    read -e -p "$(localize "$1") >" -i "$2" OPTION;
    echo "";
}
#}}}
# -----------------------------------------------------------------------------
# READ INPUT DATA {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="read_input_data";
    USAGE="$(localize "READ-INPUT-DATA-USAGE")";
    DESCRIPTION="$(localize "READ-INPUT-DATA-DESC")";
    NOTES="$(localize "READ-INPUT-DATA-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "READ-INPUT-DATA-USAGE" "read_input_data 1->(Localized Prompt) <- return value OPTION" "Comment: read_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-DATA-DESC"  "Read Data." "Comment: read_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-DATA-NOTES" "Return value in variable OPTION; not to be used in AUTOMAN or INSTALL_WIZARD Mode, since there is no default value." "Comment: read_input_data @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
read_input_data()
{
    read -p "$(localize "$1") : " OPTION;
    write_log "read_input_data  $1 = $OPTION" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
}
#}}}
# -----------------------------------------------------------------------------
# VERIFY INPUT DEFAULT DATA {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="verify_input_default_data";
    USAGE="$(localize "VERIFY-INPUT-DEFAULT-DATA-USAGE")";
    DESCRIPTION="$(localize "VERIFY-INPUT-DEFAULT-DATA-DESC")";
    NOTES="$(localize "VERIFY-INPUT-DEFAULT-DATA-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "VERIFY-INPUT-DEFAULT-DATA-USAGE"     "verify_input_default_data 1->(Prompt) 2->(Default-Value) 3->(Default 1=Yes or 0=No) 4->(Data Type: 0=Numeric, 1=Alphanumeric, 2=IP Address, 3=Domain Name, 4=Path, 5=Folder, 6=Email, 7=Special, 8=Password, 9=Alpha, 10=Variable) <- return value in OPTION" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-DESC"      "Verify Keyboard Input of Default Editable Value." "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-NOTES"     "None." "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "VERIFY-INPUT-DEFAULT-DATA-ENTER"     "Enter" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-VERIFY"    "Verify" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-NOT-EMPTY" "Can not be empty" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-0"    "Numeric Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-1"    "Alphanumeric Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-2"    "IP Address Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-3"    "Domain Name Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-4"    "Full Path Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-5"    "Folder Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DEFAULT-DATA-TEST-6"    "Email Test Data" "Comment: verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
verify_input_default_data()
{
    if [[ "$#" -ne "4" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        write_log "$FUNCNAME $1 = $YN_OPTION" "${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]}"; # Left out data, it could be a password or user name.
        OPTION="$2";
        return 0;
    fi
    # READ VERIFY INPUT {{{
    read_verify_input()
    {
        echo "";
        # @FIX using -n puts it all on the same line; when you use Arrows, it messes up the screen, deletes the line, and in general looks ugly.
        # if text is not at left side of screen, it jumps to that location
        echo -e "${BWhite}$(localize "VERIFY-INPUT-DEFAULT-DATA-ENTER") $(localize "$1")${White} >";
        read -r -i "$2" -e OPTION;
        echo "";
    }
    #}}}
    local -i Is_Valid=0;
    YN_OPTION=0;
    while [[ "$YN_OPTION" -ne 1 ]]; do
        read_verify_input "$1" "$2";
        if [[ "$4" -eq 0 ]]; then # Numeric
            if $(is_number "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 1 ]]; then # Alphanumeric
            if $(is_alphanumeric "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 2 ]]; then # IP Address
            if $(is_valid_ip "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 3 ]]; then # Domain Name
            if $(is_valid_domain "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 4 ]]; then # Path
            if $(is_valid_path "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 5 ]]; then # Folder
            if $(is_valid_path "$OPTION") ; then
                Is_Valid=1;
            else
                if $(is_alphanumeric "$OPTION") ; then
                    Is_Valid=1;
                else
                    invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
                fi
            fi
        elif [[ "$4" -eq 6 ]]; then # email
            if $(is_valid_email "$OPTION") ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 7 ]]; then # Special A-Z upper and lower, and -, but make sure the - is not leading or trailing
            if [[ "$OPTION" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]] ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 8 ]]; then # Password - Replace * with |
            if [[ "$OPTION" =~ ^[__A-Za-z0-9]+|$ ]] ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 8 ]]; then # Clean Var
            OPTION=${OPTION//[-+=.,]/_}

            if [[ "$OPTION" =~ ^[__A-Za-z0-9]+$ ]] ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi

        elif [[ "$4" -eq 9 ]]; then # Alpha Only
            if [[ "$OPTION" =~ ^[__A-Za-z]+$ ]] ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        elif [[ "$4" -eq 10 ]]; then # Variable A-Z upper and lower, and _, but make sure the _ is not trailing
            if [[ "$OPTION" =~ ^[_a-zA-Z0-9][_a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]] ; then
                Is_Valid=1;
            else
                invalid_option "$OPTION @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]} ";
            fi
        fi
        # --------------------------------
        if [[ "$Is_Valid" -eq 1 ]]; then #
            read_input_yn "VERIFY-INPUT-DEFAULT-DATA-VERIFY" "$(localize "$1") : [$OPTION]" "$3";
            if [ -z "$YN_OPTION" ]; then
                echo "$(localize "VERIFY-INPUT-DEFAULT-DATA-NOT-EMPTY")!";
                YN_OPTION=0;
            fi
        fi
    done
    write_log "$FUNCNAME $1 = $YN_OPTION" "$FUNCNAME @ $(basename ${BASH_SOURCE[1]}) : ${FUNCNAME[1]} -> ${BASH_LINENO[1]}"; # Left out data, it could be a password or user name.
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 3 ]]; then
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-0" "2" 1 0; # 0 = Numeric
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Numeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Numeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-1" "A2" 1 1; # 1 = Alphanumeric
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Alphanumeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Alphanumeric ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-2" "0.0.0.0" 1 2; # 2 = IP Address
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data IP Address ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data IP Address ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-3" "domainname.com" 1 3; # 3 = Domain Name
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Domain Name ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Domain Name ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-4" "/Full/Path" 1 4; # 4 = Path
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Path ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Path ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-5" "/Full/Path" 1 5; # 5 = Folder
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Folder ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Folder ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    verify_input_default_data "VERIFY-INPUT-DEFAULT-DATA-TEST-6" "name@domain.com" 1 6; #6 = Email
    if [[ "$YN_OPTION" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  verify_input_default_data Email ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  verify_input_default_data Email ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    pause_function "verify_input_default_data @ $(basename $BASH_SOURCE) : $LINENO";
fi
#}}}
# -----------------------------------------------------------------------------
# VERIFY INPUT DATA {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="verify_input_data";
    USAGE="$(localize "VERIFY-INPUT-DATA-USAGE")";
    DESCRIPTION="$(localize "VERIFY-INPUT-DATA-DESC")";
    NOTES="$(localize "VERIFY-INPUT-DATA-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "VERIFY-INPUT-DATA-USAGE"  "verify_input_data 1->(Prompt) 2->(Data) <- return value OPTION" "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DATA-DESC"   "verify input data." "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DATA-NOTES"  "Localized." "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "VERIFY-INPUT-DATA-ENTER"  "Enter" "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DATA-VERIFY" "Verify" "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "VERIFY-INPUT-DATA-EMPTY"  "Can not be empty" "Comment: verify_input_data @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
verify_input_data()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [[ "$AUTOMAN" -eq 1 || "$INSTALL_WIZARD" -eq 1 && "$BYPASS" -eq 1 ]]; then
        OPTION="$2";
        return 0;
    fi
    # READ VERIFY INPUT {{{
    read_verify_input()
    {
        echo -ne "\t${BWhite}$(localize "VERIFY-INPUT-DATA-ENTER") $(localize "$1")${White}";
        read -p " : " OPTION;
    }
    #}}}
    YN_OPTION=0;
    while [[ "$YN_OPTION" -ne 1 ]]; do
        read_verify_input "$1"; # Returns OPTION
        read_input_yn "VERIFY-INPUT-DATA-VERIFY" "$(localize "$1"): [$OPTION]" "$2"; # Returns YN_OPTION
        if [ -z "$OPTION" ]; then
            echo "$(localize "VERIFY-INPUT-DATA-EMPTY")!";
            YN_OPTION=0;
        fi
    done
    write_log "$FUNCNAME $1 = $YN_OPTION" "$(basename $BASH_SOURCE) : $LINENO"; # Left out data, it could be a password or user name.
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# IS WILDCARD FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_wildcard_file";
    USAGE="$(localize "IS-WILDCARD-FILE-USAGE")";
    DESCRIPTION="$(localize "IS-WILDCARD-FILE-DESC")";
    NOTES="$(localize "IS-WILDCARD-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="12 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-WILDCARD-FILE-USAGE" "is_wildcard_file 1->(/from/path/) 2->(filter)" "Comment: is_wildcard_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-WILDCARD-FILE-DESC"  "Test for Files: is_wildcard_file '/from/path/' 'log' # if &lowast;.log exist." "Comment: is_wildcard_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-WILDCARD-FILE-NOTES" "filter: if ' ' all, else use extension, do not pass 'Array' in &lowast; as wildcard. If looking for a '/path/.hidden' file, a /path/&lowast; fails, so use no wild card, i.e. /path/." "Comment: is_wildcard_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_wildcard_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    # GET FILTER {{{
    get_filter()
    {
        echo $(find "$1" -type f \( -name "*.$2" \));
    }
    #}}}
    if [ ! -d "$1" ]; then
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "[$1] Directory Not Found : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1; # Path does not exist
    fi
    if [[ "$2" == " " ]]; then
        if find "$1" -maxdepth 0 -empty | read; then
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "[$1] * Not Found : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            return 1;  # EMPTY
        else
            return 0;  # NOT EMPTY
        fi
    else
        FILTER="$(get_filter "$1" "$2")";
        if [ -z "${FILTER}" ]; then
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "get_filter [$1] *.$2 Not Found : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            return 1;  # EMPTY
        else
            return 0; # NOT EMPTY
        fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [ -f "${FULL_SCRIPT_PATH}/gtranslate-cc.db" ]; then
        if is_wildcard_file "${FULL_SCRIPT_PATH}/" "db" ; then # " " | "ext"
            echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_wildcard_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_wildcard_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
        fi
        if is_wildcard_file "${FULL_SCRIPT_PATH}/" " " ; then # " " | "ext"
            echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_wildcard_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_wildcard_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
        fi
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# MAKE DIR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="make_dir";
    USAGE="$(localize "MAKE-DIR-USAGE")";
    DESCRIPTION="$(localize "MAKE-DIR-DESC")";
    NOTES="$(localize "MAKE-DIR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "MAKE-DIR-USAGE" "make_dir 1->(/Full/Path) 2->(Debugging Information)" "Comment: make_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-DIR-DESC"  "Make Directory." "Comment: make_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-DIR-NOTES" "return 0 if dir created." "Comment: make_dir @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
make_dir()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [[ -n "$1" ]]; then # Check for Empty
        [[ ! -d "$1" ]] && mkdir -p "$1";
        if [ -d "$1" ]; then
            if [[ "$SILENT_MODE" -eq 0 ]]; then
                write_log "make_dir $1 from $2 at $DATE_TIME" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
            return 0
        else
            write_error "make_dir $1 failed to create directory from line $2." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_error "make_dir $1 failed to create directory from line $2." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            return 1;
        fi
    else
        write_error "Empty: make_dir [$1] failed to create directory from line $2." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        print_error "make_dir $1 failed to create directory from line $2." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if make_dir "${FULL_SCRIPT_PATH}/Test/Target/Source/MakeMe/" ": make_dir @ $(basename $BASH_SOURCE) : $LINENO" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  make_dir ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  make_dir ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# COPY FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="copy_file";
    USAGE="$(localize "COPY-FILE-USAGE")";
    DESCRIPTION="$(localize "COPY-FILE-DESC")";
    NOTES="$(localize "COPY-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="24 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "COPY-FILE-USAGE" "copy_file 1->(/full-path/from.ext) 2->(/full-path/to_must_end_with_a_slash/) 3->(Debugging Information)" "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILE-DESC"  "Copy File." "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILE-NOTES" "Creates Destination Folder if not exist. LINENO is for Logging and Debugging." "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "COPY-FILE-FNF"   "File Not Found" "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILE-PATH"  "Path Empty."    "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILE-ARG"   "Empty Argument" "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILE-FAIL"  "Copy Failed"    "Comment: copy_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
copy_file()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    #
    if [ ! -f "$1" ]; then
        if [[ "${EXCLUDE_FILE_WARN[@]}" != *"$1"* ]]; then
            print_error "COPY-FILE-FNF" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            write_error "COPY-FILE-FNF" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "copy_file $1 to $2 from $3 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        fi
        return 1
    fi
    if [ -z "$2" ]; then # Check for Empty
        print_error "COPY-FILE-PATH" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "COPY-FILE-PATH" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "copy_file $1 to $2 from $3 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        return 1;
    fi
    local dir_to="${2%/*}";
    # local file_to="${2##*/}"
    if [ ! -d "$dir_to" ]; then # Check for Empty
        make_dir "$dir_to" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    if [[ -n "$1" && -n "$2" ]]; then # Check for Empty
        cp -f -- "$1" "$2"; # -- means stop looking for arguments, in case the file name or folder starts with a dash, and gets interpreted as a command
        if [ "$?" -eq 0 ]; then
            write_log "copy_file $1 to $2 from $3 at $DATE_TIME" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        else
            print_error "COPY-FILE-FAIL" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            write_error "COPY-FILE-FAIL" "copy_file $1 to $2 failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$1 to $2 from $3 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
            return 1;
        fi
    else
        print_error "COPY-FILE-ARG" "copy_file [$1] to [$2] failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "COPY-FILE-ARG" "copy_file [$1] to [$2] failed to copy file from $3 at $DATE_TIME. $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Empty: [$1] to [$2] from $3 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    copy_file "${FULL_SCRIPT_PATH}/help.html" "${FULL_SCRIPT_PATH}/Test/Target/Source/help.html" "copy_file @ $(basename $BASH_SOURCE) : $LINENO";
    if [ -f "${FULL_SCRIPT_PATH}/Test/Target/Source/help.html" ]; then # Only make changes once
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  copy_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  copy_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# COPY FILES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="copy_files";
    USAGE="$(localize "COPY-FILES-USAGE")";
    DESCRIPTION="$(localize "COPY-FILES-DESC")";
    NOTES="$(localize "COPY-FILES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "COPY-FILES-USAGE" "copy_files 1->(/full-path/) 2->(ext or Blank for *) 3->(/full-path/to_must_end_with_a_slash/) 4->(Debugging Information)<br />${HELP_TAB}copy_files 1->(/full-path/) 2->( ) 3->(/full-path/to_must_end_with_a_slash/) 4->(Debugging Information)" "Comment: copy_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILES-DESC"  "Creates Destination Folder if not exist. LINENO is for Logging and Debugging." "Comment: copy_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-FILES-NOTES" "If looking for a '/path/.hidden' file, a /path/&lowast; fails, so use no wild card, i.e. /path/" "Comment: copy_files @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
copy_files()
{
    if [[ "$#" -ne "4" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if ! is_wildcard_file "$1" "$2" ; then # " " | "ext"
        if [[ "$2" == " " ]]; then
            write_error "Files Not Found! copy_files->is_wildcard_file [$1] to [$3] failed to copy file from $4 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Files Not Found! -rfv [$1] to [$3] from $4 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        else
            write_error "Files Not Found! copy_files->is_wildcard_file [$1*.$2] to [$3] failed to copy file from $4 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Files Not Found! -fv [$1*.$2] to [$3] from $4 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        fi
        return 1;
    fi
    if [[ -z "$3" ]]; then # Check for Empty
        write_error "Path Emtpy! copy_files $1 to $3 failed to copy file from $4 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Path Emtpy! $1 to $3 from $4 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        return 1;
    fi
    local dir_to="${3%/*}";
    # local file_to="${3##*/}"
    if [ ! -d "$dir_to" ]; then  # Check for Empty
        make_dir "$dir_to" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    if [[ -n "$1" && -n "$3" ]]; then  # Check for Empty
        # echo -e "${BWhite} copy_files [$1*.$2] to [$3] ${White}";
        # -- means stop looking for arguments, in case the file name or folder starts with a dash, and gets interpreted as a command
        if [[ "$2" == " " ]]; then
            TEMP="$(cp -rfv -- "$1." "$3")";           # /path/. copy all files and folders recursively
        else
            TEMP="$(cp -rfv -- "${1}"*."${2}" "$3")";  # /path/*.ext copy only files with matching extensions
        fi
        if [ "$?" -eq 0 ]; then
            if [[ "$2" == " " ]]; then
                write_log "copy_files -rfv [$1.] to [$3] from $4 at $DATE_TIME" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            else
                write_log "copy_files -rfv [$1*.$2] to [$3] from $4 at $DATE_TIME" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        else
            print_error "copy_files -rfv [$1*.$2] to [$3] failed to copy file from $4 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$2" == " " ]]; then
                write_error "copy_files -rfv [$1.] to [$3] failed to copy file from $4." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            else
                write_error "copy_files -rfv [$1*.$2] to [$3] failed to copy file from $4 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$1*.$2 to $3 from $4 returned $TEMP (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
            return 1
        fi
    else
        write_error "Empty: copy_files [$1*.$2] to [$2] failed to copy file from $3 at $DATE_TIME." "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Empty: [$1*.$2] to [$2] from $3 (: $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO)"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    copy_files "${FULL_SCRIPT_PATH}/LOG/" "log" "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/" "copy_files @ $(basename $BASH_SOURCE) : $LINENO";
    if [ -f "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/0-wittywizard-error.log" ]; then # Only make changes once
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  copy_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  copy_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    rm -rf "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/";
    copy_files "${FULL_SCRIPT_PATH}/LOG/" " " "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/" "copy_files @ $(basename $BASH_SOURCE) : $LINENO";
    if [ -f "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/0-wittywizard-error.log" ]; then # Only make changes once
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  copy_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  copy_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# COPY DIRECTORY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="copy_dir";
    USAGE="$(localize "COPY-DIRECTORY-USAGE")";
    DESCRIPTION="$(localize "COPY-DIRECTORY-DESC")";
    NOTES="$(localize "COPY-DIRECTORY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "COPY-DIRECTORY-USAGE" "copy_dir 1->(/full-path/) 2->(/full-path/to_must_end_with_a_slash/) 3->(Debugging Information)" "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-DIRECTORY-DESC"  "Copy Directory." "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-DIRECTORY-NOTES" "None." "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "COPY-DIRECTORY-PATH"  "Empty Path." "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-DIRECTORY-COPY"  "Copied Directory" "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-DIRECTORY-ERROR" "Failed to copy Directory." "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COPY-DIRECTORY-MAKE"  "Failed to Make Directory." "Comment: copy_dir @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
copy_dir()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    #
    if [[ -z "$1" ]]; then
        print_error "COPY-DIRECTORY-PATH" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "COPY-DIRECTORY-PATH" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    #
    if [ -z "$2" ]; then
        print_error "COPY-DIRECTORY-PATH" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "COPY-DIRECTORY-PATH" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    #
    local dir_to="${2%/*}";
    # local file_to="${2##*/}"
    if [ ! -d "$dir_to" ]; then
        if [ -n "$dir_to" ]; then
            if ! make_dir "$dir_to" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" ; then
                print_error "COPY-DIRECTORY-MAKE" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                write_error "COPY-DIRECTORY-MAKE" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            fi
        fi
    fi
    #
    TEMP="$(cp -rfv -- "$1" "$2")"; # -- means stop looking for arguments, in case the file name or folder starts with a dash, and gets interpreted as a command
    if [ "$?" -eq 0 ]; then
        # print_this "COPY-DIRECTORY-COPY" "[$1] -> [$2] : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_log  "COPY-DIRECTORY-COPY" "[$1] -> [$2] : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    else
        print_error "COPY-DIRECTORY-ERROR" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "COPY-DIRECTORY-ERROR" "[$1] -> [$2] | $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        # @FIX if /etc resolv.conf needs its attributes changed
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if copy_dir "${FULL_SCRIPT_PATH}/LOG/" "${FULL_SCRIPT_PATH}/Test/Target/" ": copy_dir @ $(basename $BASH_SOURCE) : $LINENO" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  copy_dir ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  copy_dir ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_file";
    USAGE="$(localize "REMOVE-FILE-USAGE")";
    DESCRIPTION="$(localize "REMOVE-FILE-DESC")";
    NOTES="$(localize "REMOVE-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-FILE-USAGE"     "remove_file 1->(/full-path/from.ext) 2->(Debugging Information)" "Comment: remove_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILE-DESC"      "Remove File if it exist." "Comment: remove_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILE-NOTES"     "if -f > rm -f." "Comment: remove_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILE-NOT-FOUND" "Not Found" "Comment: remove_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -f "$1" ]; then
        rm -f "$1";
        # print_this "remove_file $1" " -> $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_log  "remove_file $1" " -> $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        return 0;
    else
        print_error "REMOVE-FILE-NOT-FOUND" ": remove_file [$1] @ $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "REMOVE-FILE-NOT-FOUND" ": remove_file [$1] @ $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        return 1;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    remove_file "${FULL_SCRIPT_PATH}/Test/Target/Source/help.html" "remove_file @ $(basename $BASH_SOURCE) : $LINENO";
    if [ ! -f "${FULL_SCRIPT_PATH}/Test/Target/Source/help.html" ]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE FILES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_files";
    USAGE="$(localize "REMOVE-FILES-USAGE")";
    DESCRIPTION="$(localize "REMOVE-FILES-DESC")";
    NOTES="$(localize "REMOVE-FILES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-FILES-USAGE"      "remove_files 1->(/Full-Path/) 2->(ext or Blank for *) 3->(Debugging Information)" "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILES-DESC"       "Remove Files if it exist." "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILES-NOTES"      "if -f > rm -f." "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILES-NOT-FOUND"  "Not Found" "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILES-FNF"        "File Not Found Failed to remove files" "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FILES-FAIL"       "Failed to remove files" "Comment: remove_files @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_files()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if ! is_wildcard_file "$1" "$2" ; then # " " | "ext"
        if [[ "$2" == " " ]]; then
            write_error "REMOVE-FILES-FNF" "[$1] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
            print_error "REMOVE-FILES-FNF" "[$1] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME [$1] @ $(basename $BASH_SOURCE) : $LINENO"; fi
        else
            write_error "REMOVE-FILES-FNF" "[$1*.$2] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
            print_error "REMOVE-FILES-FNF" "[$1*.$2] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME [$1*.$2] @ $(basename $BASH_SOURCE) : $LINENO"; fi
        fi
        return 1;
    fi
    #
    if [[ "$2" == " " ]]; then
        TEMP="$(rm -rfv "$1.")";           # /path/. remove all files and folders recursively
    else
        TEMP="$(rm -rfv "${1}"*."${2}")";  # /path/*.ext remove only files with matching extensions
    fi
    if [ "$?" -eq 0 ]; then
        if [[ "$2" == " " ]]; then
            write_log "REMOVE-FILES-FAIL" " remove_file -rfv [$1.]    -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
        else
            write_log "REMOVE-FILES-FAIL" " remove_file -rfv [$1*.$2] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO -> $3";
        fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    copy_files "${FULL_SCRIPT_PATH}/Test/Target/Source/Extras/" " " "${FULL_SCRIPT_PATH}/Test/Target/Source/Destination/" "remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    remove_files "${FULL_SCRIPT_PATH}/Test/Target/Source/Destination/" "log" "remove_files @ $(basename $BASH_SOURCE) : $LINENO";
    if [ ! -f "${FULL_SCRIPT_PATH}/Test/Target/Source/Destination/*.log" ]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_files ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE FOLDER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_folder";
    USAGE="$(localize "REMOVE-FOLDER-USAGE")";
    DESCRIPTION="$(localize "REMOVE-FOLDER-DESC")";
    NOTES="$(localize "REMOVE-FOLDER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-FOLDER-USAGE"     "remove_folder 1->(/Full-Path/) 2->(Debugging Information)" "Comment: remove_folder @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FOLDER-DESC"      "Remove Folder if it exist." "Comment: remove_folder @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FOLDER-NOTES"     "if -d > rm -rf /Full-Path/" "Comment: remove_folder @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FOLDER-NOT-FOUND" "Not Found" "Comment: remove_folder @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_folder()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -d "$1" ]; then
        rm -rf "$1"; # -- ?
        # print_this "remove_folder $1" " -> $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_log  "remove_folder $1" " -> $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        return 0;
    else
        print_error "REMOVE-FOLDER-NOT-FOUND" ": remove_folder [$1] @ $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "REMOVE-FOLDER-NOT-FOUND" ": remove_folder [$1] @ $2 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        return 1;
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    mkdir -p ${FULL_SCRIPT_PATH}/Test/Target/RemoveMe/;
    remove_folder "${FULL_SCRIPT_PATH}/Test/Target/RemoveMe/" "remove_folder @ $(basename $BASH_SOURCE) : $LINENO";
    if [ ! -d "${FULL_SCRIPT_PATH}/Test/Target/RemoveMe/" ]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_folder ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_folder ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# DELETE LINE IN FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="delete_line_in_file";
    USAGE="$(localize "DELETE-LINE-IN-FILE-USAGE")";
    DESCRIPTION="$(localize "DELETE-LINE-IN-FILE-DESC")";
    NOTES="$(localize "DELETE-LINE-IN-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" " @ $(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DELETE-LINE-IN-FILE-USAGE" "delete_line_in_file 1->(Text on line to Delete) 2->(/FullPath/FileName.ext)" "Comment: delete_line_in_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DELETE-LINE-IN-FILE-DESC"  "Given text of Line, Delete it in File" "Comment: delete_line_in_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DELETE-LINE-IN-FILE-NOTES" "This function is not ready to use, I forgot to finish it, so its just a stub that needs to be finished" "Comment: delete_line_in_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
delete_line_in_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    sed -i '/'${1}'/ d' "$2";
    return "$?";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    print_info "TEST-FUNCTION-RUN";
    # @FIX; This function is not ready to use, I forgot to finish it, so its just a stub that needs to be finished
fi
# -----------------------------------------------------------------------------
# COMMENT FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="comment_file";
    USAGE="$(localize "COMMENT-FILE-USAGE")";
    DESCRIPTION="$(localize "COMMENT-FILE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" " @ $(basename $BASH_SOURCE) : $LINENO";
fi
# Help file Localization
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "COMMENT-FILE-USAGE" "comment_file 1->(Text to Comment) 2->(/FullPath/FileName.ext)" "Comment: comment_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "COMMENT-FILE-DESC"  "Given text of Line, Comment it out in File" "Comment: comment_file @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "COMMENT-FILE-FNF"  "File not found" "Comment: comment_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
comment_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    [[ ! -f "$2" ]] && (print_error "COMMENT-FILE-FNF" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; return 1)
    local -i MyReturn=1;
    if is_string_in_file "$2" "$1" ; then
        sed -i 's/^'${1}'/#'${1}'/g' "$2";
        MyReturn="$?";
        if [[ "$RUN_TEST" -eq 1 ]]; then
            if ! is_string_in_file "$2" "#$1" ; then
                print_error "TEST-FUNCTION-FAILED" " comment_file @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        fi
    fi
    return "$MyReturn";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    echo "Defaults: some value, line content does not matter" > "${FULL_SCRIPT_PATH}/Test/Target/Source/mytest.txt"
    if comment_file "Defaults:" "${FULL_SCRIPT_PATH}/Test/Target/Source/mytest.txt" ; then
        print_test "TEST-FUNCTION-PASSED"  " comment_file @ $(basename $BASH_SOURCE) : $LINENO";
    else
        print_error "TEST-FUNCTION-FAILED" " comment_file @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# UN-COMMENT FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="un_comment_file";
    USAGE="$(localize "UN-COMMENT-FILE-USAGE")";
    DESCRIPTION="$(localize "UN-COMMENT-FILE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
# Help file Localization
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "UN-COMMENT-FILE-USAGE" "un_comment_file 1->(Text) 2->(/FullPath/FileName.ext)" "Comment: un_comment_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UN-COMMENT-FILE-DESC"  "Given text of Line, un-Comment it out in File" "Comment: un_comment_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
un_comment_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    [[ ! -f "$2" ]] && (print_error "COMMENT-FILE-FNF" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; return 1);
    local -i MyReturn=1;
    #if is_string_in_file "$2" "#$1" ; then
    if [ $(egrep -ic "#$1" "$2") -gt 0 ]; then
        sed -i "/${1}/ s/# *//" "$2";
        MyReturn="$?";
        if [[ "$RUN_TEST" -eq 1 ]]; then
            if is_string_in_file "$2" "#$1" ; then
                print_error "TEST-FUNCTION-FAILED" " $FUNCNAME ($MyReturn) @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        fi
    fi
    return "$MyReturn";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if un_comment_file "Defaults:" "${FULL_SCRIPT_PATH}/Test/Target/Source/mytest.txt" ; then
        print_test "TEST-FUNCTION-PASSED"  " un_comment_file @ $(basename $BASH_SOURCE) : $LINENO";
    else
        print_error "TEST-FUNCTION-FAILED" " un_comment_file @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# REPLACE OPTION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="replace_option";
    USAGE="$(localize "REPLACE-OPTION-USAGE")";
    DESCRIPTION="$(localize "REPLACE-OPTION-DESC")";
    NOTES="$(localize "REPLACE-OPTION-NOTES")";
    # http://www.grymoire.com/Unix/Quote.html
    # http://www.grymoire.com/Unix/Sed.html
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REPLACE-OPTION-USAGE" "replace_option 1->(/Config/FullPath/FileName.ext) 2->(Option-String) 3->(Text to Replace) 4->(Package Name)" "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REPLACE-OPTION-DESC"  "Replace Option: Given File Name, Option and Text, add option to end of line in file." "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REPLACE-OPTION-NOTES" "If you have a string in a file: i.e. '[Option]=', you can append Text to add to it: i.e. '[Option]=Text Added'" "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REPLACE-OPTION-SF"    "Warning: String Exist:" "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REPLACE-OPTION-ERROR" "Error: String not Found:" "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REPLACE-OPTION-FNF"   "File Not Found:" "Comment: replace_option @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
replace_option()
{
    # replace_option "/usr/share/config/kdm/test-options.conf" "AllowClose=" "true" "APPEND-FILE-"
    # sed '/AllowClose=/ c\AllowClose=true' /home/UserName/Downloads/arch-git/archwiz/Test/Target/Source/test-options.conf
    # AllowClose=false to AllowClose=true
    if [[ "$#" -ne "4" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -f "$1" ]; then
        if is_string_in_file "$1" "$2" ; then
            if ! is_string_in_file "$1" "${2}$3" ; then
                #debugger 1
                sed -i 's/^'${2}'.*$/'${2}${3}'/' ${1};
                #echo "sed returned: $?"
                #debugger 0
                return "$?";
            else
                print_warning "REPLACE-OPTION-SF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                write_error "REPLACE-OPTION-SF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        else
            print_error "REPLACE-OPTION-ERROR";
            write_error "REPLACE-OPTION-ERROR" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    else
        print_error "REPLACE-OPTION-FNF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "REPLACE-OPTION-FNF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [ ! -f "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" ]; then
        touch "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf";
        echo "AllowClose=false"                                                          > "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf";
        echo "SessionsDirs=/usr/share/config/kdm/sessions,/usr/share/apps/kdm/sessions" >> "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf";
        echo "This=That"                                                                >> "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf";
    fi
    if is_string_in_file "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" "AllowClose=true" ; then
        replace_option "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" 'AllowClose=' 'false' 'REPLACE-OPTION-TEST';
    fi
    replace_option "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" 'AllowClose=' 'true' 'REPLACE-OPTION-TEST';
    if is_string_in_file "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" "AllowClose=true" ; then
        print_test "TEST-FUNCTION-PASSED"  " replace_option @ $(basename $BASH_SOURCE) : $LINENO";
    else
        print_error "TEST-FUNCTION-FAILED" " replace_option @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# ADD OPTION {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_option";
    USAGE="$(localize "ADD-OPTION-USAGE")";
    DESCRIPTION="$(localize "ADD-OPTION-DESC")";
    NOTES="$(localize "ADD-OPTION-NOTES")";
    # http://www.grymoire.com/Unix/Quote.html
    # http://www.grymoire.com/Unix/Sed.html
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-OPTION-USAGE" "add_option 1->(/Config/FullPath/FileName.ext) 2->(Option-String) 3->(Text to Add) 4->(Package Name)" "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-OPTION-DESC"  "Add Option: Given File Name, Option and Text, add option to end of line in file." "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-OPTION-NOTES" "If you have a string in a file: i.e. '[Option]=', you can append Text to add to it: i.e. '[Option]=Text Added'" "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-OPTION-SF"    "Warning: String Exist:" "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-OPTION-ERROR" "Error: String not Found:" "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-OPTION-FNF"   "File Not Found:" "Comment: add_option @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_option()
{
    if [[ "$#" -ne "4" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -f "$1" ]; then
        if is_string_in_file "$1" "$2" ; then
            if ! is_string_in_file "$1" "$3" ; then
                sed -i '/'${2}'/ s_$_'${3}'_' ${1};
                return "$?";
            else
                print_warning "ADD-OPTION-SF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                write_error "ADD-OPTION-SF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
        else
            print_error "ADD-OPTION-ERROR" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            write_error "ADD-OPTION-ERROR" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    else
        print_error "ADD-OPTION-FNF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "ADD-OPTION-FNF" "$1 - $2 - $3 - Package: $4 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    # add_option "/usr/share/config/kdm/test-options.conf" "SessionsDirs=" ",/usr/share/xsessions" "APPEND-FILE-"
    # SessionsDirs=/usr/share/config/kdm/sessions,/usr/share/apps/kdm/sessions
    # Check to see if this exist
    if is_string_in_file "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" ",/usr/share/xsessions" ; then
        replace_option "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" 'SessionsDirs=' '/usr/share/config/kdm/sessions,/usr/share/apps/kdm/sessions' 'ADD-OPTION-TEST';
    fi
    add_option "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" 'SessionsDirs=' ',/usr/share/xsessions' 'ADD-OPTION-TEST';
    if is_string_in_file "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf" ",/usr/share/xsessions" ; then
        print_test "TEST-FUNCTION-PASSED"  " add_option @ $(basename $BASH_SOURCE) : $LINENO";
    else
        print_error "TEST-FUNCTION-FAILED" " add_option @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    rm -f "${FULL_SCRIPT_PATH}/Test/Target/Source/test-options.conf";
fi
#}}}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# MAKE FILE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="make_file";
    USAGE="$(localize "MAKE-FILE-USAGE")";
    DESCRIPTION="$(localize "MAKE-FILE-DESC")";
    NOTES="$(localize "MAKE-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "MAKE-FILE-USAGE"  "make_file 1->(FileName.ext) 2->(Debugging Information)" "Comment: make_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-FILE-DESC"  "Make file." "Comment: make_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-FILE-NOTES" "None." "Comment: make_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-FILE-PASSED" "Make File created" "Comment: make_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MAKE-FILE-FAILED" "Failed to create File" "Comment: make_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
make_file()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [[ -n "$1" && -n "$2" ]]; then # Check for Empty
        [[ ! -f "$1" ]] && touch "$1";
        if [ -f "$1" ]; then
            write_log "MAKE-FILE-PASSED" ": $1 # $2 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 0;
        else
            write_error "MAKE-FILE-FAILED" ": $1 # $2 : -f : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            return 1;
        fi
    else
        write_error "MAKE-FILE-FAILED" "$1 # $2 : -n : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        print_error "MAKE-FILE-FAILED" "$1 # $2 : -n : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "Empty: [$1] at $3 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if make_file "${FULL_SCRIPT_PATH}/Test/Target/Source/MakeMe/me.txt" ": make_file @ $(basename $BASH_SOURCE) : $LINENO" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  make_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  make_file ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# SAVE ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="save_array";
    USAGE="$(localize "SAVE-ARRAY-USAGE")";
    DESCRIPTION="$(localize "SAVE-ARRAY-DESC")";
    NOTES="$(localize "SAVE-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SAVE-ARRAY-USAGE" "save_array 1->(Array(@)) 2->(/Path) 3->(MenuName.ext)" "Comment: save_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SAVE-ARRAY-DESC"  "Save Array." "Comment: save_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SAVE-ARRAY-NOTES" "None." "Comment: save_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SAVE-ARRAY-ERROR" "Error Saving Array." "Comment: save_array @ $(basename $BASH_SOURCE) : $LINENO"
fi
# -------------------------------------
save_array()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    make_dir "${2}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    touch "${2}/$3";
    local -a array=("${!1}");
    local -i total="${#array[@]}";
    for (( i=0; i<total; i++ )); do
        if [[ "$i" == 0 ]]; then
            echo "${array[$i]}"  > "${2}/$3"; # Overwrite
        else
            echo "${array[$i]}" >> "${2}/$3"; # Append
        fi
    done
    if [ ! -f "${2}/$3" ]; then
        write_error "SAVE-ARRAY-ERROR" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        print_error "SAVE-ARRAY-ERROR" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArray=( "1" "2" "3");
    if save_array "MyArray[@]" "${FULL_SCRIPT_PATH}/Test/Target/Source/" "MyArray.db" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  save_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  save_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# LOAD ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="load_array";
    USAGE="$(localize "LOAD-ARRAY-USAGE")";
    DESCRIPTION="$(localize "LOAD-ARRAY-DESC")";
    NOTES="$(localize "LOAD-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "LOAD-ARRAY-USAGE" "Array=( &#36;(load_array 1->(/Path/ArrayName.ext) 2->(ArrarySize) 3->(Default Data) ) )" "Comment: load_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-ARRAY-DESC"  "Load a saved Array from Disk." "Comment: load_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-ARRAY-NOTES" "None." "Comment: load_array @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
load_array()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    if [[ -f "$1" ]]; then
        while read line; do
            echo "$line"; # Stored Data
        done < "$1" # Load Array from serialized disk file
    else
        MyTotal="$2";
        for (( i=0; i<MyTotal; i++ )); do
            echo "$3"; # Default Data
        done
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
    MyArray=( $(load_array "${FULL_SCRIPT_PATH}/Test/Target/Source/MyArray.db" 0 0 ) );
    totalnArr="${#MyArray[@]}";
    if [[ "$totalnArr" -eq 3 ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  load_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  load_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    IFS="$OLD_IFS";
fi
#}}}
# -----------------------------------------------------------------------------
# CREATE DATA ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="create_data_array";
    USAGE="$(localize "CREATE-DATA-ARRAY-USAGE")";
    DESCRIPTION="$(localize "CREATE-DATA-ARRAY-DESC")";
    NOTES="$(localize "CREATE-DATA-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CREATE-DATA-ARRAY-USAGE" "create_data_array 1->(ArrarySize) 2->(Default Data)" "Comment: create_data_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATA-ARRAY-DESC"  "Create Data Array." "Comment: create_data_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATA-ARRAY-NOTES" "None." "Comment: create_data_array @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
create_data_array()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} -> ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    [[ "$1" -eq 0 ]] && return 0;
    MyTotal="$1";
    for (( i=0; i<MyTotal; i++ )); do
        echo "$2"; # Default Data
    done
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
    MyArray=( $(create_data_array 3 0 ) );
    IFS="$OLD_IFS";
    totalnArr="${#MyArray[@]}";
    if [[ "$totalnArr" -eq 3 ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  create_data_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  create_data_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# PRINT MENU {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="print_menu";
    USAGE="$(localize "PRINT-MENU-USAGE")";
    DESCRIPTION="$(localize "PRINT-MENU-DESC")";
    NOTES="$(localize "PRINT-MENU-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PRINT-MENU-USAGE" "print_menu 1->(MenuArray[@]) 2->(Menu_InfoArray[@]) 3->(Letter to Exit)" "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-MENU-DESC"  "Print Menu." "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-MENU-NOTES" "Localized." "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "MENU-Q" "Quit" "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MENU-B" "Back" "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "MENU-D" "Done" "Comment: print_menu @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
print_menu()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[1]} ${White}"; exit 1; fi
    local -a arrayMenu=("${!1}");     # Array
    local -i total="${#arrayMenu[@]}";
    #
    local -a arrayInfo=("${!2}");     # Array
    local -i totalInfo="${#arrayInfo[@]}";
    #
    local -i index=0;
    tput sgr0;
    #
    echo ''; # Line under Title
    # Print Information Screen Above Menu
    for (( index=0; index<totalInfo; index++ )); do
        if [[ "$totalInfo" -le 8 ]]; then
            if [ "${#arrayInfo[$index]}" -gt 0 ]; then
                print_list "${SPACE}${arrayInfo[$index]}";
            fi
        else
            if [ "${#arrayInfo[$index]}" -gt 0 ]; then
                print_list "${arrayInfo[$index]}";
            fi
        fi
    done
    # Print Menu
    echo "";
    for (( index=0; index<total; index++ )); do
        if [[ "$index" -le 8 ]]; then
            echo -e "${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${arrayMenu[$index]}"; tput sgr0;
        else
            echo -e "${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${arrayMenu[$index]}"; tput sgr0;
        fi
        ((LAST_MENU_ITEM++));
    done
    MY_ACTION=" ";
    if [[ "$3" == 'Q' ]]; then
        MY_ACTION="$(localize "MENU-Q")";
        BREAKABLE_KEY="Q";
    elif [[ "$3" == 'B' ]]; then
        MY_ACTION="$(localize "MENU-B")";
        BREAKABLE_KEY="B";
    elif [[ "$3" == 'D' ]]; then
        MY_ACTION="$(localize "MENU-D")";
        BREAKABLE_KEY="D";
    fi
    echo "";
    # Print Menu Breakable Key
    if [[ "$index" -le 8 ]]; then
        echo -e "${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${3}) $MY_ACTION"; tput sgr0;
    else
        echo -e "${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${SPACE}${3}) $MY_ACTION"; tput sgr0;
    fi
    echo "";
}
#}}}
# -----------------------------------------------------------------------------
# ADD MENU ITEM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_menu_item";
    USAGE="$(localize "ADD-MENU-ITEM-USAGE")";
    DESCRIPTION="$(localize "ADD-MENU-ITEM-DESC")";
    NOTES="$(localize "ADD-MENU-ITEM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-MENU-ITEM-USAGE" "add_menu_item 1->(Checkbox_List_Array) 2->(Menu_Array) 3->(Info_Array) 4->(Menu Description in White) 5->(In Yellow) 6->(In Red) 7->(Information Printed Above Menu) 8->(MenuTheme_Array[@])" "Comment: add_menu_item @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-MENU-ITEM-DESC"  "Add Menu Item." "Comment: add_menu_item @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-MENU-ITEM-NOTES" "Text should be Localize ID." "Comment: add_menu_item @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_menu_item()
{
    if [[ "$#" -ne "8" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    local -i total=0;
    # 1. Checkbox List Array -> 0 based Array
    # 2. Menu Array
    # 3. Info-Array
    # 4. Menu Description (In White)
    # 5. Menu Description (In Yellow)
    # 6. Menu Description (In Red)
    # 7. Informatin Printed Above Menu -> Build InfoArray
    # 8. Theme
    # @FIX pass in Checkbox-List-Array
    # RESET_MENU Unused; but lets function knows its a new menu

    #local -a checkbox_array=("${!1}")  # Checkbox List Array
    #echo "checkbox_array=${checkbox_array[@]}"
    eval "total_checkbox=\${#$1[@]}"; # Checkbox_List_Array = 0 First Time
    if [[ "$total_checkbox" -eq 0 ]]; then
        array_push "$1" "0"; # First Time we Create a Blank Checkbox Array; this means that a Save menu has not been Restored; so set it to 0
        total_checkbox=1;
        LAST_MENU_ITEM=0;    # Reset this to 0, so we can count all menus and get total
    fi
    eval "total=\${#$2[@]}"; # Menu_Array = 0 First Time; we push results into it
    #
    if [[ "$total" -ge "$total_checkbox" ]]; then # First time total=0 and total_checkbox=1, Second time total=1 and total_checkbox=1, so we need to push a new chechbox, since we will push another menu item
        array_push "$1" "0";
        ((total_checkbox++));
    fi
    #
    eval "cba=\${$1[$total]}"; # First time=0, Second time=1...
    #
    if [[ -z "$cba" ]]; then
        cba=0;
        if [[ "$RUN_TEST" -eq 2 ]]; then
            print_error "add_menu_item checkbox null value is wrong! Menu Description: $4 " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
        write_error "add_menu_item checkbox null value is wrong! Menu Description: $4 " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    if ! is_number "$cba" ; then
        if [[ "$RUN_TEST" -eq 2 ]]; then
            print_error "add_menu_item checkbox value is wrong! total=$total cba=$cba Menu Description: $4 " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
        write_error "add_menu_item checkbox value is wrong! total=$total cba=$cba Menu Description: $4 " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        cba=0;
    fi
    #
    local -a arrayTheme=("${!8}");     # Theme Array
    local -i total_theme="${#arrayTheme[@]}";
    if [[ "$total_theme" -ne 3 ]]; then
        write_error "add_menu_item MenuTheme_Array should have 3 elements: total=$total Menu Description: $4 " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        arrayTheme[0]="${Yellow}";
        arrayTheme[1]="${White}";
        arrayTheme[2]=")";
    fi
    #
    array_push "$2" "${arrayTheme[0]}$(( total + 1 ))${arrayTheme[2]}${arrayTheme[1]} $(checkbox ${cba}) ${BWhite}$(localize "$4") ${BYellow}$(localize "$5") ${BRed}$(localize "$6")${White}";
    array_push "$3" "$(localize "$7")";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# RESTART INTERNET {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="restart_internet";
    USAGE="restart_internet";
    DESCRIPTION="$(localize "RESTART-INTERNET-DESC")";
    NOTES="$(localize "RESTART-INTERNET-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "RESTART-INTERNET-DESC"  "Restart Internet." "Comment: restart_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RESTART-INTERNET-NOTES" "Assumes system.d; uses systemctl restart; needs generic functions for other then Arch Linux calls." "Comment: restart_internet @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
restart_internet()
{
    # FIXIT make OS dependent
    if [[ "$My_OS" == "solaris" ]]; then
            network restart;
    elif [[ "$My_OS" == "aix" ]]; then
            network restart;
    elif [[ "$My_OS" == "freebsd" ]]; then
            network restart;
    elif [[ "$My_OS" == "windowsnt" ]]; then
            network restart;
    elif [[ "$My_OS" == "mac" ]]; then
            network restart;
    elif [[ "$My_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            /etc/init.d/network restart;
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            if [[ "$NETWORK_MANAGER" == "networkmanager" ]]; then
                sudo systemctl restart NetworkManager.service;
            elif [[ "$NETWORK_MANAGER" == "wicd" ]]; then
                sudo systemctl restart wicd.service;
                wicd-client;
            fi
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
             if [[ "$My_PSUEDONAME" == "Ubuntu" ]]; then
                service networking restart;
             else
                /etc/init.d/networking restart;
             fi
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                network restart;
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
               network restart;
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                network restart;
        elif [[ "$My_DIST" == "slackware" ]]; then # -------------------------------- My_PSUEDONAME = Slackware Linux Distros
                /etc/rc.d/rc.inet1 restart;
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# FIX NETWORK {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="fix_network";
    USAGE="fix_network";
    DESCRIPTION="$(localize "FIX-NETWORK-DESC")";
    NOTES="$(localize "FIX-NETWORK-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "FIX-NETWORK-DESC"  "Fix Network." "Comment: fix_network @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FIX-NETWORK-NOTES" "None." "Comment: fix_network @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "FIX-NETWORK-NETWORKMANAGER" "Restarting networkmanager via systemctl..." "Comment: fix_network @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FIX-NETWORK-WICD"           "Restarting wicd via systemctl..." "Comment: fix_network @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FIX-NETWORK-TRIED-TO-FIX"   "Tried to fix network connection; you may have to run this script again." "Comment: fix_network @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
fix_network()
{
        # FIXIT make OS dependent
    if [[ "$My_OS" == "solaris" ]]; then
            network restart;
    elif [[ "$My_OS" == "aix" ]]; then
            network restart;
    elif [[ "$My_OS" == "freebsd" ]]; then
            network restart;
    elif [[ "$My_OS" == "windowsnt" ]]; then
            network restart;
    elif [[ "$My_OS" == "mac" ]]; then
            network restart;
    elif [[ "$My_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            /etc/init.d/network restart;
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            if [[ "$NETWORK_MANAGER" == "networkmanager" ]]; then
                # networkmanager
                # Internet is down; no use trying to install software
                #if ! check_package networkmanager ; then
                #    if [[ "$KDE_INSTALLED" -eq 1 ]]; then
                #        package_install "networkmanager kdeplasma-applets-networkmanagement" "INSTALL-NETWORKMANAGER-KDE"
                #        if [[ "$MATE_INSTALLED" -eq 1 ]]; then
                #            package_install "network-manager-applet" "INSTALL-NETWORKMANAGER-MATE"
                #        fi
                #    else
                #        package_install "networkmanager network-manager-applet" "INSTALL-NETWORKMANAGER-OTHER"
                #    fi
                #    package_install "networkmanager-dispatcher-ntpd" "INSTALL-NETWORKMANAGER"
                #fi
                #add_group "networkmanager"
                #add_user_2_group "networkmanager"
                print_info "FIX-NETWORK-NETWORKMANAGER";
                sudo systemctl enable NetworkManager.service;
                sudo systemctl start NetworkManager.service;
            elif [[ "$NETWORK_MANAGER" == "wicd" ]]; then
                #if ! check_package networkmanager ; then
                #    if [[ "$KDE" -eq 1 ]]; then
                #        aur_package_install "wicd wicd-kde" "AUR-INSTALL-NETWORKMANAGER-KDE"
                #    else
                #        package_install "wicd wicd-gtk" "INSTALL-NETWORKMANAGER-GTK"
                #    fi
                #fi
                print_info "FIX-NETWORK-WICD";
                sudo systemctl enable wicd.service;
                sudo systemctl start wicd.service;
                wicd-client;
            fi
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
             if [[ "$My_PSUEDONAME" == "Ubuntu" ]]; then
                service networking restart;
             else
                /etc/init.d/networking restart;
             fi
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                network restart;
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
               network restart;
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                network restart;
        elif [[ "$My_DIST" == "slackware" ]]; then # -------------------------------- My_PSUEDONAME = Slackware Linux Distros
                /etc/rc.d/rc.inet1 restart;
        fi
    fi
    # @FIX More testing and repairing
    sleep 20;
    if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
        if ! is_internet ; then
            sleep 10;
            if ! is_internet ; then
                print_error "FIX-NETWORK-TRIED-TO-FIX"; # if you see this; 20 seconds wasn't long enough, add another 10 for a full half minute
                return 1;
            fi
        fi
    fi
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# NETWORK TROUBLESHOOTING {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="network_troubleshooting";
    USAGE="network_troubleshooting";
    DESCRIPTION="$(localize "NETWORK-TROUBLESHOOTING-DESC")";
    NOTES="$(localize "NETWORK-TROUBLESHOOTING-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "NETWORK-TROUBLESHOOTING-DESC"    "Network Troubleshooting." "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-NOTES"   "None." "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "NETWORK-TROUBLESHOOTING-TITLE"   "Network Troubleshooting" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-0"  "Network Debugging" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-1"  "1: Networkmanager: install and start, this is always the best way to start troubleshooting." "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-2"  "2: Disk Resolv: Edit/Review namerservers.txt on disk, then copy it to local disk." "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-3"  "3: Local Resolv:Edit/Review local /etc/resolv.conf" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-4"  "4: Identify which network interfaces" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-5"  "5: Link status: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-6"  "6: IP Address: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-7"  "7: Ping: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-8"  "8: Devices: Show all ethx that are active" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-9"  "9: Show Users: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-10" "10: Static IP: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-11" "11: Gateway: " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-12" "12: Quit" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-13" "Identify" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-14" "Link status" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-INFO-15" "Network Debugging" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-RD-1"    "Enter IP address (192.168.1.2) " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-RD-2"    "Enter IP Mask (255.255.255.0 = 24) " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-RD-3"    "Enter IP address for Gateway (192.168.1.1) " "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-SELECT"  "Select an Option:" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NETWORK-TROUBLESHOOTING-NIC"     "Select a NIC:" "Comment: network_troubleshooting @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
network_troubleshooting()
{
    get_network_devices;
    load_software;
    while [[ 1 ]]; do
        print_title "NETWORK-TROUBLESHOOTING-TITLE" " ";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-0";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-1";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-2";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-3";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-4";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-5";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-6";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-7";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-8";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-9";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-10";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-11";
        echo "";
        print_info  "NETWORK-TROUBLESHOOTING-INFO-12";
        #                   1              2              3             4          5         6         7          8         9         10           11        12
        NETWORK_TROUBLE=("Networkmanager" "Disk Resolv" "Local Resolv" "Identify" "Link" "IP address" "Ping"  "Devices" "Show Users" "Static IP" "Gateway" "Quit");
        PS3="$prompt1";
        print_this "NETWORK-TROUBLESHOOTING-SELECT";
        echo "";
        select OPT in "${NETWORK_TROUBLE[@]}"; do
            case "$REPLY" in
                1)  # Networkmanager
                    fix_network;
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                2)  # Disk Resolv
                    custom_nameservers;
                    if [[ "$My_OS" == "solaris" ]]; then
                            cat /etc/resolv.conf ;
                    elif [[ "$My_OS" == "aix" ]]; then
                            cat /etc/resolv.conf ;
                    elif [[ "$My_OS" == "freebsd" ]]; then
                            cat /etc/resolv.conf ;
                    elif [[ "$My_OS" == "windowsnt" ]]; then
                            cat /etc/resolv.conf ;
                    elif [[ "$My_OS" == "mac" ]]; then
                            cat /etc/resolv.conf ;
                    elif [[ "$My_OS" == "linux" ]]; then
                        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
                        # See wizard.sh os_info to see if OS test exist or works
                        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                            cat /etc/resolv.conf ;
                        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
                            cat /etc/resolv.conf ;
                        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
                            cat /etc/resolv.conf ;
                        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                            cat /etc/resolv.conf ;
                        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
                            cat /etc/resolv.conf ;
                        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                            cat /etc/resolv.conf ;
                        fi
                    fi
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                3)  # Local Resolv
                    if [[ "$My_OS" == "solaris" ]]; then
                            $EDITOR /etc/resolv.conf;
                    elif [[ "$My_OS" == "aix" ]]; then
                            $EDITOR /etc/resolv.conf;
                    elif [[ "$My_OS" == "freebsd" ]]; then
                            $EDITOR /etc/resolv.conf;
                    elif [[ "$My_OS" == "windowsnt" ]]; then
                            $EDITOR /etc/resolv.conf;
                    elif [[ "$My_OS" == "mac" ]]; then
                            $EDITOR /etc/resolv.conf;
                    elif [[ "$My_OS" == "linux" ]]; then
                        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
                        # See wizard.sh os_info to see if OS test exist or works
                        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                            $EDITOR /etc/resolv.conf;
                        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
                            $EDITOR /etc/resolv.conf;
                        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
                            $EDITOR /etc/resolv.conf;
                        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                            $EDITOR /etc/resolv.conf;
                        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
                            $EDITOR /etc/resolv.conf;
                        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                            $EDITOR /etc/resolv.conf;
                        fi
                    fi
                    break;
                    ;;
                4)  # Identify
                    print_info "NETWORK-TROUBLESHOOTING-INFO-15" ": ip a ";
                    ip a;
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                5)  # Link
                    print_info "NETWORK-TROUBLESHOOTING-INFO-16" ": ip link show dev eth0";
                    for MyNIC in ${NIC[@]}; do
                        ip link show dev "$MyNIC";
                    done
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                6)  # IP address
                    print_info "NETWORK-TROUBLESHOOTING-INFO-16" ": ip addr show dev eth0";
                    for MyNIC in ${NIC[@]}; do
                        ip addr show dev "$MyNIC";
                    done
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                7)  # Ping
                    ping -c 3 "$PingHost1";
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                8)  # Devices
                    get_network_devices;
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
                9)  # Show Users
                    show_users;
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
               10)  # Add Static IP address
                    print_title "NETWORK-TROUBLESHOOTING-TITLE" " ";
                    print_info  "NETWORK-TROUBLESHOOTING-INFO-17";
                    # Add Static IP address
                    PS3="$prompt1";
                    print_this "NETWORK-TROUBLESHOOTING-NIC";
                    echo "";
                    select OPT in "${NIC[@]}"; do
                        case "$REPLY" in
                            1)
                                NIC_DEV="$NIC[0]";
                                break;
                                ;;
                            2)
                                NIC_DEV="$NIC[0]";
                                break;
                                ;;
                            3)
                                NIC_DEV="$NIC[0]";
                                break;
                                ;;
                            *)
                                invalid_option "$REPLY";
                                ;;
                        esac
                    done
                    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
                    read_input_data "NETWORK-TROUBLESHOOTING-RD-1"; # Enter IP Address
                    IP_ADDRESS="$OPTION";
                    read_input_data "NETWORK-TROUBLESHOOTING-RD-2";
                    BYPASS="$Old_BYPASS"; # Restore Bypass
                    IP_MASK="$OPTION";
                    ip addr add "${IP_ADDRESS}/${IP_MASK}" dev "$NIC_DEV";
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;

               11)  # Add Static Gateway
                    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
                    read_input_data "NETWORK-TROUBLESHOOTING-RD-3";
                    BYPASS="$Old_BYPASS"; # Restore Bypass
                    IP_ADDRESS="$OPTION";
                    ip route add default via "$IP_ADDRESS";
                    pause_function "network_troubleshooting $LINENO";
                    break;
                    ;;
               12)  # Quit
                    exit 1;
                    ;;
              'q')
                    break;
                    ;;
                *)
                    invalid_option "$REPLY";
                    ;;
            esac
       done
       is_breakable "$REPLY" "q";
   done
}
#}}}
# -----------------------------------------------------------------------------
# IS INTERNET {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_internet";
    USAGE="is_internet";
    DESCRIPTION="$(localize "IS-INTERNET-DESC")";
    NOTES="$(localize "IS-INTERNET-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-INTERNET-DESC"  "Check if Internet is up by Pinging two Major DNS servers." "Comment: is_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-INTERNET-NOTES" "This pings google.com and wikipedia.org; they are good to ping to see if the Internet is up." "Comment: is_internet @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "IS-INTERNET-INFO" "Checking for Internet Connection..." "Comment: is_internet @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_internet()
{
    print_this "IS-INTERNET-INFO" "$PingHost1 or $PingHost2";
    ((ping -w5 -c3 "$PingHost1" || ping -w5 -c3 "$PingHost2") > /dev/null 2>&1) && return 0 || return 1;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_internet ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_internet ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_internet ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        fix_network;
        if is_internet ; then
            echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_internet ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_internet ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# IS ONLINE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_online";
    USAGE="$(localize "IS-ONLINE-USAGE")";
    DESCRIPTION="$(localize "IS-ONLINE-DESC")";
    NOTES="$(localize "IS-ONLINE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-ONLINE-USAGE" "is_online 1->(url)" "Comment: is_online @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-ONLINE-DESC"  "Check if URL can be Pinged through the Internet." "Comment: is_online @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-ONLINE-NOTES" "This pings URL passed in." "Comment: is_online @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "IS-ONLINE-INFO" "Checking URL for Internet Connection..." "Comment: is_online @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_online()
{
    print_this "IS-ONLINE-INFO" "$1";
    if ! ((ping -w5 -c3 "$1") > /dev/null 2>&1) ; then
        sleep 3;
        if ! ((ping -w5 -c3 "$1") > /dev/null 2>&1) ; then return 1; fi
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_online "$PingHost1" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_online ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_online ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# GET IP FROM URL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_ip_from_url";
    USAGE="$(localize "GET-IP-FROM-URL-USAGE")";
    DESCRIPTION="$(localize "GET-IP-FROM-URL-DESC")";
    NOTES="$(localize "GET-IP-FROM-URL-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-IP-FROM-URL-USAGE" "get_ip_from_url 1->(url)" "Comment: get_ip_from_url @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-IP-FROM-URL-DESC"  "Get IP Address from URL." "Comment: get_ip_from_url @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-IP-FROM-URL-NOTES" "Uses Host." "Comment: get_ip_from_url @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_ip_from_url()
{
    echo "$(host $1 | awk '/^[[:alnum:].-]+ has address/ { print $4 ; exit }')";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 2 ]]; then
    if [[ "$(get_ip_from_url "$Test_SSH_URL")" == "$Test_SSH_IP" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  get_ip_from_url ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  get_ip_from_url $Test_SSH_URL -> $Test_SSH_IP ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# RUN DB SQL FILE SSH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="run_db_sql_file_ssh";
    USAGE="$(localize "RUN-DB-SQL-FILE-SSH-USAGE")";
    DESCRIPTION="$(localize "RUN-DB-SQL-FILE-SSH-DESC")";
    NOTES="$(localize "RUN-DB-SQL-FILE-SSH-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Jun 2013";
    REVISION="17 Jun 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "RUN-DB-SQL-FILE-SSH-USAGE" "run_db_sql_file_ssh 1->(IP or URL Address) 2->(User Name) 3->(/Full-Path/File-Name.sql or SQL Statement) 4->(DB User Name) 5->(DB Password) 6->(0=SQL File,1=SQL Statement) 7->(Database Type: 0=None,1=SQlite,2=PostgreSql,3=MySql)" "Comment: run_db_sql_file_ssh @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RUN-DB-SQL-FILE-SSH-DESC"  "Run Dabase Command." "Comment: run_db_sql_file_ssh @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RUN-DB-SQL-FILE-SSH-NOTES" "None." "Comment: run_db_sql_file_ssh @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
run_db_sql_file_ssh()
{
    if [[ "$6" -eq 0 ]]; then     # SQL File
        scp "$3" "${2}@${1}:";    # Root Folder for User
        if [[ "$7" -eq 3 ]]; then # 0=None,1=SQlite,2=PostgreSql,3=MySql
            if [[ "$?" -eq 0 ]]; then
                ssh "${2}@${1}" "mysql -u$4 -p$5 < $3";
            fi
        fi
    else                          # SQL Statement
        if [[ "$7" -eq 3 ]]; then # 0=None,1=SQlite,2=PostgreSql,3=MySql
            ssh "${2}@${1}" "mysql -u$4 -p$5 -e \"$3\"";
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# -------------------------- Array Functions ----------------------------------
# -----------------------------------------------------------------------------
# ARRAY PUSH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="array_push";
    USAGE="$(localize "ARRAY-PUSH-USAGE")";
    DESCRIPTION="$(localize "ARRAY-PUSH-DESC")";
    NOTES="$(localize "ARRAY-PUSH-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ARRAY-PUSH-USAGE" "array_push 1->(array) 2->(Element)" "Comment: array_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ARRAY-PUSH-DESC"  "Push Element into an Array." "Comment: array_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ARRAY-PUSH-NOTES" "None." "Comment: array_push @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
array_push()
{
    eval "shift; $1+=(\"\$@\")";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArray=( "1" "2" );
    array_push "MyArray" "3";
    totalnArr="${#MyArray[@]}";
    if [[ "$totalnArr" -eq 3 ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  array_push ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  array_push ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE FROM ARRAY {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_from_array";
    USAGE="$(localize "REMOVE-FROM-ARRAY-USAGE")";
    DESCRIPTION="$(localize "REMOVE-FROM-ARRAY-DESC")";
    NOTES="$(localize "REMOVE-FROM-ARRAY-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-FROM-ARRAY-USAGE" "remove_from_array 1->(array) 2->(Element)" "Comment: remove_from_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FROM-ARRAY-DESC"  "Remove Element from an Array." "Comment: remove_from_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-FROM-ARRAY-NOTES" "Pass in Array by name 'array'." "Comment: remove_from_array @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "REMOVE-FROM-ARRAY-ERROR" "Wrong Parameters passed to remove_from_array" "Comment: remove_from_array @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_from_array()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> ${White} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    # Check to see if its in Array
    if is_in_array "$1[@]" "$2" ; then
        eval "local -a array=(\${$1[@]})";
        eval "$1=(${array[@]:0:$ARR_INDEX} ${array[@]:$(($ARR_INDEX + 1))})";
        return "$?";
    fi
    return 1;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArray=( "1" "2" "3" );
    if is_in_array "MyArray[@]" "2" ; then
        remove_from_array "MyArray" "2";
    fi
    if ! is_in_array "MyArray[@]" "2" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_from_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_from_array ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# GET INDEX {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_index";
    USAGE="$(localize "GET-INDEX-USAGE")";
    DESCRIPTION="$(localize "GET-INDEX-DESC")";
    NOTES="$(localize "GET-INDEX-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-INDEX-USAGE" "get_index 1->(array[@]) 2->(Search)" "Comment: get_index @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INDEX-DESC"  "Get Index into an Array." "Comment: get_index @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-INDEX-NOTES" "Bombs if not found; but finds errors in data; you could ask for data; but if its not in Array; this is a bug in Data not logic." "Comment: get_index @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_index()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> ${White} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    local -a i_array=("${!1}");
    local -i index=0;
    for index in "${!i_array[@]}"; do
        if [[ "${i_array[$index]}" == "$2" ]]; then
            echo -n "$[index]";
            return 0;
        fi
    done
    write_error "FAILED:only use this if you know the record exist in get_index [$1] [$2]; check  " "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    pause_function "FAILED:only use this if you know the record exist in get_index [$1] [$2] at line $LINENO";
    exit 1;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArray=( "1" "2" "3" );
    if [[ $(get_index "MyArray[@]" "2") -eq 1 ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  get_index ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  get_index ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
declare -a REMOVED_INDEXES=()
#
# REMOVE ARRAY DUPLICATES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_array_duplicates";
    USAGE="$(localize "REMOVE-ARRAY-DUPLICATES-USAGE")";
    DESCRIPTION="$(localize "REMOVE-ARRAY-DUPLICATES-DESC")";
    NOTES="$(localize "REMOVE-ARRAY-DUPLICATES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-ARRAY-DUPLICATES-USAGE" "MyArray=( \$( remove_array_duplicates '1->(Array[@])' ) )" "Comment: remove_array_duplicates @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-ARRAY-DUPLICATES-DESC"  "Removes Duplicates in Array." "Comment: remove_array_duplicates @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-ARRAY-DUPLICATES-NOTES" "set IFS=\$'\n\t'; before call" "Comment: remove_array_duplicates @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_array_duplicates()
{
    # Test Code
    # MY_ARR=("MY" "MY" "2" "2" "LIST" "LIST" "OK")
    # local -i total=${#MY_ARR[@]}
    # echo ${MY_ARR[@]} # Prints: MY MY 2 2 LIST LIST OK
    # MY_ARR=( $(remove_array_duplicates MY_ARR[@]) )
    # echo ${MY_ARR[@]} # Prints: MY 2 LIST OK    declare -a array=("${!1}")
    # for (( index=0; index<total; index++ )); do echo "ARRAY= ${MY_ARR[$index]}"; done # to echo with new line
    local -a array=("${!1}");
    local -i total="${#array[@]}";
    local -a sarray=( "" );
    local -i i=0;
    local -i j=0;
    local -i y=0;
    for (( i=0; i<total; i++ )); do
        (( j = i + 1 ));
        while (( j < total )); do
            if [ "${array[$i]}" == "${array[$j]}" ]; then
                break;
            fi
            (( j = j + 1 ));
        done
        if [[ "$j" == "$total" ]]; then
            sarray[$y]="${array[$i]}";
            (( y = y + 1 ));
        else
            REMOVED_INDEXES[$[${#REMOVED_INDEXES[@]}]]="$i";
        fi
    done
    # Must echo to fill array
    for element in "${sarray[*]}"; do
        echo -e "${element}";
    done
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
    MyArray=( "1" "2" "3" "4" "4" "5" "6-8" "6-8" );
    MyArray=( $( remove_array_duplicates "MyArray[@]") );
    IFS="$OLD_IFS";
    totalnArr="${#MyArray[@]}";
    if [[ "$totalnArr" -eq 6 ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_array_duplicates ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_array_duplicates ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# IS LAST ITEM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_last_item";
    USAGE="$(localize "IS-LAST-ITEM-USAGE")";
    DESCRIPTION="$(localize "IS-LAST-ITEM-DESC")";
    NOTES="$(localize "IS-LAST-ITEM-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-LAST-ITEM-USAGE" "is_last_item 1->(array[@]) 2->(search)" "Comment: is_last_item @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-LAST-ITEM-DESC"  "is last item in array." "Comment: is_last_item @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-LAST-ITEM-NOTES" "None." "Comment: is_last_item @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_last_item()
{
    local -a i_array=("${!1}");
    local -i total="${#i_array[@]}";
    local -i index=0;
    for (( index=0; index<total; index++ )); do
        if [[ "${i_array[$index]}" == "$2" ]]; then
            if [[ "$[index + 1]" -eq "${#i_array[@]}" ]]; then
                return 0; # True
            else
                return 1; # False
            fi
        fi
    done
    return 1;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyArray=( "1" "2" "3" "4" "5" "6" );
    if is_last_item "MyArray[@]" "6" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_last_item ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_last_item ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# DATE2STAMP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="date2stamp";
    USAGE="$(localize "DATE2STAMP-USAGE")";
    DESCRIPTION="$(localize "DATE2STAMP-DESC")";
    NOTES="$(localize "DATE2STAMP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DATE2STAMP-USAGE" "date2stamp 1->(date)" "Comment: date2stamp @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DATE2STAMP-DESC"  "Convert Date to Datetime stamp." "Comment: date2stamp @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DATE2STAMP-NOTES" "None." "Comment: date2stamp @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
date2stamp()
{
    date --utc --date "$1" +%s;
}
#}}}
# -----------------------------------------------------------------------------
# DETECTED VIDEO CARD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="detected_video_card";
    USAGE="detected_video_card";
    DESCRIPTION="$(localize "DETECTED-VIDEO-CARD-DESC")";
    NOTES="$(localize "DETECTED-VIDEO-CARD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="19 Jan 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DETECTED-VIDEO-CARD-DESC"  "Detect Video Card." "Comment: detected_video_card @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DETECTED-VIDEO-CARD-NOTES" "Need to add more support for Video Cards, currently it supports: nVidia, Intel, ATI and Vesa." "Comment: detected_video_card @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
detected_video_card()
{
    # @FIX Add more Video cards and Options
    #  1        2         3       4     5      6            7
    # "nVidia" "Nouveau" "Intel" "ATI" "Vesa" "Virtualbox" "Skip"
    if (lspci | grep -q 'VGA compatible controller: NVIDIA'); then
        VIDEO_CARD=1;
    elif (lspci | grep -q 'VGA compatible controller: NVIDIA'); then # This will never get set
        VIDEO_CARD=2;
    elif (lspci | grep -q 'VGA compatible controller: Intel'); then
        VIDEO_CARD=3;
    elif (lspci | grep -q 'VGA compatible controller: ATI'); then
        VIDEO_CARD=4;
    elif (lspci | grep -q 'VGA compatible controller: Vesa'); then # Don't know if this works
        VIDEO_CARD=5;
    elif (lspci | grep -q 'VGA compatible controller: Virtualbox'); then  # This doesn't work, just putting it out there for a better fix, since its just an option and not hardware
        VIDEO_CARD=6;
    else
        VIDEO_CARD=7;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# CLEAR LOGS {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="clear_logs";
    USAGE="clear_logs";
    DESCRIPTION="$(localize "CLEAR-LOGS-DESC")";
    NOTES="$(localize "CLEAR-LOGS-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CLEAR-LOGS-DESC"    "Clear all Log Entries." "Comment: clear_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAR-LOGS-NOTES"   "None." "Comment: clear_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAR-LOGS-CLEAR-1" "Clearing Log Files" "Comment: clear_logs @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CLEAR-LOGS-CLEAR-2" "Created Log Folders" "Comment: clear_logs @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
clear_logs()
{
    print_this "CLEAR-LOGS-CLEAR-1" "..."
    make_dir "$LOG_PATH"    "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    make_dir "$MENU_PATH"   "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    make_dir "$CONFIG_PATH" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    print_this "CLEAR-LOGS-CLEAR-2" "...";
    copy_file "${ERROR_LOG}"    "$FULL_SCRIPT_PATH/Archive/${LOG_DATE_TIME}.log" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    copy_file "${ACTIVITY_LOG}" "$FULL_SCRIPT_PATH/Archive/${LOG_DATE_TIME}.log" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    echo "# Error Log: $SCRIPT_NAME Version: $SCRIPT_VERSION on $DATE_TIME." > "$ERROR_LOG";
    echo "# Log: $SCRIPT_NAME Version: $SCRIPT_VERSION on $DATE_TIME."       > "$ACTIVITY_LOG";
}
#}}}
# -----------------------------------------------------------------------------
# IS USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_user";
    USAGE="$(localize "IS-USER-USAGE")";
    DESCRIPTION="$(localize "IS-USER-DESC")";
    NOTES="$(localize "IS-USER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-USER-USAGE"  "is_user 1->(USERNAME)" "Comment: is_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-USER-DESC"  "Checks if USERNAME exist." "Comment: is_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-USER-NOTES" "None." "Comment: is_user @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_user()
{
    egrep -i "^$1" /etc/passwd > /dev/null 2>&1;
    return "$?";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_user $(whoami) ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_user ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_user ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# ADD USER GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_user_group";
    USAGE="add_user_group 1->(Group Name)";
    DESCRIPTION="$(localize "ADD-USER-GROUP-DESC")";
    NOTES="$(localize "ADD-USER-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-USER-GROUP-DESC"  "Add User group." "Comment: add_user_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-USER-GROUP-NOTES" "None." "Comment: add_user_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_user_group()
{
    USER_GROUPS[${#USER_GROUPS[*]}]="$1";
    local OLD_IFS="$IFS"; IFS=$'\n\t';
    USER_GROUPS=( $( remove_array_duplicates "USER_GROUPS[@]") );
    IFS=$"$OLD_IFS";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    add_user_group "TestMyAccount";
    if is_in_array "USER_GROUPS[@]" "TestMyAccount" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_user_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_user_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE USER GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_user_group";
    USAGE="$(localize "REMOVE-USER-GROUP-USAGE")";
    DESCRIPTION="$(localize "REMOVE-USER-GROUP-DESC")";
    NOTES="$(localize "REMOVE-USER-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-USER-GROUP-USAGE" "remove_user_group 1->(Group Name)" "Comment: remove_user_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-USER-GROUP-DESC"  "Remove User group." "Comment: remove_user_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-USER-GROUP-NOTES" "None." "Comment: remove_user_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_user_group()
{
    if is_in_array "USER_GROUPS[@]" "$1" ; then
        remove_from_array "USER_GROUPS" "$1";
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    add_user_group "TestMyAccount2";
    remove_user_group "TestMyAccount2";
    if ! is_in_array "USER_GROUPS[@]" "TestMyAccount2" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_user_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  remove_user_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# IS USER IN GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_user_in_group";
    USAGE="is_user_in_group 1->(GroupName)";
    DESCRIPTION="$(localize "IS-USER-IN-GROUP-DESC")";
    NOTES="$(localize "IS-USER-IN-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-USER-IN-GROUP-DESC"  "is user in group." "Comment: is_user_in_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-USER-IN-GROUP-NOTES" "None." "Comment: is_user_in_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_user_in_group()
{
    groups "${USERNAME}" | grep "$1" > /dev/null 2>&1;
    return "$?";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_user_in_group $(whoami) ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_user_in_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_user_in_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# IS GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_group";
    USAGE="$(localize "IS-GROUP-USAGE")"
    DESCRIPTION="$(localize "IS-GROUP-DESC")";
    NOTES="$(localize "IS-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-GROUP-USAGE"  "is_group 1->(GROUPNAME)" "Comment: is_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-GROUP-DESC"  "Is Group." "Comment: is_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-GROUP-NOTES" "None." "Comment: is_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_group()
{
    egrep -i "^$1" /etc/group > /dev/null 2>&1;
    return "$?";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if is_group "users" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# ADD GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_group";
    USAGE="$(localize "ADD-GROUP-USAGE")";
    DESCRIPTION="$(localize "ADD-GROUP-DESC")";
    NOTES="$(localize "ADD-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-GROUP-USAGE" "add_group 1->(GroupName)" "Comment: add_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-GROUP-DESC"  "Add Group."               "Comment: add_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-GROUP-NOTES" "None."                    "Comment: add_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-GROUP-OK"    "Added Group"              "Comment: add_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-GROUP-FAIL"  "Failed to add Group"      "Comment: add_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_group()
{
    if ! is_group "$1" ; then
        if sudo groupadd "$1" ; then
            write_log "ADD-GROUP-OK" ": $1 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 0;
        else
            print_error "ADD-GROUP-FAIL" ": $1 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            write_error "ADD-GROUP-FAIL" ": $1 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 1;
        fi
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if add_group "testgroup" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    if is_group "testgroup" ; then
       if sudo groupdel "testgroup" ; then
            echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-REMOVE") add_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAIL-REMOVE") add_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
       fi
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# ADD USER 2 GROUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_user_2_group";
    USAGE="$(localize "ADD-USER-2-GROUP-USAGE")";
    DESCRIPTION="$(localize "ADD-USER-2-GROUP-DESC")";
    NOTES="$(localize "ADD-USER-2-GROUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-USER-2-GROUP-USAGE" "add_user_2_group 1->(GroupName)" "Comment: add_user_2_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-USER-2-GROUP-DESC"  "Add User to Group." "Comment: add_user_2_group @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-USER-2-GROUP-NOTES" "None." "Comment: add_user_2_group @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "ADD-USER-2-GROUP-ERROR" "Error in adding User to group" "Comment: add_user_2_group @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_user_2_group()
{
    if ! is_group "testgroup" ; then
        if add_group "testgroup" ; then
            write_log "add_user_2_group $1" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    fi
    if ! is_user_in_group "$1" ; then
        if sudo gpasswd -a "${USERNAME}" "$1" ; then
            write_log "add_user_2_group $1" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 0;
        else
            write_error "ADD-USER-2-GROUP-ERROR" ": gpasswd -a ${USERNAME} $1 -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 1;
        fi
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if add_user_2_group "testgroup" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_user_2_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_user_2_group ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    # remove them
    if is_user_in_group "testgroup" ; then
        sudo gpasswd -d "${USERNAME}" testgroup;
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# SET DEBUGGING MODE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="set_debugging_mode";
    USAGE="$(localize "SET-DEBUGGING-MODE-USAGE")";
    DESCRIPTION="$(localize "SET-DEBUGGING-MODE-DESC")";
    NOTES="$(localize "SET-DEBUGGING-MODE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SET-DEBUGGING-MODE-USAGE" "set_debugging_mode" "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-DESC"  "Set Debugging Mode: also checks for Internet Connection." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-NOTES" "Fill try to Repair Internet Connection. Only sets Debugging switch if DEBUGGING is set to 1." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "SET-DEBUGGING-MODE-TITLE"         "Starting setup..." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-INTERNET-UP"   "Internet is Up!"   "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-TRIED-TO-FIX"  "I tried to fix Network, I will test it again, if it fails, first try to re-run this script over, if that fails, try Network Troubleshooting." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-TRY-AGAIN"     "trying again in 13 seconds..." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-INTERNET-DOWN" "Internet is Down: Internet is Down, this script requires an Internet Connection, fix and retry; try Network Troubleshooting; first try to rerun this script, I did try to fix this. Select Install with No Internet Connection option." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-NO-INTERNET"   "No Internet Install Set; if it fails; you must establish an Internet connection first; try Network Troubleshooting." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-WARN-1"        "Debug Mode will insert a Pause Function at critical functions and give you some information about how the script is running, it also may set other variables and run more test." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SET-DEBUGGING-MODE-WARN-2"        "Debugging is set on, if set -o nounset or set -u, you may get unbound errors that need to be fixed." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "BOOT-MODE-DETECTED"               "Boot Mode Detected." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LIVE-MODE-DETECTED"               "Live Mode Detected." "Comment: set_debugging_mode @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
set_debugging_mode()
{
    if [[ "$SET_DEBUGGING" -eq 0 ]]; then
        SET_DEBUGGING=1; # So we only run this once.
    else
        return 0; # True
    fi
    IsOK=0;  # True
    print_title "SET-DEBUGGING-MODE-TITLE";
    print_info "$TEXT_SCRIPT_ID";
    if is_internet ; then
        print_info "SET-DEBUGGING-MODE-INTERNET-UP";
    else
        fix_network;
        print_error "SET-DEBUGGING-MODE-TRIED-TO-FIX";
        print_this "SET-DEBUGGING-MODE-TRY-AGAIN";
        sleep 13;
        if ! is_internet ; then
            write_error "SET-DEBUGGING-MODE-INTERNET-DOWN" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_error "SET-DEBUGGING-MODE-INTERNET-DOWN" ;
            if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                INSTALL_NO_INTERNET=1;
                print_error "SET-DEBUGGING-MODE-NO-INTERNET";
            fi
            pause_function "set_debugging_mode : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            IsOK=0;
        fi
    fi
    if [[ "$DEBUGGING" -eq 1 ]]; then
        #set -u
        set -o nounset;
        print_error "SET-DEBUGGING-MODE-WARN-1";
        print_error "SET-DEBUGGING-MODE-WARN-2";
        pause_function "set_debugging_mode : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    return "$IsOK";
}
#}}}
# -----------------------------------------------------------------------------
# TEST INTERNET {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="test_internet";
    USAGE="$(localize "TEST-INTERNET-USAGE")";
    DESCRIPTION="$(localize "TEST-INTERNET-DESC")";
    NOTES="$(localize "TEST-INTERNET-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "TEST-INTERNET-USAGE" "test_internet" "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-DESC"  "Set Debugging Mode: also checks for Internet Connection." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-NOTES" "Fill try to Repair Internet Connection. Only sets Debugging switch if DEBUGGING is set to 1." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "TEST-INTERNET-TITLE"         "Starting setup..." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-INTERNET-UP"   "Internet is Up!"   "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-TRIED-TO-FIX"  "I tried to fix Network, I will test it again, if it fails, first try to re-run this script over, if that fails, try Network Troubleshooting." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-TRY-AGAIN"     "trying again in 13 seconds..." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-INTERNET-DOWN" "Internet is Down: Internet is Down, this script requires an Internet Connection, fix and retry; try Network Troubleshooting; first try to rerun this script, I did try to fix this. Select Install with No Internet Connection option." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-NO-INTERNET"   "No Internet Install Set; if it fails; you must establish an Internet connection first; try Network Troubleshooting." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-WARN-1"        "Debug Mode will insert a Pause Function at critical functions and give you some information about how the script is running, it also may set other variables and run more test." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-INTERNET-WARN-2"        "Debugging is set on, if set -o nounset or set -u, you may get unbound errors that need to be fixed." "Comment: test_internet @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
test_internet()
{
    if [[ "$SET_DEBUGGING" -eq 0 ]]; then
        SET_DEBUGGING=1; # So we only run this once.
    else
        return 0; # True
    fi
    IsOK=0;  # True
    print_title "TEST-INTERNET-TITLE";
    print_info "$TEXT_SCRIPT_ID";
    if is_internet ; then
        print_info "TEST-INTERNET-INTERNET-UP";
    else
        fix_network;
        print_error "TEST-INTERNET-TRIED-TO-FIX";
        print_this "TEST-INTERNET-TRY-AGAIN";
        sleep 13;
        if ! is_internet ; then
            write_error "TEST-INTERNET-INTERNET-DOWN" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_error "TEST-INTERNET-INTERNET-DOWN" ;
            if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                INSTALL_NO_INTERNET=1;
                print_error "TEST-INTERNET-NO-INTERNET";
            fi
            pause_function "set_debugging_mode : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            IsOK=0;
        fi
    fi
    if [[ "$DEBUGGING" -eq 1 ]]; then
        #set -u
        set -o nounset;
        print_error "TEST-INTERNET-WARN-1";
        print_error "TEST-INTERNET-WARN-2";
        pause_function "set_debugging_mode : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    return "$IsOK";
}
#}}}
# -----------------------------------------------------------------------------
# GET COUNTRY CODES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="country_list";
    USAGE="country_list";
    DESCRIPTION="$(localize "GET-COUNTRY-CODES-DESC")";
    NOTES="$(localize "GET-COUNTRY-CODES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-COUNTRY-CODES-DESC"  "country list." "Comment: country_list @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-NOTES" "Sets COUNTRY." "Comment: country_list @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-COUNTRY-CODES-SELECT" "Select your Country:" "Comment: country_list @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
country_list()
{
    #`reflector --list-countries | sed 's/[0-9]//g' | sed 's/^/"/g' | sed 's/,.*//g' | sed 's/ *$//g'  | sed 's/$/"/g' | sed -e :a -e '$!N; s/\n/ /; ta'`
    PS3="$prompt1";
    print_info "GET-COUNTRY-CODES-SELECT";
    select COUNTRY in "${COUNTRIES[@]}"; do
        if contains_element "$COUNTRY" "${COUNTRIES[@]}"; then
          break;
        else
          invalid_option "$REPLY";
        fi
    done
}
#}}}
# -----------------------------------------------------------------------------
# GET COUNTRY CODES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_country_codes";
    USAGE="get_country_codes";
    DESCRIPTION="$(localize "GET-COUNTRY-CODES-DESC")";
    NOTES="$(localize "GET-COUNTRY-CODES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-COUNTRY-CODES-DESC"    "Get Country Code and set Counter." "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-NOTES"   "None." "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-COUNTRY-CODES-WARN"    "You must enter your Country correctly, no validation is done!" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INPUT"   "Country Code for Mirror List: (US) " "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-TITLE"   "Country Code for Mirror List" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-COUNTRY-CODES-INFO-1"  "Australia     = AU | Belarus       = BY | Belgium       = BE" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-2"  "Brazil        = BR | Bulgaria      = BG | Canada        = CA" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-3"  "Chile         = CL | China         = CN | Colombia      = CO" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-4"  "Czech Repub   = CZ | Denmark       = DK | Estonia       = EE" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-5"  "Finland       = FI | France        = FR | Germany       = DE" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-6"  "Greece        = GR | Hungary       = HU | India         = IN" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-7"  "Ireland       = IE | Israel        = IL | Italy         = IT" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-8"  "Japan         = JP | Kazakhstan    = KZ | Korea         = KR" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-9"  "Macedonia     = MK | Netherlands   = NL | New Caledonia = NC" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-10" "New Zealand   = NZ | Norway        = NO | Poland        = PL" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-11" "Portugal      = PT | Romania       = RO | Russian Fed   = RU" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-12" "Serbia        = RS | Singapore     = SG | Slovakia      = SK" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-13" "South Africa  = ZA | Spain         = ES | Sri Lanka     = LK" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-14" "Sweden        = SE | Switzerland   = CH | Taiwan        = TW" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-15" "Ukraine       = UA | United King   = GB | United States = US" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODES-INFO-16" "Uzbekistan    = UZ | Viet Nam = VN" "Comment: get_country_codes @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_country_codes()
{
    # I pull the code from Locale, so it should always be right, so no need for a menu; default should work.
    print_title "GET-COUNTRY-CODES-TITLE" " - https://www.archlinux.org/mirrorlist/";
    print_this  "GET-COUNTRY-CODES-INFO-1";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-2";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-3";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-4";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-5";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-6";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-7";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-8";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-9";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-10";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-11";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-12";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-13";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-14";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-15";
    print_line;
    print_this  "GET-COUNTRY-CODES-INFO-16";
    print_line;
    print_error "GET-COUNTRY-CODES-WARN";
    #
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_default "GET-COUNTRY-CODES-INPUT" "${LOCALE#*_}";
    BYPASS="$Old_BYPASS"; # Restore Bypass
    COUNTRY_CODE="$(to_upper_case "$OPTION")"; # `echo "$OPTION" | tr '[:lower:]' '[:upper:]'`;  # Upper case only
    COUNTRY="${COUNTRIES[$(get_index "COUNTRY_CODES[@]" "$COUNTRY_CODE")]}";
}
#}}}
# -----------------------------------------------------------------------------
# GET COUNTRY CODE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_country_code";
    USAGE="get_country_code";
    DESCRIPTION="$(localize "GET-COUNTRY-CODE-DESC")";
    NOTES="$(localize "GET-COUNTRY-CODE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-COUNTRY-CODE-DESC"    "Get Country and Country Code." "Comment: get_country_code @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-COUNTRY-CODE-NOTES"   "Localized." "Comment: get_country_code @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-COUNTRY-CODE-CONFIRM" "Confirm Country Code" "Comment: get_country_code @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_country_code()
{
    YN_OPTION=0;
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    while [[ $YN_OPTION -ne 1 ]]; do
        get_country_codes;
        read_input_yn "GET-COUNTRY-CODE-CONFIRM" "$COUNTRY_CODE" 1; # Returns YN_OPTION
    done
    BYPASS="$Old_BYPASS"; # Restore Bypass
    OPTION="$COUNTRY_CODE";
}
#}}}
# -----------------------------------------------------------------------------
# GET ROOT PASSWORD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_root_password";
    USAGE="get_root_password";
    DESCRIPTION="$(localize "GET-ROOT-PASSWORD-DESC")";
    NOTES="$(localize "GET-ROOT-PASSWORD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-ROOT-PASSWORD-DESC"   "Get root password." "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-ROOT-PASSWORD-NOTES"  "This shows the password on screen; not very secure, but its used so you can see the password, you do not want a mistake putting in Passwords." "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-ROOT-PASSWORD-TITLE"  "root" "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-ROOT-PASSWORD-INFO-1" "No Special Characters, until I figure out how to do this." "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-ROOT-PASSWORD-INFO-2" "Enter Root Password." "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-ROOT-PASSWORD-VD"     "root Password" "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-ROOT-PASSWORD-INFO-3" "Root Password is Set." "Comment: get_root_password @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_root_password()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    print_title "GET-ROOT-PASSWORD-TITLE";
    print_info  "GET-ROOT-PASSWORD-INFO-1";
    print_info  "GET-ROOT-PASSWORD-INFO-2";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    verify_input_data "GET-ROOT-PASSWORD-VD" 1;
    Root_Password="$OPTION";
    BYPASS="$Old_BYPASS";
    print_title "GET-ROOT-PASSWORD-TITLE";
    print_info  "GET-ROOT-PASSWORD-INFO-3";
    # @FIX check for empty name
}
#}}}
# -----------------------------------------------------------------------------
# GET USER NAME {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_user_name";
    USAGE="$(localize "GET-USER-NAME-USAGE")";
    DESCRIPTION="$(localize "GET-USER-NAME-DESC")";
    NOTES="$(localize "GET-USER-NAME-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-USER-NAME-USAGE"  "get_user_name 1->(Optional Translated String for Title)"  "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-NAME-DESC"   "Get User Name."  "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-NAME-NOTES"  "Sets USERNAME." "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-USER-NAME-TITLE"  "User" "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-NAME-INFO-1" "No Special Characters, until I figure out how to do this." "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-NAME-INFO-2" "Enter User Name Alphanumeric only." "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-NAME-VD"     "User Name" "Comment: get_user_name @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_user_name()
{
    # @FIX Special Characters: How to embed ! $ into a variable, then to disk so a pipe can echo it; tried single tic '!' and escape \!, get error ! processes not found
    if [ -n "$1" ] ; then
        print_title "GET-USER-NAME-TITLE" "$1";
    else
        print_title "GET-USER-NAME-TITLE";
    fi
    print_info  "GET-USER-NAME-INFO-1";
    print_info  "GET-USER-NAME-INFO-2";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    verify_input_default_data "GET-USER-NAME-VD" "${USERNAME}" 1 1; # 1 = Alphanumeric
    USERNAME="$OPTION";
    BYPASS="$Old_BYPASS";
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# GET USER PASSWORD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_user_password";
    USAGE="get_user_password";
    DESCRIPTION="$(localize "GET-USER-PASSWORD-DESC")";
    NOTES="$(localize "GET-USER-PASSWORD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-USER-PASSWORD-DESC"   "get user password." "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-PASSWORD-NOTES"  "Password in clear text." "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-USER-PASSWORD-TITLE"  "User Password" "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-PASSWORD-INFO-1" "16 Character Maximum on most Database Engines, Some Special Characters (Problem Storing them in text file) (use | instead of *)." "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-PASSWORD-INFO-2" "Enter User Password for" "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-PASSWORD-VD"     "User Password" "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-USER-PASSWORD-INFO-3" "User Name and Password is Set." "Comment: get_user_password @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_user_password()
{
    print_title "GET-USER-PASSWORD-TITLE" ": ${USERNAME}";
    print_info  "GET-USER-PASSWORD-INFO-1";
    print_info  "GET-USER-PASSWORD-INFO-2" ": ${USERNAME}";
    Old_BYPASS="$BYPASS"; BYPASS=0;
    verify_input_default_data "GET-USER-PASSWORD-VD" "${USERPASSWD}" 1 8; # 8 = Password
    #verify_input_data "GET-USER-PASSWORD-VD" 1;
    USERPASSWD="$OPTION";
    BYPASS="$Old_BYPASS";
    print_title "GET-USER-PASSWORD-TITLE";
    print_info  "GET-USER-PASSWORD-INFO-3";
    # @FIX check for empty name
}
#}}}
# -----------------------------------------------------------------------------
# GET LOCALE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_locale";
    USAGE="get_locale";
    DESCRIPTION="$(localize "GET-LOCALE-DESC")";
    NOTES="$(localize "GET-LOCALE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-LOCALE-DESC"     "Get Locale." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-NOTES"    "Used to get a Locale." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-LOCALE-TITLE"    "LOCALE" "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-1"   "Locales are used in Linux to define which language the user uses." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-2"   "As the locales define the character sets being used as well, setting up the correct locale is especially important if the language contains non-ASCII characters." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-3"   "We can only initialize those Locales that are Available, if not in list, Install Language and rerun script." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-SELECT"   "Select your Language Locale:" "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-TITLE-2"  "LANGUAGE/LOCALE" "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-4"   "Locales are used in Linux to define which language the user uses." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-5"   "As the locales define the character sets being used as well, setting up the correct locale is especially important if the language contains non-ASCII characters." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-6"   "We can only initialize those Locales that are Available, if not in list, Install Language and rerun script." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-7"   "First list shows all Available Languages, if yours is not in list choose No, then a full list will appear." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-INFO-8"   "Pick your Primary Language first, then you have an option to select as many languages as you wish." "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-CONFIRM"  "Confirm Language Locale" "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-DEFAULT"  "Use Default System Language"  "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-ADD-MORE" "Add more Locales" "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-LOCALE-EDIT"     "Edit system language (ex: en_US): " "Comment: get_locale @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_locale()
{
    # -------------------------------------
    # GET LOCALES LIST {{{
    get_locales_list()
    {
        print_title "GET-LOCALE-TITLE" " - https://wiki.archlinux.org/index.php/Locale";
        print_info  "GET-LOCALE-INFO-1";
        print_info  "GET-LOCALE-INFO-2";
        print_info  "GET-LOCALE-INFO-3";
        # Another way to show all available, lots of work
        # @FIX create Localized po files for Localization
        # mkdir {af,sq,ar,eu,be,bs,bg,ca,hr,zh_CN,zh_TW,cs,da,en,et,fa,ph,fi,fr_FR,fr_CH,fr_BE,fr_CA,ga,gl,ka,de,el,gu,he,hi,hu,is,id,it,ja,kn,km,ko,lo,lt,lv,ml,ms,mi,mn,no,pl,pt_PT,pt_BR,ro,ru,mi,sr,sk,sl,so,es,sv,tl,ta,th,mi_NZ,tr,uk,vi}
        # @FIX do I need to localize Locale
        LOCALE_LANG=("Afrikaans" "Albanian" "Arabic" "Basque" "Belarusian" "Bosnian" "Bulgarian" "Catalan" "Croatian" "Chinese (Simplified)" "Chinese (Traditional)" "Czech" "Danish" "Dutch" "English" "Estonian" "Farsi" "Filipino" "Finnish" "French(FR)" "French (CH)" "French (BE)" "French (CA)" "Gaelic" "Gallego" "Georgian" "German" "Greek" "Gujarati" "Hebrew" "Hindi" "Hungarian" "Icelandic" "Indonesian" "Italian" "Japanese" "Kannada" "Khmer" "Korean" "Lao" "Lithuanian" "Latvian" "Malayalam" "Malaysian" "Maori" "Mongolian" "Norwegian" "Polish" "Portuguese" "Portuguese (Brazil)" "Romanian" "Russian" "Samoan" "Serbian" "Slovak" "Slovenian" "Somali" "Spanish" "Swedish" "Tagalog" "Tamil" "Thai" "Tongan" "Turkish" "Ukrainian" "Vietnamese");
        LOCALE_CODES=("af_ZA" "sq_AL" "ar_SA" "eu_ES" "be_BY" "bs_BA" "bg_BG" "ca_ES" "hr_HR" "zh_CN" "zh_TW" "cs_CZ" "da_DK" "nl_NL" "en_US" "et_EE" "fa_IR" "ph_PH" "fi_FI" "fr_FR" "fr_CH" "fr_BE" "fr_CA" "ga" "gl_ES" "ka_GE" "de_DE" "el_GR" "gu" "he_IL" "hi_IN" "hu" "is_IS" "id_ID" "it_IT" "ja_JP" "kn_IN" "km_KH" "ko_KR" "lo_LA" "lt_LT" "lv" "ml_IN" "ms_MY" "mi_NZ" "no_NO" "pl" "pt_PT." "pt_BR" "ro_RO" "ru_RU" "mi_NZ" "sr_CS" "sk_SK" "sl_SI" "so_SO" "es_ES" "sv_SE" "tl" "ta_IN" "th_TH" "mi_NZ" "tr_TR" "uk_UA" "vi_VN");
        LOCALE_LANG[$[${#LOCALE_LANG[@]}]]="Not-in-List"; # No Spaces
        PS3="$prompt1";
        echo "GET-LOCALE-SELECT";
        select LOCALE in "${LOCALE_LANG[@]}"; do
            if contains_element "$LOCALE" ${LOCALE_LANG[@]}; then
                is_last_item "LOCALE_LANG[@]" "$LOCALE";
                if [[ "$?" -ne 1 ]]; then
                    LOCALE="${LOCALE_CODES[$(get_index "LOCALE_LANG[@]" "$LOCALE")]}";
                    return 0; # True
                else
                    return 1; # False
                fi
                break;
            else
                invalid_option "$LOCALE";
            fi
        done
    }
    #}}}
    # -------------------------------------
    #LANGUAGE SELECTOR {{{
    language_selector()
    {
        #
        print_title "GET-LOCALE-TITLE-2" " - https://wiki.archlinux.org/index.php/Locale";
        print_info  "GET-LOCALE-INFO-4";
        print_info  "GET-LOCALE-INFO-5";
        print_info  "GET-LOCALE-INFO-6";
        print_info  "GET-LOCALE-INFO-7";
        print_info  "GET-LOCALE-INFO-8";
        #
        read_input_yn "GET-LOCALE-DEFAULT" "${LANGUAGE}" 1; # Returns YN_OPTION
        if [[ "$YN_OPTION" -eq 1 ]]; then
            LOCALE="$LANGUAGE";
            set_language "$LOCALE";
        else
            get_locales_list;
            read_input_default "GET-LOCALE-EDIT" "$LOCALE";
            set_language "$LOCALE";
        fi
    }
    #}}}
    #
    LOCALE_ARRAY=( "" );
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    #
    language_selector;
    #
    YN_OPTION=0;
    while [[ $YN_OPTION -ne 1 ]]; do
        if [ "${#LOCALE_ARRAY}" -eq 0 ]; then
            LOCALE_ARRAY=( "$LOCALE" );
        else
            LOCALE_ARRAY=( "${LOCALE_ARRAY[@]}" "$LOCALE" );
        fi
        read_input_yn "GET-LOCALE-ADD-MORE" " " 0; # Returns YN_OPTION
        if [[ "$YN_OPTION" -eq 1 ]]; then
            get_locales_list;
            read_input_default "GET-LOCALE-EDIT" "$LOCALE";
            read_input_yn "GET-LOCALE-CONFIRM" "$LOCALE" 1;
            if [[ "$YN_OPTION" -eq 0 ]]; then
               LOCALE="NONE";
            fi
            YN_OPTION=0;
        else
            YN_OPTION=1;
            break;
        fi
    done
    BYPASS="$Old_BYPASS"; # Restore Bypass
}
#}}}
# -----------------------------------------------------------------------------
# YES NO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="yes_no";
    USAGE="$(localize "YES-NO-USAGE")";
    DESCRIPTION="$(localize "YES-NO-DESC")";
    NOTES="$(localize "YES-NO-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "YES-NO-USAGE" "yes_no 1->(0=no, 1=yes)" "Comment: yes_no @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "YES-NO-DESC"  "Convert Digital to Analog." "Comment: yes_no @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "YES-NO-NOTES" "Localized. Used to Show simple settings." "Comment: yes_no @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "YES" "Yes" "Comment: yes_no @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NO"  "No"  "Comment: yes_no @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
yes_no()
{
    if [[ "$1" -eq 1 ]]; then
        localize "YES" "";
    else
        localize "NO" "";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# SELECT CREATE USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="select_create_user";
    USAGE="select_create_user";
    DESCRIPTION="$(localize "SELECT-CREATE-USER-DESC")";
    NOTES="$(localize "SELECT-CREATE-USER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SELECT-CREATE-USER-DESC"  "select user." "Comment: select_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-CREATE-USER-NOTES" "None." "Comment: select_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "SUDO-WARNING" "WARNING: THE SELECTED USER MUST HAVE SUDO PRIVILEGES" "Comment: select_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "Create-new-user" "Create new user" "Comment: select_create_user @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-CREATE-USER-AVAILABLE-USERS" "Available Users: " "Comment: select_create_user @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
select_create_user()
{
    print_title "SELECT/CREATE USER ACCOUNT - https://wiki.archlinux.org/index.php/Users_and_Groups";
    users=( $(cat /etc/passwd | grep "/home" | cut -d: -f1) );
    PS3="$prompt1";
    print_info "SELECT-CREATE-USER-AVAILABLE-USERS";
    if [[ "$(( ${#users[@]} ))" -gt 0 ]]; then
        print_error localize "SUDO-WARNING" "";
    else
        echo "";
    fi
    TEMP="$(localize "Create-new-user" "")";
    select OPT in "${users[@]}" "$TEMP"; do
        if [[ "$OPT" == "$TEMP" ]]; then
            create_new_user;
            break;
        elif contains_element "$OPT" "${users[@]}"; then
            USERNAME=$OPT;
            break;
        else
            invalid_option "$OPT";
        fi
    done
    [[ ! -f "/home/${USERNAME}/.bashrc" ]] && configure_user_account;
}
#}}}
# -----------------------------------------------------------------------------
# APACHE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="apache";
    USAGE="$(localize "START-INTERNET-USAGE")";
    DESCRIPTION="$(localize "START-INTERNET-DESC")";
    NOTES="$(localize "START-INTERNET-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "START-INTERNET-USAGE" "apache 1->(0=stop, 1=start, 2=restart)" "Comment: apache @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "START-INTERNET-DESC"  "Apache Control." "Comment: apache @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "START-INTERNET-NOTES" "OS Independent way of Controlling Apache." "Comment: apache @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
apache()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    declare MyCommand="";
    if [[ "$1" -eq 0 ]]; then
        MyCommand="stop";
    elif [[ "$1" -eq 1 ]]; then
        MyCommand="start";
    elif [[ "$1" -eq 2 ]]; then
        MyCommand="restart";
    fi
    if [[ "$My_OS" == "solaris" ]]; then
        service httpd "$MyCommand";
    elif [[ "$My_OS" == "aix" ]]; then
        service httpd "$MyCommand";
    elif [[ "$My_OS" == "freebsd" ]]; then
        service httpd "$MyCommand";
    elif [[ "$My_OS" == "windowsnt" ]]; then
        service httpd "$MyCommand";
    elif [[ "$My_OS" == "mac" ]]; then
        service httpd "$MyCommand";
    elif [[ "$My_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            service httpd "$MyCommand";
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            if check_package "apache" ; then
                httpd "$MyCommand";
            fi
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            apache2 stop;
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            service httpd "$MyCommand";
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            service httpd "$MyCommand";
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            service httpd "$MyCommand";
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# GET KEYBOARD LAYOUT {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_keyboard_layout";
    USAGE="get_keyboard_layout";
    DESCRIPTION="$(localize "GET-KEYBOARD-LAYOUT-DESC")";
    NOTES="$(localize "GET-KEYBOARD-LAYOUT-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-KEYBOARD-LAYOUT-DESC"   "Get Keyboard Layout, makes changes for some variants." "Comment: get_keyboard_layout @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-KEYBOARD-LAYOUT-NOTES"  "None." "Comment: get_keyboard_layout @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-KEYBOARD-LAYOUT-TITLE"  "Keymap." "Comment: get_keyboard_layout @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-KEYBOARD-LAYOUT-SELECT" "Select keyboard layout:" "Comment: get_keyboard_layout @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_keyboard_layout()
{
    if [[ "$LANGUAGE" == 'es_ES' ]]; then
        print_title "GET-KEYBOARD-LAYOUT-TITLE" "https://wiki.archlinux.org/index.php/KEYMAP";
        KBLAYOUT=("es" "latam");
        PS3="$prompt1";
        print_info "GET-KEYBOARD-LAYOUT-SELECT";
        select KBRD in "${KBLAYOUT[@]}"; do
            KEYBOARD="$KBRD";
        done
    fi
}
#}}}
# -----------------------------------------------------------------------------
# CONFIGURE KEYMAP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="configure_keymap";
    USAGE="configure_keymap";
    DESCRIPTION="$(localize "CONFIGURE-KEYMAP-DESC")";
    NOTES="$(localize "CONFIGURE-KEYMAP-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CONFIGURE-KEYMAP-DESC"    "Allows user to decide if they wish to change the Default Keymap." "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-NOTES"   "None." "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "Load-Keymap"              "Load Keymap" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "Confirm-Keymap"           "Confirm Keymap" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-TITLE"   "KEYMAP" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO"    "The KEYMAP variable is specified in the /etc/rc.conf file. It defines what keymap the keyboard is in the virtual consoles. Keytable files are provided by the kbd package." "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-DEFAULT" "If Default is ok, then no changes needed: " "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-LAYOUT"  "Keyboard Layout (ex: us-acentos): " "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CONFIGURE-KEYMAP-INFO-1"  "Belgian                = be-latin1    | Brazilian Portuguese = br-abnt2     | Canadian-French = cf" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-2"  "Canadian Multilingual  = ca_multi     | Colemak (US)         = colemak      | Croatian        = croat" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-3"  "Czech                  = cz-lat2      | Dvorak               = dvorak       | French          = fr-latin1" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-4"  "German                 = de-latin1 or de-latin1-nodeadkeys                  | Italian         = it" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-5"  "Lithuanian             = lt.baltic    | Norwegian            = no-latin1    | Polish          = pl" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-6"  "Portuguese             = pt-latin9    | Romanian             = ro_win       | Russian         = ru4" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-7"  "Singapore              = sg-latin1    | Slovene              = slovene      | Swedish         = sv-latin1" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-8"  "Swiss-French           = fr_CH-latin1 | Swiss-German         = de_CH-latin1 | Spanish         = es" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-9"  "Spanish Latinoamerican = la-latin1    | Turkish              = tr_q-latin5  | Ukrainian       = ua" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-KEYMAP-INFO-10" "United States          = us or us-acentos                                   | United Kingdom  = uk" "Comment: configure_keymap @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
configure_keymap()
{
    setkeymap()
    {
        local keymaps=( $(ls /usr/share/kbd/keymaps/i386/qwerty | sed 's/.map.gz//g') );
        PS3="(shift+pgup/pgdown) $prompt1";
        echo "Select keymap:";
        select KEYMAP in "${keymaps[@]}" "more"; do
            if contains_element "$KEYMAP" ${keymaps[@]}; then
                loadkeys $KEYMAP;
                break;
            elif [[ "$KEYMAP" == more ]]; then
                read -p "CONFIGURE-KEYMAP-LAYOUT" KEYMAP;
                loadkeys $KEYMAP;
                break;
            else
                invalid_option "$KEYMAP";
            fi
        done
    }
    print_title "CONFIGURE-KEYMAP-TITLE" " - https://wiki.archlinux.org/index.php/KEYMAP";
    print_this  "CONFIGURE-KEYMAP-INFO";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-1";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-2";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-3";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-4";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-5";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-6";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-7";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-8";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-9";
    print_line;
    print_this "CONFIGURE-KEYMAP-INFO-10";
    print_line;
    print_this  "CONFIGURE-KEYMAP-DEFAULT" " [$KEYMAP]";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_default "Keymap" "$KEYMAP";
    read_input_yn "Load-Keymap" "$KEYMAP" 0;
    if [[ "$YN_OPTION" -eq 1 ]]; then
        while [[ $YN_OPTION -ne 1 ]]; do
            setkeymap;
            read_input_yn "Confirm-Keymap" "$KEYMAP" 1;
        done
    else
        KEYMAP="us";
    fi
    BYPASS="$Old_BYPASS"; # Restore Bypass
}
#}}}
# -----------------------------------------------------------------------------
# GET EDITOR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_editor";
    USAGE="get_editor";
    DESCRIPTION="$(localize "GET-EDITOR-DESC")";
    NOTES="$(localize "GET-EDITOR-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-EDITOR-DESC"  "This gets called from Boot mode and Live mode; it does not add software, only ask if you wish to change the default editor, called from the create_config function." "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-EDITOR-NOTES" "None." "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-EDITOR-DEFAULT"   "Do you wish to change the Default Editor of " "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-EDITOR-TITLE"     "DEFAULT EDITOR" "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-EDITOR-INSTALLED" "Installed Editor(s): " "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-EDITOR-EDITORS"   "Editors" "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-EDITOR-SELECT"    "Select default editor:" "Comment: get_editor @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_editor()
{
    print_title "GET-EDITOR-TITLE";
    if [[ -f /usr/bin/vim ]]; then
        print_info "GET-EDITOR-INSTALLED" "emacs";
    else
        print_info "GET-EDITOR-INSTALLED" "emacs & vim";
    fi
    print_this "GET-EDITOR-EDITORS" ": ${EDITORS[*]}";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "GET-EDITOR-DEFAULT" "$EDITOR" 0;
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        PS3="$prompt1";
        print_this "GET-EDITOR-SELECT";
        select OPT in "${EDITORS[@]}"; do
            case "$REPLY" in
                1)
                    EDITOR="nano";
                    break;
                    ;;
                2)
                    EDITOR="emacs";
                    break;
                    ;;
                3)
                    EDITOR="vi";
                    break;
                    ;;
                4)
                    EDITOR="vim";
                    break;
                    ;;
                5)
                    EDITOR="joe";
                    break;
                    ;;
                *)
                    invalid_option "$OPT";
                    ;;
            esac
        done
    fi
}
#}}}
# -----------------------------------------------------------------------------
# SELECT EDITOR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="select_editor";
    USAGE="select_editor";
    DESCRIPTION="$(localize "SELECT-EDITOR-DESC")";
    NOTES="$(localize "SELECT-EDITOR-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SELECT-EDITOR-DESC"  "select_editor: Select Editor." "Comment: select_editor @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-EDITOR-NOTES" "None." "Comment: select_editor @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
select_editor()
{
    get_editor;
    if [[ "$EDITOR" == "nano" ]]; then
        add_packagemanager "package_install 'nano' 'INSTALL-NANO'" "INSTALL-NANO";
        package_install "nano" "INSTALL-NANO";
    elif [[ "$EDITOR" == "emacs" ]]; then
        add_packagemanager "package_install 'emacs' 'INSTALL-EMACS'" "INSTALL-EMACS";
        package_install "emacs" "INSTALL-EMACS";
    elif [[ "$EDITOR" == "vim" ]]; then
        if [[ ! -f /usr/bin/vim ]]; then
            add_packagemanager "package_install 'vim' 'INSTALL-VIM'" "INSTALL-VIM";
            package_install "vim" "INSTALL-VIM";
        fi
    elif [[ "$EDITOR" == "joe" ]]; then
        add_packagemanager "aur_package_install 'joe' 'AUR-INSTALL-JOE'" "AUR-INSTALL-JOE";
        aur_package_install "joe" "AUR-INSTALL-JOE";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# CONFIGURE TIMEZONE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="configure_timezone";
    USAGE="configure_timezone";
    DESCRIPTION="$(localize "CONFIGURE-TIMEZONE-DESC")";
    NOTES="$(localize "CONFIGURE-TIMEZONE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CONFIGURE-TIMEZONE-DESC"     "Configure Timezone." "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-NOTES"    "None." "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CONFIGURE-TIMEZONE-DEFAULT"  "Is the Default Timezone Correct" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-CONFIRM"  "Confirm Timezone " "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-TITLE"    "TIMEZONE" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-INFO-1"   "In an operating system the time (clock) is determined by four parts: Time value, Time standard, Time Zone, and DST (Daylight Saving Time if applicable)." "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE"     "Select zone:" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-SUBZONE"  "Select subzone:" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CONFIGURE-TIMEZONE-ZONE-1"   "Africa" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-2"   "America" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-3"   "Antarctica" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-4"   "Arctic" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-5"   "Asia" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-6"   "Atlantic" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-7"   "Australia" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-8"   "Brazil" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-9"   "Canada" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-10"  "Chile" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-11"  "Europe" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-12"  "Indian" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-13"  "Mexico" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-14"  "Midest" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-15"  "Pacific" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-TIMEZONE-ZONE-16"  "US" "Comment: configure_timezone @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
configure_timezone()
{
    settimezone()
    {
        # @FIX Localize?
        local zone=("$(localize "CONFIGURE-TIMEZONE-ZONE-1")" "$(localize "CONFIGURE-TIMEZONE-ZONE-2")" "$(localize "CONFIGURE-TIMEZONE-ZONE-3")" "$(localize "CONFIGURE-TIMEZONE-ZONE-4")" "$(localize "CONFIGURE-TIMEZONE-ZONE-5")" "$(localize "CONFIGURE-TIMEZONE-ZONE-6")" "$(localize "CONFIGURE-TIMEZONE-ZONE-7")" "$(localize "CONFIGURE-TIMEZONE-ZONE-8")" "$(localize "CONFIGURE-TIMEZONE-ZONE-9")" "$(localize "CONFIGURE-TIMEZONE-ZONE-10")" "$(localize "CONFIGURE-TIMEZONE-ZONE-11")" "$(localize "CONFIGURE-TIMEZONE-ZONE-12")" "$(localize "CONFIGURE-TIMEZONE-ZONE-13")" "$(localize "CONFIGURE-TIMEZONE-ZONE-14")" "$(localize "CONFIGURE-TIMEZONE-ZONE-15")" "$(localize "CONFIGURE-TIMEZONE-ZONE-16")");
        PS3="$prompt1";
        echo "CONFIGURE-TIMEZONE-ZONE";
        select ZONE in "${zone[@]}"; do
            if contains_element "$ZONE" ${zone[@]}; then
                local subzone=( $(ls /usr/share/zoneinfo/$ZONE/) );
                PS3="$prompt1";
                echo "CONFIGURE-TIMEZONE-SUBZONE";
                select SUBZONE in "${subzone[@]}"; do
                    if contains_element "$SUBZONE" ${subzone[@]}; then
                        add_packagemanager "remove_file \"/etc/localtime\" \"$LINENO\"; ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime" "RUN-TIMEZONE";
                        break;
                    else
                        invalid_option "$SUBZONE";
                    fi
                done
                break;
            else
                invalid_option "$ZONE"
            fi
        done
    }
    print_title "CONFIGURE-TIMEZONE-TITLE" " - https://wiki.archlinux.org/index.php/Timezone";
    print_info  "CONFIGURE-TIMEZONE-INFO-1";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "CONFIGURE-TIMEZONE-DEFAULT" "$ZONE/$SUBZONE" 1;
    while [[ $YN_OPTION -ne 1 ]]; do
        settimezone;
        read_input_yn "CONFIGURE-TIMEZONE-CONFIRM" "($ZONE/$SUBZONE)" 1;
    done
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$RUNTIME_MODE" -eq 2 ]]; then # Live Mode
        if [[ "$DRIVE_FORMATED" -eq 1 ]]; then
            touch ${MOUNTPOINT}/etc/timezone;
            echo "${ZONE}/${SUBZONE}" > ${MOUNTPOINT}/etc/timezone;
            copy_file ${MOUNTPOINT}/etc/timezone "${FULL_SCRIPT_PATH}/etc/timezone" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        else
            echo "${ZONE}/${SUBZONE}" > "${FULL_SCRIPT_PATH}/etc/timezone";
        fi
    else # Boot Mode
        echo "${ZONE}/${SUBZONE}" > "${FULL_SCRIPT_PATH}/etc/timezone";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# CHOOSE AUR HELPER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="choose_aurhelper";
    USAGE="choose_aurhelper";
    DESCRIPTION="$(localize "CHOOSE-AUR-HELPER-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CHOOSE-AUR-HELPER-DESC"   "Choose AUR Helper" "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CHOOSE-AUR-HELPER-TITLE"   "AUR HELPER" "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-1"  "AUR Helpers are written to make using the Arch User Repository more comfortable." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-2"  "YAOURT" "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-3"  "Yaourt (Yet AnOther User Repository Tool) is a community-contributed wrapper for pacman which adds seamless access to the AUR, allowing and automating package compilation and installation from your choice of the thousands of PKGBUILDs in the AUR, in addition to the many thousands of available Arch Linux binary packages." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-4"  "Yaourt is Recommended." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-5"  "List of AUR Helpers: yaourt, packer and pacaur." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-INFO-6"  "None of these tools are officially supported by Arch devs." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-SELECT"  "Choose your default AUR helper to install and use, you can only use one." "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHOOSE-AUR-HELPER-CHANGE"  "Do you wish to change the Default AUR Helper"  "Comment: choose_aurhelper @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
choose_aurhelper()
{
    print_title "CHOOSE-AUR-HELPER-TITLE" " - https://wiki.archlinux.org/index.php/AUR_Helpers";
    print_info  "CHOOSE-AUR-HELPER-INFO-1";
    print_info  "CHOOSE-AUR-HELPER-INFO-2" " - https://wiki.archlinux.org/index.php/Yaourt";
    print_info  "CHOOSE-AUR-HELPER-INFO-3";
    print_info  "CHOOSE-AUR-HELPER-INFO-4";
    print_info  "CHOOSE-AUR-HELPER-INFO-5";
    print_error "CHOOSE-AUR-HELPER-INFO-6";
    Old_BYPASS="$BYPASS"; BYPASS=0; # Do Not Allow Bypass
    read_input_yn "CHOOSE-AUR-HELPER-CHANGE" "$AUR_HELPER" 0;
    BYPASS="$Old_BYPASS"; # Restore Bypass
    if [[ "$YN_OPTION" -eq 1 ]]; then
        PS3="$prompt1";
        print_info "CHOOSE-AUR-HELPER-SELECT";
        select OPT in "${AUR_HELPERS[@]}"; do
            case "$REPLY" in
                1)
                    AUR_HELPER="yaourt";
                    break;
                    ;;
                2)
                    AUR_HELPER="packer";
                    break;
                    ;;
                3)
                    AUR_HELPER="pacaur";
                    break;
                    ;;
                *)
                    invalid_option "$REPLY";
                    ;;
            esac
        done
    fi
}
#}}}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# PACKAGE TYPE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="package_remove";
    USAGE="$(localize "PACKAGE-TYPE-USAGE")";
    DESCRIPTION="$(localize "PACKAGE-TYPE-DESC")";
    NOTES="$(localize "PACKAGE-TYPE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PACKAGE-TYPE-USAGE" "package_type 1->(0=install,1=install-group,2=remove,3=apache-start,4=apache-stop,5=apache-restart,6=haproxy,7=monit,8=FTP,9=system-upgrade,10=refresh-repo,11=mysql) 2->(Package) 3->(OS) 4->(Special)" "Comment: package_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-TYPE-DESC"  "Package type" "Comment: package_type @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-TYPE-NOTES" "Value returned in: echo." "Comment: package_type @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
package_type()
{
    local This_OS="$(string_split "$3" ":" 1)";
    local This_Distro="$(string_split "$3" ":" 2)";
    local This_PSUEDONAME="$(string_split "$3" ":" 3)";
    local This_Distro_Version="$(string_split "$3" ":" 4)";
    #
    if [[ "$This_OS" == "solaris" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$This_OS" == "aix" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$This_OS" == "freebsd" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$This_OS" == "windowsnt" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$This_OS" == "mac" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$This_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$This_Distro" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            if [[ "$1" -eq 0 ]]; then # Install
                if [[ "$4" -eq 0 ]]; then # Install
                    echo "sudo yum install $2 -y";
                else
                    echo "sudo yum groupinstall install $2 -y";
                fi
                return 0;
            elif [[ "$1" -eq 1 ]]; then # Install Group
                echo "sudo yum groupinstall $2 -y";
                return 0;
            elif [[ "$1" -eq 2 ]]; then # Remove
                echo "sudo yum remove $2"; # do not do an automatic remove -y
                return 0;
            elif [[ "$1" -eq 3 ]]; then # apache-start
                echo "sudo service httpd start";
                return 0;
            elif [[ "$1" -eq 4 ]]; then # apache-stop
                echo "sudo service httpd stop";
                return 0;
            elif [[ "$1" -eq 5 ]]; then # apache-restart
                echo "sudo service httpd restart";
                return 0;
            elif [[ "$1" -eq 6 ]]; then # haproxy
                echo "sudo service haproxy start; chkconfig haproxy on";
                return 0;
            elif [[ "$1" -eq 7 ]]; then # monit
                echo "sudo service monit start; chkconfig --levels 235 monit on";
                return 0;
            elif [[ "$1" -eq 8 ]]; then # FTP
                echo "sudo service $FTP_Install start; chkconfig $FTP_Install on";
                return 0;
            elif [[ "$1" -eq 9 ]]; then # system-upgrade
                echo "sudo yum-complete-transaction && package-cleanup --dupes && package-cleanup --dupes && package-cleanup --problems && yum update -y && yum upgrade -y";
                return 0;
            elif [[ "$1" -eq 10 ]]; then # refresh-repo
                echo "sudo yum update -y";
                return 0;
            elif [[ "$1" -eq 11 ]]; then # mysql
                echo "sudo service mysqld start; chkconfig --levels 235 mysqld on";
                return 0;
            fi
        elif [[ "$This_Distro" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            if [[ "$1" -eq 0 ]]; then # Install
                if [[ "$4" -eq 0 ]]; then # Install
                    echo "sudo pacman --noconfirm -S $2";
                else
                    echo "yaourt --noconfirm -S $2";
                fi
                return 0;
            elif [[ "$1" -eq 1 ]]; then # Install Group
                echo "sudo pacman -S $2 --noconfirm";   # We wish to remove some apps that will be replace with ones that replace it, so do not remove dependencies.
                return 0;
            elif [[ "$1" -eq 2 ]]; then # Remove
                echo "sudo pacman -Rddn $2";   # We wish to remove some apps that will be replace with ones that replace it, so do not remove dependencies. do not do automatic remove  --noconfirm
                return 0;
            elif [[ "$1" -eq 3 ]]; then # apache-start
                echo "sudo systemctl start httpd";
                return 0;
            elif [[ "$1" -eq 4 ]]; then # apache-stop
                echo "sudo systemctl stop httpd";
                return 0;
            elif [[ "$1" -eq 5 ]]; then # apache-restart
                echo "sudo systemctl restart httpd";
                return 0;
            elif [[ "$1" -eq 6 ]]; then # haproxy
                echo "sudo systemctl haproxy start; sudo systemctl enable haproxy";
                return 0;
            elif [[ "$1" -eq 7 ]]; then # monit
                echo "sudo systemctl monit start; sudo systemctl enable monit";
                return 0;
            elif [[ "$1" -eq 8 ]]; then # FTP
                echo "sudo systemctl $FTP_Install start; sudo systemctl enable $FTP_Install";
                return 0;
            elif [[ "$1" -eq 9 ]]; then # system-upgrade
                echo "sudo pacman -Syyu --noconfirm;";
                return 0;
            elif [[ "$1" -eq 10 ]]; then # refresh-repo
                echo "sudo pacman -Syy --noconfirm";
                return 0;
            elif [[ "$1" -eq 11 ]]; then # mysql
                echo "sudo systemctl mysqld start; sudo systemctl enable mysqld";
                return 0;
            fi
        elif [[ "$This_Distro" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            if [[ "$1" -eq 0 ]]; then # Install
                if [[ "$4" -eq 0 ]]; then # Install
                    echo "sudo apt-get install $2 -y";
                else
                    echo "sudo apt-get install $2 -y";
                fi
                return 0;
            elif [[ "$1" -eq 1 ]]; then # Install Group
                echo "sudo apt-get install $2 -y";
                return 0;
            elif [[ "$1" -eq 2 ]]; then # Remove
                echo "sudo apt-get remove $2"; # do not do automatic remove  -y
                return 0;
            elif [[ "$1" -eq 3 ]]; then # apache-start
                echo "sudo apache2 start";
                return 0;
            elif [[ "$1" -eq 4 ]]; then # apache-stop
                echo "sudo apache2 stop";
                return 0;
            elif [[ "$1" -eq 5 ]]; then # apache-restart
                echo "sudo apache2 restart";
                return 0;
            elif [[ "$1" -eq 6 ]]; then # haproxy
                echo "sudo service haproxy start; chkconfig haproxy on";
                return 0;
            elif [[ "$1" -eq 7 ]]; then # monit
                echo "sudo service monit start; chkconfig --levels 235 monit on";
                return 0;
            elif [[ "$1" -eq 8 ]]; then # FTP
                echo "sudo service $FTP_Install start; chkconfig $FTP_Install on";
                return 0;
            elif [[ "$1" -eq 9 ]]; then # system-upgrade
                #echo "apt-get update; apt-get upgrade";
                echo "sudo apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && aptitude update -y && aptitude full-upgrade -y && aptitude build-dep && dpkg --configure -a && aptitude build-dep && aptitude install -f";
                return 0;
            elif [[ "$1" -eq 10 ]]; then # refresh-repo
                echo "sudo apt-get update";
                return 0;
            elif [[ "$1" -eq 11 ]]; then # mysql
                echo "sudo service mysqld start; chkconfig --levels 235 mysqld on";
                return 0;
          fi
        elif [[ "$This_Distro" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            return 0;
        elif [[ "$This_Distro" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            return 0;
        elif [[ "$This_Distro" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            return 0;
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# DB BACKUP {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="mysql_backup";
    USAGE="MYSQL-BACKUP-USAGE";
    DESCRIPTION="$(localize "DB-BACKUP-DESC")";
    NOTES="$(localize "DB-BACKUP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DB-BACKUP-USAGE"   "mysql_backup 1->(Database type: 0=None,1=SQlite,2=PostgreSql,3=MySql) 2->(User Name) 3->(IP Address) 4->(DB Name) 5->(Db User Name) 6->(Password) 7->(Base Destination Path) 8->(DB Full Path)" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DB-BACKUP-DESC"    "Backup Database" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DB-BACKUP-NOTES"   "" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DB-BACKUP-TITLE"   "Start MySQL Backup..." "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DB-BACKUP-WORKING" "Working on" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DB-BACKUP-ERROR"   "Dump Failed" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DB-BACKUP-PING"    "Ping Failed" "Comment: mysql_backup @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
db_backup()
{
    print_this "DB-BACKUP-TITLE"
    #
    if is_online "$3" ; then
        print_info "DB-BACKUP-WORKING" "$3..."
        mkdir -p "${1}/${DB_Full_Paths[$i]}/"
        if [[ "$1" -eq 0 ]]; then   # None
            continue;
        elif [[ "$1" -eq 1 ]]; then # Sqlite
            print_warning "Not supported yet"
        elif [[ "$1" -eq 2 ]]; then # PostgreSql
            print_warning "Not supported yet"
        elif [[ "$1" -eq 3 ]]; then # My_SQL
            ssh "$2@$3" "mysqldump --user=$5 --password=$6 $5 |gzip -cq9" > "$7/$8/${5}.sql.gz";
        fi
        if [[ "$?" -ne 0 ]]; then
            print_warning "DB-BACKUP-ERROR" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
            write_error   "DB-BACKUP-ERROR" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
            #read -e -sn 1 -p "PRESS-ANY-KEY-CONTINUE"
        fi
    else
        print_warning "DB-BACKUP-PING" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
        write_error   "DB-BACKUP-PING" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
    fi
}
# -----------------------------------------------------------------------------
# CREATE DATABASE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="create_database";
    USAGE="MYSQL-BACKUP-USAGE";
    DESCRIPTION="$(localize "CREATE-DATABASE-DESC")";
    NOTES="$(localize "CREATE-DATABASE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CREATE-DATABASE-USAGE"   "create_database 1->(Database type: 0=None,1=SQlite,2=PostgreSql,3=MySql) 2->(User Name) 3->(IP Address) 4->(DB Name) 5->(Db User Name) 6->(DB Password) 7->(DB root Password)" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-DESC"    "Backup Database" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-NOTES"   "" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CREATE-DATABASE-TITLE"   "Start MySQL Backup..." "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-WORKING" "Working on" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-ERROR"   "Dump Failed" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-PING"    "Ping Failed" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-DATABASE-NI"      "Not Implemented" "Comment: create_database @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
create_database()
{
    if [[ "$#" -ne 7 ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} $(gettext -s "CREATE-DATABASE-USAGE")${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> ${White}$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; exit $E_BADARGS; fi
    if [[ "$1" -eq 0 ]]; then return 0; fi # None
    if is_online "$3" ; then
        if [[ "$1" -eq 1 ]]; then   # SQlite
            print_this "CREATE-DATABASE-NI";
            return 0;
        elif [[ "$1" -eq 2 ]]; then # PostgreSql
            print_this "CREATE-DATABASE-NI";
            return 0;
        elif [[ "$1" -eq 3 ]]; then # MySql: which mysql
            # /usr/bin/mysql_secure_installation
            # /usr/bin/mysqladmin -u root password 'new-password'
            # /usr/bin/mysqladmin -u root -h vps-1135159-16955.manage.myhosting.com password 'new-password'
            # "UPDATE user SET password=PASSWORD("<YOUR_PASSWORD>") WHERE User="root";"

            # mysql --host=localhost --user=user --password=password << END
            # CREATE USER ${TICK}${5}${TICK}@${TICK}localhost${TICK} IDENTIFIED BY ${TICK}${6}${TICK};
            # CREATE DATABASE IF NOT EXISTS ${TICK}${4}${TICK} DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
            # GRANT ALL PRIVILEGES ON ${TICK}${4}${TICK} . * TO ${TICK}${5}${TICK}@${TICK}localhost${TICK};
            # END

            # @FIX I don't think we want to do this on Shared Host
            #ssh "root@${3}" "mysqladmin -u root password ${TICK}$7${TICK}";
            #if [[ "$?" -eq 1 ]]; then  echo "Failed to set password"; fi

            # ${BTICK} or ${TICK}
            # "CREATE USER '$username'@'localhost' IDENTIFIED BY  '$password';"
            # "CREATE DATABASE \`$domainname\`;"
            # "GRANT ALL PRIVILEGES ON  \`$domainname\`.* TO $username@localhost WITH GRANT OPTION;"
            local SQL="CREATE USER ${TICK}${5}${TICK}@${TICK}localhost${TICK} IDENTIFIED BY ${TICK}${6}${TICK};CREATE DATABASE IF NOT EXISTS ${TICK}${4}${TICK} DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;GRANT ALL PRIVILEGES ON ${TICK}${4}${TICK}.* TO ${TICK}${5}${TICK}@${TICK}localhost${TICK} IDENTIFIED BY ${TICK}${6}${TICK};FLUSH PRIVILEGES;";
            #echo "mysql -uroot -p$7 -e \"$SQL\"";
            #ssh "$2@$3" "mysql -uroot -p$7 -e \"$SQL\"";
            # 1->(IP or URL Address) 2->(User Name) 3->(/Full-Path/File-Name.sql or SQL Statement) 4->(DB User Name) 5->(DB Password) 6->(0=SQL File,1=SQL Statement) 7->(Database Type: 0=None,1=SQlite,2=PostgreSql,3=MySql
            run_db_sql_file_ssh "$3" "$2" "$SQL" "root" "$7" "1" "$1";
            print_line;
            SQL="show databases;";
            print_line;
            run_db_sql_file_ssh "$3" "$2" "$SQL" "root" "$7" "1" "$1";
        fi
        if [[ "$?" -ne 0 ]]; then
            print_warning "CREATE-DATABASE-ERROR" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
            write_error   "CREATE-DATABASE-ERROR" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
            #read -e -sn 1 -p "PRESS-ANY-KEY-CONTINUE"
        fi
    else
        print_warning "CREATE-DATABASE-PING" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
        write_error   "CREATE-DATABASE-PING" "$3 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
    fi
}
# -----------------------------------------------------------------------------
#
# ADD PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_package";
    USAGE="ADD-PACKAGE-USAGE";
    DESCRIPTION="$(localize "ADD-PACKAGE-DESC")";
    NOTES="$(localize "ADD-PACKAGE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-PACKAGE-USAGE" "add_package 1->(package)" "Comment: add_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-PACKAGE-DESC"  "Add Package to PACKAGES array; for testing and building cache folder" "Comment: add_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-PACKAGE-NOTES" "Call per Package Manager" "Comment: add_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "ADD-PACKAGE-ERROR"  "Wrong Parameters to add_package" "Comment: add_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_package()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$1" ]; then print_error "ADD-PACKAGE-ERROR" " : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    CMD="$(rtrim $1)";
    if [[ -z "$CMD" || "$CMD" == "" ]]; then return 1; fi
    if ! is_in_array "PACKAGES[@]" "$1" ; then
        if [ "${#PACKAGES}" -eq 0 ]; then
            PACKAGES[0]="$1";
        else
            PACKAGES[${#PACKAGES[*]}]="$1";
        fi
    fi
    return 0;
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    add_package "test package";
    MyTotal="${#PACKAGES[@]}";
    if [[ "$MyTotal" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
#
# REMOVE PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_package";
    USAGE="REMOVE-PACKAGE-USAGE";
    DESCRIPTION="$(localize "REMOVE-PACKAGE-DESC")";
    NOTES="$(localize "REMOVE-PACKAGE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-PACKAGE-USAGE" "remove_package 1->(package)" "Comment: remove_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-PACKAGE-DESC"  "Remove Package from PACKAGES array; for testing and building cache folder" "Comment: remove_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-PACKAGE-NOTES" "Call per Package Manager" "Comment: remove_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "REMOVE-PACKAGE-ERROR"  "Wrong Parameters to remove_package" "Comment: remove_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_package()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$1" ]; then
        print_error "REMOVE-PACKAGE-ERROR" " : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
    fi
    CMD="$(rtrim $1)";
    if [[ -z "$CMD" || "$CMD" == "" ]]; then
        return 1;
    fi
    if is_in_array "PACKAGES[@]" "$1" ; then
        remove_from_array "PACKAGES" "$1";
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    remove_package "test package";
    MyTotal="${#PACKAGES[@]}";
    if ! is_in_array "PACKAGES[@]" "test package" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed}$(gettext -s "TEST-FUNCTION-FAILED")  remove_package $MyTotal ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# ADD PACKAGEMANAGER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_packagemanager";
    USAGE="$(localize "ADD-PACKAGEMANAGER-USAGE")";
    DESCRIPTION="$(localize "ADD-PACKAGEMANAGER-DESC")";
    NOTES="$(localize "ADD-PACKAGEMANAGER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-PACKAGEMANAGER-USAGE" "add_packagemanager 1->(COMMAND-LINE) 2->(NAME-OF-PACKAGE)" "Comment: add_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-PACKAGEMANAGER-DESC"  "Add A Package to the Manager" "Comment: add_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-PACKAGEMANAGER-NOTES" "Hart of System." "Comment: add_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "ADD-PACKAGEMANAGER-ERROR"  "Wrong Parameters passed to add_packagemanager" "Comment: add_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_packagemanager()
{
    if [[ "$#" -ne "2" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO")${BYellow} |$@| ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> ${White} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$2" ]; then
        print_error "ADD-PACKAGEMANAGER-ERROR";
    fi
    CMD="$(rtrim $1)"
    if [[ -z "$CMD" || "$CMD" == "" ]]; then
        return 1;
    fi
    # Check to see if its in Array
    if ! is_in_array "PACKMANAGER_NAME[@]" "$2" ; then
        if [ "${#PACKMANAGER}" -eq 0 ]; then
            PACKMANAGER[0]="$1";
        else
            PACKMANAGER[${#PACKMANAGER[*]}]="$1";
        fi
        if [ "${#PACKMANAGER_NAME}" -eq 0 ]; then
            PACKMANAGER_NAME[0]="$2";
        else
            PACKMANAGER_NAME[${#PACKMANAGER_NAME[*]}]="$2";
        fi
        return 0
    fi
    return 1
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    add_packagemanager "package_install 'nano vi' 'INSTALL-APPS-REQUIRED'" "CONFIG-TEST-PACKAGE";
    if is_in_array "PACKMANAGER_NAME[@]" "CONFIG-TEST-PACKAGE" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_packagemanager ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_packagemanager ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# REMOVE PACKAGEMANAGER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_packagemanager";
    USAGE="$(localize "REMOVE-PACKAGEMANAGER-USAGE")";
    DESCRIPTION="$(localize "REMOVE-PACKAGEMANAGER-DESC")";
    NOTES="$(localize "REMOVE-PACKAGEMANAGER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-PACKAGEMANAGER-USAGE" "remove_packagemanager 1->(NAME-OF-PACKAGE)" "Comment: remove_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-PACKAGEMANAGER-DESC"  "Remove A Package to the Manager" "Comment: remove_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-PACKAGEMANAGER-NOTES" "Hart of System." "Comment: remove_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "REMOVE-PACKAGEMANAGER-ERROR"  "Wrong Parameters to add_packagemanager" "Comment: remove_packagemanager @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_packagemanager()
{

    if is_in_array "PACKMANAGER_NAME[@]" "$1" ; then
        remove_from_array "PACKMANAGER_NAME" "$1";
        remove_from_array "PACKMANAGER" "$1";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# PACKAGE INSTALL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="package_install";
    USAGE="$(localize "PACKAGE-INSTALL-USAGE")";
    DESCRIPTION="$(localize "PACKAGE-INSTALL-DESC")";
    NOTES="$(localize "PACKAGE-INSTALL-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PACKAGE-INSTALL-USAGE" "package_install 1->(SPACE DELIMITED LIST OF PACKAGES TO INSTALL) 2->(NAME-OF-PACKAGE-MANAGER)" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-DESC"  "Install package from core or additional Repositories." "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-NOTES" "Install one at a time, check to see if already install, if fails, try again with with confirm." "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "PACKAGE-INSTALL-ERROR"            "Installer did not install Package" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILED-INTERNET"  "Internet check failed" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGE-MANAGER"  "for Package Manager" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-REFRESH"          "Refreshing Repository Database and Updates..." "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-COMPLETE"         "Package Manager Completed" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILURES"         "Installed" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGES"         "Packages" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILED"           "Failed" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-INSTALLED"        "Installed" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-RETRY"            "Retry" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGE"          "install package" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-MANUAL"           "with Manual intervention." "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-CURRENTLY"        "currently working on" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-RETRIES"          "Retries" "Comment: package_install @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
package_install()
{
    refresh_repo;
    if [[ "$USE_PARALLEL" -eq 1 ]]; then
        # This is all done in Parallel; whereas below runs once install at a time
        if ! install_package "$1" "$2" "PACKAGE-INSTALL-$2" ; then
            if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                if ! is_internet ; then
                    restart_internet;
                    sleep 13;
                    if ! is_internet ; then
                        failed_install_core "$PACKAGE";
                        write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                        # @FIX what to do now: restart network adapter
                        abort_install "$RUNTIME_MODE";
                    else
                        print_this "PACKAGE-INSTALL-REFRESH";
                        refresh_repo;
                    fi
                fi
            fi
            print_this " " "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 $(localize "PACKAGE-INSTALL-MANUAL")";
            if ! install_package "$1" "$2" "PACKAGE-INSTALL-$2" ; then
                failed_install_core "$PACKAGE";
                write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                return 1;
            fi
        fi
        print_this "PACKAGE-INSTALL-COMPLETE" ": $2";
        return 0;
    fi
    # USE_PARALLEL = 0
    # install packages one at a time using Installer to check if package is already loaded.
    local -i retry_times=0;
    local -i total_packages="$(echo "$1" | wc -w)";
    local -i number_installed=0;
    local -i number_failed=0;
    local -i current=0;
    #
    for PACKAGE in $1; do
        retry_times=0;
        if ! check_package "$PACKAGE" ; then # 1. First check
            print_info "Installing Package $PACKAGE for Package Manager $2 -> currently working on $current of $total_packages packages, with $number_installed installs";
            install_package_with "$PACKAGE" "0" "0" "x"; # No Confirm, No Force
            # some packages do not register, i.e. mate and mate-extras, so this is a work around; so you do not get stuck in a loop @FIX make a list
            if ! check_package "$PACKAGE" ; then # 2. Failed Once
                ((retry_times++));
                print_this " " "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2";
                print_this "PACKAGE-INSTALL-REFRESH";
                system_upgrade;
                install_package_with "$PACKAGE" "0" "1" "x"; # Install with the No Confirm and Force
                if ! check_package "$PACKAGE" ; then # 3. Failed Twice
                    ((retry_times++));
                    if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                        if ! is_internet ; then
                            restart_internet;
                            sleep 13;
                            if ! is_internet ; then
                                failed_install_core "$PACKAGE";
                                write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                                # @FIX what to do now: restart network adapter
                                abort_install "$RUNTIME_MODE";
                            else
                                print_this "PACKAGE-INSTALL-REFRESH";
                                system_upgrade;
                            fi
                        fi
                    fi
                    print_this "*" "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 $(localize "PACKAGE-INSTALL-MANUAL") $(localize "PACKAGE-INSTALL-CURRENTLY") $current -> $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES") -> $(localize "PACKAGE-INSTALL-RETRIES") = ${retry_times}";
                    install_package_with "$PACKAGE" "1" "0" "x"; # Install with Manual Interaction, Confirm and no Force
                    # Last try
                    if ! check_package "$PACKAGE" ; then # 4. Failed Three times
                        ((retry_times++));
                        ((number_failed++)); # increment number installed
                        make_dir "${LOG_PATH}/failures/core/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        touch "${LOG_PATH}/failures/core/${PACKAGE}.log";
                        install_package_with "$PACKAGE" "1" "1" "x" 2> "${LOG_PATH}/failures/core/${PACKAGE}.log"; # Install with the force and Log output
                        if ! check_package "$PACKAGE" ; then # 4. Failed Three times
                            failed_install_core "$PACKAGE";
                            write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                        fi
                    else
                        installed_core "$PACKAGE";
                        ((number_installed++));
                    fi
                else
                    installed_core "$PACKAGE";
                    ((number_installed++));
                fi
            else
                installed_core "$PACKAGE";
                ((number_installed++));
            fi
        else
            installed_core "$PACKAGE"; # Already Installed
            ((number_installed++));
        fi
    done
    print_this "PACKAGE-INSTALL-COMPLETE" ": $2";
    if [[ "$number_installed" -eq "$total_packages" ]]; then
        return 0;
    else
        print_error "PACKAGE-INSTALL-FAILURES" ": $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES"), $number_failed $(localize "PACKAGE-INSTALL-FAILED"), $number_installed $(localize "PACKAGE-INSTALL-INSTALLED") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "PACKAGE-INSTALL-FAILURES" ": $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES"), $number_failed $(localize "PACKAGE-INSTALL-FAILED"), $number_installed $(localize "PACKAGE-INSTALL-INSTALLED") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# PACKAGE GROUP INSTALL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="package_group_install";
    USAGE="$(localize "PACKAGE-INSTALL-USAGE")";
    DESCRIPTION="$(localize "PACKAGE-INSTALL-DESC")";
    NOTES="$(localize "PACKAGE-INSTALL-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PACKAGE-INSTALL-USAGE" "package_group_install 1->(SPACE DELIMITED LIST OF PACKAGES TO INSTALL) 2->(NAME-OF-PACKAGE-MANAGER)" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-DESC"  "Install package from core or additional Repositories." "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-NOTES" "Install one at a time, check to see if already install, if fails, try again with with confirm." "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "PACKAGE-INSTALL-ERROR"            "Installer did not install Package" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILED-INTERNET"  "Internet check failed" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGE-MANAGER"  "for Package Manager" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-REFRESH"          "Refreshing Repository Database and Updates..." "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-COMPLETE"         "Package Manager Completed" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILURES"         "Installed" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGES"         "Packages" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-FAILED"           "Failed" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-INSTALLED"        "Installed" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-RETRY"            "Retry" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-PACKAGE"          "install package" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-MANUAL"           "with Manual intervention." "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-CURRENTLY"        "currently working on" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-INSTALL-RETRIES"          "Retries" "Comment: package_group_install @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
package_group_install()
{
    refresh_repo;
    if [[ "$USE_PARALLEL" -eq 1 ]]; then
        # This is all done in Parallel; whereas below runs once install at a time
        if ! install_package "$1" "$2" "PACKAGE-INSTALL-$2" ; then
            if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                if ! is_internet ; then
                    restart_internet;
                    sleep 13;
                    if ! is_internet ; then
                        failed_install_core "$PACKAGE";
                        write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                        # @FIX what to do now: restart network adapter
                        abort_install "$RUNTIME_MODE";
                    else
                        print_this "PACKAGE-INSTALL-REFRESH";
                        refresh_repo;
                    fi
                fi
            fi
            print_this " " "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 $(localize "PACKAGE-INSTALL-MANUAL")"
            if ! install_package "$1" "$2" "PACKAGE-INSTALL-$2" ; then
                failed_install_core "$PACKAGE";
                write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                return 1;
            fi
        fi
        print_this "PACKAGE-INSTALL-COMPLETE" ": $2";
        return 0;
    fi
    # USE_PARALLEL = 0;
    # install packages one at a time using Installer to check if package is already loaded.
    local -i retry_times=0;
    local -i total_packages="$(echo "$1" | wc -w)";
    local -i number_installed=0;
    local -i number_failed=0;
    local -i current=0;
    #
    for PACKAGE in $1; do
        retry_times=0
        if ! check_package "$PACKAGE" ; then # 1. First check
            print_info "Installing Package $PACKAGE for Package Manager $2 -> currently working on $current of $total_packages packages, with $number_installed installs";
            install_group_package_with '--noconfirm --needed' "$PACKAGE";
            # some packages do not register, i.e. mate and mate-extras, so this is a work around; so you do not get stuck in a loop @FIX make a list
            if ! check_package "$PACKAGE" ; then # 2. Failed Once
                ((retry_times++));
                print_this " " "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2";
                print_this "PACKAGE-INSTALL-REFRESH";
                system_upgrade;
                install_group_package_with '--noconfirm --needed --force' "$PACKAGE"; # Install with the force
                if ! check_package "$PACKAGE" ; then # 3. Failed Twice
                    ((retry_times++));
                    if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                        if ! is_internet ; then
                            restart_internet;
                            sleep 13;
                            if ! is_internet ; then
                                failed_install_core "$PACKAGE";
                                write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - $(localize "PACKAGE-INSTALL-FAILED-INTERNET") - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                                # @FIX what to do now: restart network adapter
                                abort_install "$RUNTIME_MODE";
                            else
                                print_this "PACKAGE-INSTALL-REFRESH";
                                system_upgrade;
                            fi
                        fi
                    fi
                    print_this "*" "${BRed} $(localize "PACKAGE-INSTALL-RETRY") ${BWhite}  $(localize "PACKAGE-INSTALL-PACKAGE") $PACKAGE $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 $(localize "PACKAGE-INSTALL-MANUAL") $(localize "PACKAGE-INSTALL-CURRENTLY") $current -> $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES") -> $(localize "PACKAGE-INSTALL-RETRIES") = ${retry_times}";
                    install_group_package_with ' --needed' "$PACKAGE"; # Install with Manual Interaction
                    # Last try
                    if ! check_package "$PACKAGE" ; then # 4. Failed Three times
                        ((retry_times++));
                        ((number_failed++)); # increment number installed
                        make_dir "${LOG_PATH}/failures/core/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        touch "${LOG_PATH}/failures/core/${PACKAGE}.log";
                        install_group_package_with '--noconfirm --needed --force' "$PACKAGE" 2> "${LOG_PATH}/failures/core/${PACKAGE}.log"; # Install with the force and Log output
                        if ! check_package "$PACKAGE" ; then # 4. Failed Three times
                            failed_install_core "$PACKAGE";
                            write_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            print_error "PACKAGE-INSTALL-ERROR" ": $PACKAGE - $(localize "PACKAGE-INSTALL-PACKAGE-MANAGER") $2 - USE_PARALLEL=$USE_PARALLEL : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                        fi
                    else
                        installed_core "$PACKAGE";
                        ((number_installed++));
                    fi
                else
                    installed_core "$PACKAGE";
                    ((number_installed++));
                fi
            else
                installed_core "$PACKAGE";
                ((number_installed++));
            fi
        else
            installed_core "$PACKAGE"; # Already Installed
            ((number_installed++));
        fi
    done
    print_this "PACKAGE-INSTALL-COMPLETE" ": $2"
    if [[ "$number_installed" -eq "$total_packages" ]]; then
        return 0;
    else
        print_error "PACKAGE-INSTALL-FAILURES" ": $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES"), $number_failed $(localize "PACKAGE-INSTALL-FAILED"), $number_installed $(localize "PACKAGE-INSTALL-INSTALLED") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "PACKAGE-INSTALL-FAILURES" ": $total_packages - $(localize "PACKAGE-INSTALL-PACKAGES"), $number_failed $(localize "PACKAGE-INSTALL-FAILED"), $number_installed $(localize "PACKAGE-INSTALL-INSTALLED") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# PACKAGE REMOVE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="package_remove";
    USAGE="$(localize "PACKAGE-REMOVE-USAGE")";
    DESCRIPTION="$(localize "PACKAGE-REMOVE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PACKAGE-REMOVE-USAGE" "package_remove 1->(SPACE DELIMITED LIST OF PACKAGES TO REMOVE) 2->(NAME-OF-PACKAGE-MANAGER)" "Comment: package_remove @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PACKAGE-REMOVE-DESC"  "Package remove" "Comment: package_remove @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "PACKAGE-REMOVE-INFO"  "Removing package" "Comment: package_remove @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
package_remove()
{
    refresh_repo;
    for PACKAGE in $1; do
        if check_package "$PACKAGE" ; then
            print_info "PACKAGE-REMOVE-INFO" ": $PACKAGE";
            if [[ "$My_OS" == "solaris" ]]; then
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_OS" == "aix" ]]; then
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_OS" == "freebsd" ]]; then
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_OS" == "windowsnt" ]]; then
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_OS" == "mac" ]]; then
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_OS" == "linux" ]]; then
                # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
                # See wizard.sh os_info to see if OS test exist or works
                if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                    sudo yum remove "$PACKAGE" -y;
                elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
                    # sudo pacman -Rcsn --noconfirm "$PACKAGE" # This operation is recursive, and must be used with care since it can remove many potentially needed packages.
                    sudo pacman -Rddn --noconfirm "$PACKAGE";   # We wish to remove some apps that will be replace with ones that replace it, so do not remove dependencies.
                elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
                    sudo apt-get remove "$PACKAGE" -y
                elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                    print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
                elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
                    print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
                elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                    print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
                fi
            fi
        fi
    done
}
#}}}
# -----------------------------------------------------------------------------
# INSTALL PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="install_package";
    USAGE="$(localize "INSTALL-PACKAGE-USAGE")";
    DESCRIPTION="$(localize "INSTALL-PACKAGE-DESC")";
    NOTES="$(localize "INSTALL-PACKAGE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALL-PACKAGE-USAGE" "install_package 1->(NAME_OF_PACKAGE space delimited) 2->(NAME-OF-PACKAGE-MANAGER)" "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-DESC"  "Install package from core or additional Repositories." "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-NOTES" "Install one at a time, check to see if already install, if fails, try again with with confirm." "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "INSTALL-PACKAGE-INSTALLING"     "Installer Installing" "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-ERROR-1"        "Installer did not install Package" "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-ERROR-2"        "for Install Package Manager" "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-INSTALL-PM2ML"  "using pm2ml: Installing" "Comment: install_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
install_package()
{
    refresh_repo;
    if [[ "$USE_PARALLEL" -eq 0 ]]; then
        IS_ERROR=0;
        for PACKAGE in $1; do
            if ! check_package "$PACKAGE" ; then
                IS_ERROR=1;
                write_error "INSTALL-PACKAGE-ERROR" ": [$1] $(localize "INSTALL-PACKAGE-ERROR-2") $2 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error "INSTALL-PACKAGE-ERROR" ": [$1] $(localize "INSTALL-PACKAGE-ERROR-2") $2 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            fi
        done
        if [[ "$IS_ERROR" -eq 1 ]]; then
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            return 1;
        fi
        return 0;
    elif [[ "$USE_PARALLEL" -eq 1 ]]; then
        print_info "INSTALL-PACKAGE-INSTALLING" ": $2";
        if ! package_install "$1" "$2" ; then
            IS_ERROR=1;
            write_error "INSTALL-PACKAGE-ERROR" ": [$1] $(localize "INSTALL-PACKAGE-ERROR-2") $2 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_error "INSTALL-PACKAGE-ERROR" ": [$1] $(localize "INSTALL-PACKAGE-ERROR-2") $2 : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        fi
        # install_package_with "$1" "1" "0" "x"
    else
        print_info "INSTALL-PACKAGE-INSTALL-PM2ML" ": $2";
        # ppls "$1";
        # Arguments for aria2c.
        aria2_args=( "--metalink-file=-"  "--conf-path=/etc/ppl.conf" )
        # download packages
        pm2ml -no /var/cache/pacman/pkg "$1" -r -p http -l 50 | aria2c "${aria2_args[@]}"
        # invoke pacman
        if [[ "$RUNTIME_MODE" -eq 1 ]]; then
            install_package_with "$1" "0" "0" "x"; # If running from Boot Mode; you don't want to upgrade the system
        else
            install_package_with "$1" "0" "0" "-u";
        fi
    fi
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# DO CURL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_curl";
    USAGE="$(localize "DO-CURL-USAGE")";
    DESCRIPTION="$(localize "DO-CURL-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-CURL-USAGE"         "do_curl 1->(name of AUR Package)" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CURL-DESC"          "Download AUR Package file via curl." "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-CURL-DOWNLOADED"    "Downloaded AUR Package" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CURL-FAILED"        "Failed to Downloaded AUR Package" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CURL-PASSED"        "Downloaded AUR Package" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CURL-DOWNLOADING"   "Downloading:" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-CURL-ONLINE-FAILED" "Failed to ping https://aur.archlinux.org" "Comment: do_curl @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_curl()
{
    #
    curl_this()
    {
        if curl -o "${1}.tar.gz" "https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz" ; then
            write_log "DO-CURL-DOWNLOADED" ": ${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 0;
        else
            return 1;
        fi
    }
    #
    local -i DOWNLOADED=0;
    if curl_this "${1}" ; then
        DOWNLOADED=1;
    else
        local -i RETRIES=0;
        while [  $RETRIES -lt 3 ]; do
            print_this "DO-CURL-DOWNLOADING" " $1.tar.gz -> https://aur.archlinux.org/packages/${1:0:2}/$1/$1.tar.gz :) RETRIES=$RETRIES";
            if curl_this "$1" ; then
                DOWNLOADED=1;
                break;
            else
                if ! is_online "aur.archlinux.org" ; then
                    if ! is_internet ; then
                        restart_internet;
                    else
                        write_error "DO-CURL-ONLINE-FAILED" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        if [[ "$DEBUGGING" -eq 1 ]]; then
                            print_this     "DO-CURL-ONLINE-FAILED" " curl -o ${1}.tar.gz https://aur.archlinux.org/1/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                            pause_function "${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        fi
                    fi
                fi
                sleep 60; # the Ultimate wait a minute
            fi
            ((RETRIES++));
        done
    fi
    if [[ "$DOWNLOADED" -eq 1 ]]; then
        return 0;
    else
        write_error "DO-CURL-FAILED" ": ${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        return 1;
    fi
}
#}}}
# -----------------------------------------------------------------------------
# AUR DOWNLOAD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="aur_download";
    USAGE="aur_download 1->(Package Name)";
    DESCRIPTION="$(localize "AUR-DOWNLOAD-DESC")";
    NOTES="$(localize "AUR-DOWNLOAD-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "AUR-DOWNLOAD-DESC"  "AUR Download Packages" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-NOTES" "&#36;AUR_CUSTOM_PACKAGES: if Boot Mode /root/usb/AUR-Packages, if Live Mode /mnt/AUR-Packages" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "AUR-DOWNLOAD-DOWNLOADING-AUR-PACKAGE" "Downloading AUR Package" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-FILE-EXIST"              "File Exist, check date of file" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGE-UP2DATE"         "Up to date Package" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-FILE-CORRUPTED"          "File Corrupted:" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-FILE-NOT-FOUND"          "File Not Found" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-CURL-FAILED"             "Failed to Downloaded AUR Package" "Comment: aur_download @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
aur_download()
{
    local -i IsFileNew=0;
    print_info "AUR-DOWNLOAD-DOWNLOADING-AUR-PACKAGE" " $1";
    if ! cd "$AUR_CUSTOM_PACKAGES/"; then
        make_dir "$AUR_CUSTOM_PACKAGES/"    "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"
        print_error "TEST-FUNCTION-FAILED" "configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    if [ -f "${1}.tar.gz" ]; then
        print_this "AUR-DOWNLOAD-FILE-EXIST" " ${1}"; # @FIX check date, if it needs to be updated, download it again
        IsFileNew=0;
        # curl -z 21-Dec-11 http://www.example.com/yy.html
        # -z "$(date —rfc-2822 -d @$(<index.html.timestamp))"
        # @FIX will it rename on download, since file exist
        # curl -z "${1}.tar.gz" -o "${1}.tar.gz" "https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz"
    else
        if ! do_curl "$1" ; then
            write_error "AUR-DOWNLOAD-CURL-FAILED" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then
                print_this     "AUR-DOWNLOAD-CURL-FAILED" " curl -o ${1}.tar.gz https://aur.archlinux.org/1/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            fi
            return 1;
        fi
        IsFileNew=1;
    fi
    #
    if [ -f "${1}.tar.gz" ]; then
        if [[ -d "$1" && IsFileNew -eq 0 ]]; then
            print_this "AUR-DOWNLOAD-PACKAGE-UP2DATE" ": $1";
            if [ ! -d "${1}" ]; then
                if ! tar zxvf "$1.tar.gz" ; then
                    write_error "AUR-DOWNLOAD-FILE-CORRUPTED" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    if [[ "$DEBUGGING" -eq 1 ]]; then
                        print_this     "AUR-DOWNLOAD-FILE-CORRUPTED" " curl -o ${1}.tar.gz https://aur.archlinux.org/1/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                        pause_function "${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    fi
                    return 1;
                fi
            fi
            chown -R "${USERNAME}:${USERNAME}" "$AUR_CUSTOM_PACKAGES/${1}";
            chmod -R 775 "$AUR_CUSTOM_PACKAGES/${1}";
            cd "${1}";
            # @FIX check for compliled code
            return 0;
        else
            if tar zxvf "$1.tar.gz" ; then
                if [[ "$AUR_REPO" -ne 1 ]]; then # AUR Repo
                    rm "${1}.tar.gz";
                fi
                chown -R "${USERNAME}:${USERNAME}" "$AUR_CUSTOM_PACKAGES/${1}";
                chmod -R 775 "$AUR_CUSTOM_PACKAGES/${1}";
                cd "${1}";
                return 0;
            else
                write_error "AUR-DOWNLOAD-FILE-CORRUPTED" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then
                    print_this     "AUR-DOWNLOAD-FILE-CORRUPTED" " curl -o ${1}.tar.gz https://aur.archlinux.org/1/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    pause_function "${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                fi
                return 1;
            fi
        fi
    else
        write_error "AUR-DOWNLOAD-FILE-NOT-FOUND" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then
            print_this     "AUR-DOWNLOAD-FILE-NOT-FOUND" " curl -o ${1}.tar.gz https://aur.archlinux.org/packages/${1:0:2}/${1}/${1}.tar.gz : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            pause_function "${1} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
        return 1;
    fi
    return 1;
}
#}}}
# -----------------------------------------------------------------------------
# GET AUR PACKAGES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="get_aur_packages";
    USAGE="$(localize "GET-AUR-PACKAGES-USAGE")";
    DESCRIPTION="$(localize "GET-AUR-PACKAGES-DESC")";
    NOTES="$(localize "GET-AUR-PACKAGES-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "GET-AUR-PACKAGES-USAGE"            "get_aur_packages 1->(package-name) 2->(&#36;DEBUGGING) 3->(&#36;AUR_REPO)" "Comment: get_aur_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-AUR-PACKAGES-DESC"             "Get AUR packages" "Comment: get_aur_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-AUR-PACKAGES-NOTES"            "Called from export under user, so script functions not available, cd folder before calling" "Comment: get_aur_packages @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "GET-AUR-PACKAGES-COMPILING"        "Compiling Package" "Comment: get_aur_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "GET-AUR-PACKAGES-FAILED-COMPILING" "Failed to compile" "Comment: get_aur_packages @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
get_aur_packages()
{
    # Ran from User Not root; so its running in a emtpy sandbox, so export all functions you need
    local White='\e[0;37m';  # White
    local BWhite='\e[1;37m'; # Bold White
    local BRed='\e[1;31m';   # Red
    #
    if [ "$#" -ne "3" ]; then echo -e "${BRed} get_aur_packages $(gettext -s "WRONG-NUMBER-OF-ARGUMENTS") ${White}"; fi
    local parms="-s";
    if [[ "$3" -eq 1 ]]; then # AUR Repo
        parms="-fs";
    else                      # No Repo
        parms="-fsi";          # Install
    fi
    echo -e "${BWhite}\t $(gettext -s "GET-AUR-PACKAGES-COMPILING") ${1} makepkg ${parms} --noconfirm in function: get_aur_packages at line: $(basename $BASH_SOURCE) : $LINENO ${White}";
    cd "${1}";
    if ! makepkg ${parms} --noconfirm ; then
        if [[ "$2" -eq 1 ]]; then # DEBUGGING
            echo -e "${BRed}\t${1} $(gettext -s "GET-AUR-PACKAGES-FAILED-COMPILING") makepkg ${parms} --noconfirm in function: get_aur_packages at line: $(basename $BASH_SOURCE) : $LINENO ${White}";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE") (get_aur_packages ${1})...";
        fi
        return 1;
    fi
    return 0;

    #
    echo -e "${BWhite}\t $(gettext -s "GET-AUR-PACKAGES-COMPILING") ${1} makepkg ${parms} --noconfirm in function: get_aur_packages at line: $(basename $BASH_SOURCE) : $LINENO ${White}"
    cd "${1}";
    if [[ "$3" -eq 1 ]]; then # AUR Repo
        if ! makepkg -s --noconfirm ; then
            if [[ "$2" -eq 1 ]]; then # DEBUGGING
                echo -e "${BRed}\t${1} $(gettext -s "GET-AUR-PACKAGES-FAILED-COMPILING") makepkg ${parms} --noconfirm in function: get_aur_packages at line: $(basename $BASH_SOURCE) : $LINENO ${White}";
                read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE") (get_aur_packages ${1})...";
            fi
            return 1;
        fi
    else                      # No Repo
        if ! makepkg -si --noconfirm ; then
            if [[ "$2" -eq 1 ]]; then # DEBUGGING
                echo -e "${BRed}\t${1} $(gettext -s "GET-AUR-PACKAGES-FAILED-COMPILING") makepkg ${parms} --noconfirm in function: get_aur_packages at line: $(basename $BASH_SOURCE) : $LINENO ${White}";
                read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE") (get_aur_packages ${1})...";
            fi
            return 1;
        fi
    fi
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
#
export -f get_aur_packages # need to export so if we are running as user it will find it
#
# AUR DOWNLOAD PACKAGES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="aur_download_packages";
    USAGE="$(localize "AUR-DOWNLOAD-PACKAGES-USAGE")";
    DESCRIPTION="$(localize "AUR-DOWNLOAD-PACKAGES-DESC")";
    NOTES="$(localize "AUR-DOWNLOAD-PACKAGES-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "AUR-DOWNLOAD-PACKAGES-USAGE" "aur_download_packages 1->(Package Names Space Delimited)" "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-DESC"  "AUR Download Packages" "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-NOTES" "AUR_CUSTOM_PACKAGES: if Boot Mode /root/usb/AUR-Packages, if Live Mode /mnt/AUR-Packages" "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "AUR-DOWNLOAD-PACKAGES-TITLE"              "AUR Package Downloader." "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-WARN-CREATE-FOLDER" "Could not create folder " "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-WORKING-ON"         "Working on Package " "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-RETRIES"            "retries" "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-DOWNLOAD-PACKAGES-FAILED-DOWNLOAD"    "Failed Downloading AUR Package" "Comment: aur_download_packages @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
aur_download_packages()
{
    local OLD_IFS="$IFS"; IFS=$' '; # Very Important
    AUR_CUSTOM_PACKAGES="/home/${USERNAME}/${AUR_REPO_NAME}" # if Boot Mode /root/usb/AUR-Packages, if Live Mode /mnt/AUR-Packages
    #
    print_info "AUR-DOWNLOAD-PACKAGES-TITLE";
    MyReturn=0;
    local -i retries=0;
    for PACKAGE in $1; do
        if [ ! -d "$AUR_CUSTOM_PACKAGES/" ]; then
            if ! make_dir "$AUR_CUSTOM_PACKAGES/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO" ; then
                print_error  "AUR-DOWNLOAD-PACKAGES-WARN-CREATE-FOLDER" "$AUR_CUSTOM_PACKAGES";
                pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                cd "$FULL_SCRIPT_PATH";
                IFS="$OLD_IFS";
                return 1;
            fi
            chmod -R 770 "$AUR_CUSTOM_PACKAGES/${1}";
        fi
        retries=0; # Reset
        YN_OPTION=0;
        while [[ "$YN_OPTION" -ne 1 ]]; do
            ((retries++));
            print_info "AUR-DOWNLOAD-PACKAGES-WORKING-ON" "$PACKAGE $(localize "AUR-DOWNLOAD-PACKAGES-RETRIES") = $retries";
            aur_download "$PACKAGE";
            MyReturn="$?"; # Always call this frist thing after a function return to capture it.
            if [[ "$MyReturn" == 0 ]]; then
                if cd "$AUR_CUSTOM_PACKAGES/" ; then
                    chown -R "${USERNAME}:${USERNAME}" "$AUR_CUSTOM_PACKAGES/";
                    # exec command as user instead of root
                    su "${USERNAME}" -c "get_aur_packages \"$PACKAGE\" \"$DEBUGGING\" \"$AUR_REPO\""; # Run as User
                    MyReturn="$?"; # Always call this frist thing after a function return to capture it.
                    YN_OPTION=1;
                fi
            fi
            if [[ "$retries" -gt 3 ]]; then
                YN_OPTION=1;
                write_error "AUR-DOWNLOAD-PACKAGES-FAILED-DOWNLOAD" " $PACKAGE : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error "AUR-DOWNLOAD-PACKAGES-FAILED-DOWNLOAD" " $PACKAGE : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            fi
            #
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$PACKAGE $(localize "AUR-DOWNLOAD-PACKAGES-RETRIES") = $retries : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        done
        #
    done
    cd "$FULL_SCRIPT_PATH";
    IFS="$OLD_IFS";
    return "$MyReturn";
}
#}}}
# -----------------------------------------------------------------------------
# CONFIGURE AUR HELPER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="configure_aur_helper";
    USAGE="configure_aur_helper";
    DESCRIPTION="$(localize "CONFIGURE-AUR-HELPER-DESC")";
    NOTES="$(localize "CONFIGURE-AUR-HELPER-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CONFIGURE-AUR-HELPER-DESC"          "Configure AUR Helper" "Comment: configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-AUR-HELPER-NOTES"         "Should only be run from Live Mode." "Comment: configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CONFIGURE-AUR-HELPER-CONFIG-HELP"   "Configuring AUR Helper" "Comment: configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-AUR-HELPER-NOT-INSTALLED" "Not Installed" "Comment: configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CONFIGURE-AUR-HELPER-INSTALLED"     "Installed" "Comment: configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
configure_aur_helper()
{
    # base-devel installed with pacstrap
    if [[ "$AUR_HELPER" == 'yaourt' ]]; then
        if ! check_package "yaourt" ; then
            print_info "CONFIGURE-AUR-HELPER-CONFIG-HELP" ": $AUR_HELPER";
            package_install "yajl namcap" "INSTALL-AUR-HELPER-$AUR_HELPER";
            sudo pacman -D --asdeps yajl namcap;
            if ! aur_download_packages "package-query yaourt" ; then
                write_error    "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error  "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if ! aur_download_packages "package-query yaourt" ; then
                    write_error    "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    print_error  "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    return 1;
                fi
            else
                print_info "CONFIGURE-AUR-HELPER-INSTALLED" " $AUR_HELPER";
            fi
            sudo pacman -D --asdeps package-query;
            if ! check_package "yaourt" ; then
                print_error "CONFIGURE-AUR-HELPER-NOT-INSTALLED" ": $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                write_error "CONFIGURE-AUR-HELPER-NOT-INSTALLED" ": $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                # @FIX how to fix this
                pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                return 1;
            fi
        fi
    elif [[ "$AUR_HELPER" == 'packer' ]]; then
        if ! check_package "packer" ; then
            print_info "CONFIGURE-AUR-HELPER-CONFIG-HELP" " $AUR_HELPER";
            package_install "git jshon" "INSTALL-AUR-HELPER-$AUR_HELPER";
            sudo pacman -D --asdeps jshon;
            aur_download_packages "packer";
            if ! check_package "packer" ; then
                echo "Packer not installed. EXIT now";
                write_error    "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error  "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                return 1;
            fi
        fi
    elif [[ "$AUR_HELPER" == 'pacaur' ]]; then
        if ! check_package "pacaur" ; then
            print_info "CONFIGURE-AUR-HELPER-CONFIG-HELP" " $AUR_HELPER";
            package_install "yajl expac" "INSTALL-AUR-HELPER-$AUR_HELPER";
            sudo pacman -D --asdeps yajl expac;
            #fix pod2man path
            ln -s /usr/bin/core_perl/pod2man /usr/bin/;
            aur_download_packages "cower pacaur";
            sudo pacman -D --asdeps cower;
            if ! check_package "pacaur" ; then
                echo "Pacaur not installed. EXIT now";
                write_error    "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error  "CONFIGURE-AUR-HELPER-NOT-INSTALLED" " $AUR_HELPER : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                return 1;
            fi
        fi
    fi
    if [[ "$IS_PHTHON3_AUR" -eq 1 ]]; then
        $AUR_HELPER -S python3-aur;
    fi
    # $AUR_HELPER -Syua --devel --noconfirm # Do I need to do this?
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 4 ]]; then
    if is_os "archlinux" ; then
        if aur_download_packages "package-query yaourt" ; then
            print_test "TEST-FUNCTION-PASSED" "configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
        else
            print_error "TEST-FUNCTION-FAILED" "configure_aur_helper @ $(basename $BASH_SOURCE) : $LINENO";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
        fi
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# INSTALL PACKAGE WITH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="install_package_with";
    USAGE="$(localize "INSTALL-PACKAGE-WITH-USAGE")";
    DESCRIPTION="$(localize "INSTALL-PACKAGE-WITH-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALL-PACKAGE-WITH-USAGE" "install_package_with 1->(Package) 2->(Confirm) 3->(Force) 4->(extra)" "Comment: install_package_with @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-PACKAGE-WITH-DESC"  "Install Package with Parametters" "Comment: install_package_with @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "INSTALL-PACKAGE-WITH-INFO"  "Installing Package with" "Comment: install_package_with @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
install_package_with()
{
    print_info "INSTALL-PACKAGE-WITH-INFO" "$1";
    if [[ "$REFRESH_REPO" -eq 1 ]]; then
        REFRESH_REPO=0;
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            sudo yum update;
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            sudo pacman -Syy && abs;
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            sudo apt-get update;
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    fi
    #
    if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo yum install "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            rpm -e --nodeps PACKAGE
            # or rpm -e --justdb --nodeps PACKAGE
            sudo yum install "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            rpm -e --nodeps PACKAGE
            # or rpm -e --justdb --nodeps PACKAGE
            sudo yum install "$1" -y;
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo yum install "$1" -y;
        else                                       # Default No Confirm
            sudo yum install "$1" -y;
        fi
    elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo pacman --needed -S "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            sudo pacman --needed --force -S "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            sudo pacman --needed --noconfirm --force -S "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo pacman --needed --noconfirm -S "$1";
        else
            sudo pacman --noconfirm --needed -S "$1";   # Default No Confirm
        fi
    elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo apt-get install "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            sudo apt-get -f install "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            sudo apt-get -f -y install "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo apt-get -y install "$1";
        else
            sudo apt-get -y install "$1";   # Default No Confirm
        fi
    elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# INSTALL GROUP PACKAGE WITH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="install_group_package_with";
    USAGE="$(localize "INSTALL-GROUP-PACKAGE-WITH-USAGE")";
    DESCRIPTION="$(localize "INSTALL-GROUP-PACKAGE-WITH-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALL-GROUP-PACKAGE-WITH-USAGE" "install_group_package_with 1->(Package) 2->(confirm) 3->(force) 4->(extra)" "Comment: install_group_package_with @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-GROUP-PACKAGE-WITH-DESC"  "Install Package with Parameters" "Comment: install_group_package_with @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "INSTALL-GROUP-PACKAGE-WITH-INFO"  "Installing Package with" "Comment: install_group_package_with @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
install_group_package_with()
{
    print_info "INSTALL-GROUP-PACKAGE-WITH-INFO" "$1";
    if [[ "$REFRESH_REPO" -eq 1 ]]; then
        REFRESH_REPO=0;
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            sudo yum update;
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            sudo pacman -Syy;
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            sudo apt-get update;
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    fi
    #
    if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo yum groupinstall "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            rpm -e --nodeps PACKAGE;
            # or rpm -e --justdb --nodeps PACKAGE
            sudo yum groupinstall "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            rpm -e --nodeps PACKAGE;
            # or rpm -e --justdb --nodeps PACKAGE
            sudo yum groupinstall "$1" -y;
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo yum groupinstall "$1" -y;
        else                                       # Default No Confirm
            sudo yum groupinstall "$1" -y;
        fi
    elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo pacman --needed -S "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            sudo pacman --needed --force -S "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            sudo pacman --needed --noconfirm --force -S "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo pacman --needed --noconfirm -S "$1";
        else                                       # Default No Confirm
            sudo pacman --noconfirm --needed -S "$1";
        fi
    elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
        if [[ "$2" -eq 0 && "$3" -eq 0 ]]; then    # Confirm
            sudo apt-get install "$1";
        elif [[ "$2" -eq 0 && "$3" -eq 1 ]]; then  # Confirm and Force
            sudo apt-get -f install "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 1 ]]; then  # No Confirm and Force
            sudo apt-get -f -y install "$1";
        elif [[ "$2" -eq 1 && "$3" -eq 0 ]]; then  # No Confirm
            sudo apt-get -y install "$1";
        else                                       # Default No Confirm
            sudo apt-get -y install "$1";
        fi
    elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    fi
}
#}}}
# -----------------------------------------------------------------------------
# REFRESH REPO {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="refresh_repo";
    USAGE="refresh_repo";
    DESCRIPTION="$(localize "REFRESH-REPO-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REFRESH-REPO-DESC"  "Refresh Repository" "Comment: refresh_repo @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "REFRESH-REPO-INFO"  "Refresh Repository Database..." "Comment: refresh_repo @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
refresh_repo()
{
    if [[ "$REFRESH_REPO" -eq 1 ]]; then
        REFRESH_REPO=0
        print_info "REFRESH-REPO-INFO"
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            sudo yum update;
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            sudo pacman -Syy;
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            sudo apt-get update;
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# SYSTEM UPDATE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="system_upgrade";
    USAGE="system_upgrade";
    DESCRIPTION="$(localize "SYSTEM-UPDATE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SYSTEM-UPDATE-DESC"  "Full Installer System Upgrade: Set a var so you do not do this every call, then perform an optimize" "Comment: system_upgrade @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "SYSTEM-UPDATE-INFO"  "UPDATING YOUR SYSTEM" "Comment: system_upgrade @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
system_upgrade()
{
    print_info "SYSTEM-UPDATE-INFO";
    if [[ "$REFRESH_REPO" -eq 1 ]]; then
        if [[ "$USE_PARALLEL" -eq 0 ]]; then
            if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                sudo yum update; sudo yum upgrade -y;
            elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
                sudo pacman -Syy --noconfirm; sudo pacman -Su --noconfirm;
            elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
                sudo apt-get update; sudo apt-get upgrade;
            elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            fi
        else
            # pplsyu
            aria2_args=( "--metalink-file=-" "--conf-path=/etc/ppl.conf" ); # Arguments for aria2c.
            sudo pacman -Sy; # sync databases
            #pm2ml -ysd var/lib/pacman/sync | aria2c "${aria2_args[@]}";
            # download packages
            pm2ml -no var/cache/pacman/pkg -u -r -p http -l 50 | aria2c "${aria2_args[@]}";
            # invoke pacman
            sudo pacman -Su  --noconfirm;
        fi
        REFRESH_REPO=0;
    else
        if [[ "$USE_PARALLEL" -eq 0 ]]; then
            if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
                sudo yum update; sudo yum upgrade -y;
            elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
                sudo pacman -Syy --noconfirm; sudo pacman -Su --noconfirm;
            elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
                sudo apt-get update; sudo apt-get upgrade;
            elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
                print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
            fi
        else
            # pplsyu;
            aria2_args=( "--metalink-file=-" "--conf-path=/etc/ppl.conf" ); # Arguments for aria2c.
            # download packages
            pm2ml -no var/cache/pacman/pkg -u -r -p http -l 50 | aria2c "${aria2_args[@]}";
            # invoke pacman
            sudo pacman -Su  --noconfirm;
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# UPDATE SYSTEM {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="update_system";
    USAGE="$(localize "UPDATE-SYSTEM-USAGE")";
    DESCRIPTION="$(localize "UPDATE-SYSTEM-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "UPDATE-SYSTEM-DESC"  "Update System" "Comment: update_system @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UPDATE-SYSTEM-USAGE" "update_system 1->(Distro Type) 2->(Use Parallel Update) 3->(IP address)" "Comment: update_system @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "UPDATE-SYSTEM-INFO"  "Update System" "Comment: update_system @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UPDATE-SYSTEM-UP"    "System Updated" "Comment: update_system @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
update_system()
{
    if [[ "$#" -ne "3" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    print_info "UPDATE-SYSTEM-INFO";
    if [[ "$2" -eq 0 ]]; then
        if [[ "$1" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            if [[ "$3" == '0.0.0.0' || "$3" == '127.0.0.1' ]]; then
                sudo yum-complete-transaction && sudo package-cleanup --dupes && sudo ackage-cleanup --dupes && sudo package-cleanup --problems && sudo yum update -y && sudo yum upgrade -y;
            else
                ssh "root@$3" "yum-complete-transaction && package-cleanup --dupes && ackage-cleanup --dupes && package-cleanup --problems && yum update -y && yum upgrade -y";
            fi
        elif [[ "$1" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            if [[ "$3" == '0.0.0.0' || "$3" == '127.0.0.1' ]]; then
                sudo pacman -Syy && sudo pacman -Su --noconfirm && yaourt -Syua --noconfirm && yaourt -Syua --devel --noconfirm;
            else
                ssh "root@$3" "pacman -Syy && pacman -Su --noconfirm && yaourt -Syua --noconfirm && yaourt -Syua --devel --noconfirm;";
            fi
        elif [[ "$1" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            if [[ "$3" == '0.0.0.0' || "$3" == '127.0.0.1' ]]; then
                sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo aptitude update -y && sudo aptitude full-upgrade -y && sudo aptitude build-dep && sudo dpkg --configure -a && sudo aptitude build-dep && sudo aptitude install -f;
            else
                ssh "root@$3" "apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && aptitude update -y && aptitude full-upgrade -y && aptitude build-dep && dpkg --configure -a && aptitude build-dep && aptitude install -f;";
            fi
        elif [[ "$1" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$1" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$1" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    else
        if [[ "$1" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            pplsyu; # only works on Archlinux
        else
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    fi
    pause_function "$(gettext -s "UPDATE-SYSTEM-UP") $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
}
#}}}
# -----------------------------------------------------------------------------
# INSTALLED CORE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="installed_core";
    USAGE="$(localize "INSTALLED-CORE-USAGE")";
    DESCRIPTION="$(localize "INSTALLED-CORE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALLED-CORE-USAGE" "installed_core 1->(package-name)" "Comment: installed_core @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALLED-CORE-DESC"  "Installed core" "Comment: installed_core @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
installed_core()
{
    CORE_INSTALL[$[${#CORE_INSTALL[@]}]]="$1"
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    installed_core "core-foo";
    installed_core "core-bar";
fi
#}}}
# -----------------------------------------------------------------------------
# FAILED INSTALL CORE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="failed_install_core";
    USAGE="$(localize "FAILED-INSTALL-CORE-USAGE")";
    DESCRIPTION="$(localize "FAILED-INSTALL-CORE-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "FAILED-INSTALL-CORE-USAGE" "failed-install_core 1->(package-name)" "Comment: failed_install_core @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FAILED-INSTALL-CORE-DESC"  "Failed install core" "Comment: failed_install_core @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
failed_install_core()
{
    FAILED_CORE_INSTALL[$[${#FAILED_CORE_INSTALL[@]}]]="$1";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    failed_install_core "core-food";
    failed_install_core "core-bard";
fi
#}}}
# -----------------------------------------------------------------------------
# INSTALLED AUR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="installed_aur";
    USAGE="$(localize "INSTALLED-AUR-USAGE")";
    DESCRIPTION="$(localize "INSTALLED-AUR-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALLED-AUR-USAGE" "installed_aur 1->(package-name)" "Comment: installed_aur @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALLED-AUR-DESC"  "Installed aur" "Comment: installed_aur @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
installed_aur()
{
    AUR_INSTALL[$[${#AUR_INSTALL[@]}]]="$1";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    installed_aur "aur-foo";
    installed_aur "aur-bar";
fi
#}}}
# -----------------------------------------------------------------------------
# FAILED INSTALL AUR {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="failed_install_aur";
    USAGE="$(localize "FAILED-INSTALL-AUR-USAGE")";
    DESCRIPTION="$(localize "FAILED-INSTALL-AUR-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "FAILED-INSTALL-AUR-USAGE" "failed_install_aur 1->(package-name)" "Comment: failed_install_aur @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "FAILED-INSTALL-AUR-DESC"  "Failed install aur" "Comment: failed_install_aur @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
failed_install_aur()
{
    FAILED_AUR_INSTALL[$[${#FAILED_AUR_INSTALL[@]}]]="$1";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    failed_install_aur "aur-food";
    failed_install_aur "aur-bard";
fi
#}}}
# -----------------------------------------------------------------------------
# CHECK PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="check_package";
    USAGE="$(localize "CHECK-PACKAGE-USAGE")";
    DESCRIPTION="$(localize "CHECK-PACKAGE-DESC")";
    NOTES="$(localize "CHECK-PACKAGE-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CHECK-PACKAGE-USAGE" "check_package 1->(Single-Package-to-Check Or Multiple Packages)" "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-PACKAGE-DESC"  "checks package(s) to see if they are installed." "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-PACKAGE-NOTES" "I have seen this fail for one or more packages that were already install: mate; so I added -Qm for this reason." "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CHECK-PACKAGE-NFCD" "Not Found" "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-PACKAGE-FSSP" "Found" "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CHECK-PACKAGE-FFP"  "Failed to find package" "Comment: check_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
check_package()
{
    refresh_repo;
    if [[ "$My_OS" == "solaris" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_OS" == "aix" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_OS" == "freebsd" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_OS" == "windowsnt" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_OS" == "mac" ]]; then
        print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
    elif [[ "$My_OS" == "linux" ]]; then
        # if there is a need to know which Distro; i.e. CentOS for Redhat, or Ubuntu for Debian, then use My_PSUEDONAME
        # See wizard.sh os_info to see if OS test exist or works
        if [[ "$My_DIST" == "redhat" ]]; then # -------------------------------- Redhat, Centos, Fedora
            if sudo yum list "$1" &> /dev/null ; then        # check if a package is already installed from Core
                return 0;
            else
                return 1;
            fi
        elif [[ "$My_DIST" == "archlinux" ]]; then # --------------------------- My_PSUEDONAME = Archlinux Distros
            # @FIX direct error to null &>
            if ! sudo pacman -Q "$1" &> /dev/null ; then        # check if a package is already installed from Core
                print_warning "CHECK-PACKAGE-NFCD" ": $1";
                if sudo pacman -Ssp "$1" &> /dev/null ; then   # check if a package is already installed from Outside Repository
                    make_dir "${LOG_PATH}/ssp/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    touch "${LOG_PATH}/ssp/${1}.log";
                    sudo pacman -Ssp "$1" > "${LOG_PATH}/ssp/${1}.log";
                    ## The files created need to be hand made, two elements per line; element 0 is package name, second element is a path to look for, if it exist; program should be installed
                    local -i isFound=0;
                    local -i index=0;
                    local -i total="${#PACKAGE_CHECK_FAILURES[*]}";
                    for (( index=0; index<total; index++ )); do
                        if [[ "${PACKAGE_CHECK_FAILURES[$((index))]}" == "$1" ]]; then
                            #echo "total=$total - ${PACKAGE_CHECK_FAILURES[@]} and ${PACKAGE_FAILURES_CHECK[@]}"
                            if is_string_in_file "${LOG_PATH}/ssp/${1}.log" "${PACKAGE_FAILURES_CHECK[$index]}" ; then
                                isFound=1;
                                print_warning "CHECK-PACKAGE-FSSP" ": $1";
                                break
                            else
                                print_error "CHECK-PACKAGE-FFP" ": $1";
                                write_error "CHECK-PACKAGE-FFP" ": $1 -> $FUNCNAME ${White} @ $(basename $BASH_SOURCE) : $LINENO";
                            fi
                        fi
                    done
                    if [[ "$isFound" -eq 1 ]]; then
                        return 0
                    else
                        return 1
                    fi
                else
                    return 1
                fi
            else
                return 0
            fi
        elif [[ "$My_DIST" == "debian" ]]; then # ------------------------------ Debian: My_PSUEDONAME = Ubuntu, LMDE - Distros
            if apt-cache search "$1" &> /dev/null ; then        # check if a package is already installed from Core
                return 0;
            else
                return 1;
            fi
        elif [[ "$My_DIST" == "unitedlinux" ]]; then # ------------------------- My_PSUEDONAME = unitedlinux Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "mandrake" ]]; then # ---------------------------- My_PSUEDONAME = Mandrake Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        elif [[ "$My_DIST" == "suse" ]]; then # -------------------------------- My_PSUEDONAME = Suse Distros
            print_error "DO-INSTALL-DISTRO-UNSUPPORTED";
        fi
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 2 ]]; then
    if check_package "nano" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  check_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  check_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# SET LANGUAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="set_language";
    USAGE="set_language";
    DESCRIPTION="$(localize "SET-LANGUAGE-DESC")";
    NOTES="$(localize "NONE")";
    # af ak ar as ast be bg bn-bd bn-in br bs ca cs csb cy da de el en-gb en-us en-za eo es-ar es-cl es-es es-mx et eu fa ff fi fr fy-nl ga-ie gd gl gu-in he hi-in hr hu hy-am id is it ja kk km kn ko ku lg lij lt lv mai mk ml mr nb-no nl nn-no nso or pa-in pl pt-br pt-pt rm ro ru si sk sl son sq sr sv-se ta ta-lk te th tr uk vi zh-cn zh-tw zu"
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SET-LANGUAGE-DESC"  "Set Language: Used to set Languages for packages" "Comment: set_language @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
set_language()
{
    LANGUAGE="$1";
    # KDE #{{{
    if [[ "$LANGUAGE" == pt_BR || "$LANGUAGE" == en_GB || "$LANGUAGE" == zh_CN ]]; then
        LANGUAGE_KDE="$(to_lower_case "$LANGUAGE")";
    elif [[ "$LANGUAGE" == en_US ]]; then
        LANGUAGE_KDE="en_gb";
    else
        LANGUAGE_KDE="$(echo $LANGUAGE | cut -d\_ -f1)";
    fi
    #}}}
    # FIREFOX #{{{
    if [[ "$LANGUAGE" == pt_BR || "$LANGUAGE" == pt_PT || "$LANGUAGE" == en_GB || "$LANGUAGE" == es_AR || "$LANGUAGE" == es_ES || "$LANGUAGE" == zh_CN ]]; then
        LANGUAGE_FF="$(echo $(to_lower_case "$LANGUAGE") | sed 's/_/-/')";
    elif [[ "$LANGUAGE" == en_US ]]; then
        LANGUAGE_FF="en-us";
        #LANGUAGE_FF="en-gb";
    else
        LANGUAGE_FF="$(echo $LANGUAGE | cut -d\_ -f1)";
    fi
    #}}}
    # HUNSPELL #{{{
    if [[ "$LANGUAGE" == pt_BR ]]; then
        LANGUAGE_HS="$(echo $(to_lower_case "$LANGUAGE") | sed 's/_/-/')";
    elif [[ "$LANGUAGE" == pt_PT ]]; then
        LANGUAGE_HS="pt_pt";
    else
        LANGUAGE_HS="$(echo $LANGUAGE | cut -d\_ -f1)";
    fi
    #}}}
    # ASPELL #{{{
    LANGUAGE_AS="$(echo $LANGUAGE | cut -d\_ -f1)";
    #}}}
    # LIBREOFFICE #{{{
    if [[ "$LANGUAGE" == pt_BR || "$LANGUAGE" == en_GB || "$LANGUAGE" == en_US || "$LANGUAGE" == zh_CN ]]; then
        LANGUAGE_LO="$(echo $LANGUAGE | sed 's/_/-/')";
    else
        LANGUAGE_LO="$(echo $LANGUAGE | cut -d\_ -f1)";
    fi
    #}}}
    # CALLIGRA #{{{
    LANGUAGE_CALLIGRA="${LANGUAGE:0:2}"
    if [[ "$LANGUAGE" == 'pt_br' ]]; then
        LANGUAGE_CALLIGRA='pt_br'; # Portugese
    else
        LANGUAGE_CALLIGRA='pt'; # Brazilian Portugese
    fi
    if [[ "$LANGUAGE" == 'zh_cn' ]]; then
        LANGUAGE_CALLIGRA='zh_cn';  # Simplified Chinese
    else
        LANGUAGE_CALLIGRA='zh_tw';  # Traditional Chinese
    fi
    if [[ "${LANGUAGE:0:2}" == 'en' ]]; then
        LANGUAGE_CALLIGRA='en_gb'; # British
    fi
    #}}}
}
#}}}
# -----------------------------------------------------------------------------
#
# DOWNLOAD AUR REPO PACKAGES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="download_aur_repo_packages";
    USAGE="download_aur_repo_packages";
    DESCRIPTION="$(localize "DOWNLOAD-AUR-REPO-PACKAGES-DESC")";
    NOTES="$(localize "NONE")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-DESC"  "Download AUR Repository Packages: download all AUR Repository Packages into one folder, unarchive them, compile them, and copy package to Custom Package Repo" "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-NO-PACKAGES"          "No packages in download_aur_repo_packages; create Software Configuration first." "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-DOWNLOADING"          "Downloading AUR Repository with" "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-DOWNLOADING-PACKAGE"  "AUR downloading package" "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-PACKAGE-FAIL"         "aur_download_packages Failed to download package" "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DOWNLOAD-AUR-REPO-PACKAGES-COMPLETED"            "Download AUR Repo Packages Completed" "Comment: download_aur_repo_packages @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
download_aur_repo_packages()
{
    AUR_CUSTOM_PACKAGES="${FULL_SCRIPT_PATH}/${AUR_REPO_NAME}"; # if Boot Mode /root/usb/AUR-Packages, if Live Mode /mnt/AUR-Packages
    #
    system_upgrade;
    local all_packages="";
    if [ "${#AUR_PACKAGES}" -gt 0 ]; then
        local -i total="${#AUR_PACKAGES[@]}";
        for (( i=0; i<total; i++ )); do
            all_packages="$all_packages ${AUR_PACKAGES[$i]}";
        done
    else
        print_error "DOWNLOAD-AUR-REPO-PACKAGES-NO-PACKAGES" " : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        abort_install "$RUNTIME_MODE";
    fi
    print_info "DOWNLOAD-AUR-REPO-PACKAGES-DOWNLOADING" ": $all_packages";
    #
    DO_SINGLES=0;
    if [[ "$DO_SINGLES" -eq 1 ]]; then
        for PACKAGE in "$all_packages[@]"; do
            print_info "DOWNLOAD-AUR-REPO-PACKAGES-DOWNLOADING-PACKAGE" ": [${PACKAGE}] -> [${AUR_CUSTOM_PACKAGES}]";
            if ! aur_download_packages "$PACKAGE" ; then
                write_error "DOWNLOAD-AUR-REPO-PACKAGES-PACKAGE-FAIL" ": $PACKAGE : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                print_error "DOWNLOAD-AUR-REPO-PACKAGES-PACKAGE-FAIL" ": $PACKAGE : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "DO_SINGLES : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
            fi
        done
    else
        if ! aur_download_packages "$all_packages" ; then
            write_error "DOWNLOAD-AUR-REPO-PACKAGES-PACKAGE-FAIL" ": $all_packages : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_error "DOWNLOAD-AUR-REPO-PACKAGES-PACKAGE-FAIL" ": $all_packages : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        fi
    fi
    #
    if [[ "$AUR_REPO" -eq 1 ]]; then
        # set before getting here: AUR_REPO_NAME="${MOUNTPOINT}$AUR_REPO_NAME" # /mnt/home/${USERNAME}/aur-packages/
        if [[ "$RUNTIME_MODE" -eq 1 ]]; then
            # AUR_CUSTOM_PACKAGES = Boot Mode /root/usb/AUR-Packages
            copy_files "$AUR_CUSTOM_PACKAGES" " " "${MOUNTPOINT}${MOUNTPOINT}/${AUR_REPO_NAME}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        else
            # AUR_CUSTOM_PACKAGES = Live Mode /mnt/AUR-Packages
            copy_files "$AUR_CUSTOM_PACKAGES" " " "/mnt/${AUR_REPO_NAME}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
    fi
    #
    print_info "DOWNLOAD-AUR-REPO-PACKAGES-COMPLETED";
    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
    return 0;
}
#}}}
# -----------------------------------------------------------------------------
# INSTALL DOWNLOAD {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="install_download";
    USAGE="$(localize "INSTALL-DOWNLOAD-USAGE")";
    DESCRIPTION="$(localize "INSTALL-DOWNLOAD-DESC")";
    NOTES="$(localize "INSTALL-DOWNLOAD-NOTES")";
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "INSTALL-DOWNLOAD-USAGE" "install_download 1->(PACKAGE FROM AUR) 2->(Args: NoConfirm, Force) 3->(Log output)" "Comment: install_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-DOWNLOAD-DESC"  "Install AUR Package using AUR_HELPER" "Comment: install_download @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-DOWNLOAD-NOTES" "Called from add_packagemanager, run in Live Mode: Install one at a time, check to see if its already installed, if fail, try again with confirm.<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: --needed --recursive --force --upgrades" "Comment: install_download @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
install_download()
{
    if [[ "$AUR_REPO" -eq 1 ]]; then
        # package-name-1.0.1-1-x86_64.pkg.tar.xz
        if [[ "$3" -eq 1 ]]; then
            sudo pacman --needed -U "${AUR_CUSTOM_PACKAGES}/${1}/${1}-"*.pkg.tar.xz;
        else
            sudo pacman --needed -U "${AUR_CUSTOM_PACKAGES}/${1}/${1}-"*.pkg.tar.xz 2> "${LOG_PATH}/failures/core/${PACKAGE}.log";
        fi
    else
        if [[ "$3" -eq 1 ]]; then
            su - "${USERNAME}" -c "$AUR_HELPER $2 --needed --force -S $1 2> ${LOG_PATH}/failures/core/${PACKAGE}.log"; # Run as User
        else
            su - "${USERNAME}" -c "$AUR_HELPER $2 --needed -S $1"; # Run as User
        fi
    fi
}
#}}}
# -----------------------------------------------------------------------------
# AUR PACKAGE INSTALL {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="aur_package_install";
    USAGE="$(localize "AUR-PACKAGE-INSTALL-USAGE")";
    DESCRIPTION="$(localize "AUR-PACKAGE-INSTALL-DESC")";
    NOTES="$(localize "AUR-PACKAGE-INSTALL-NOTES")";
    #            : --needed --recursive --force --upgrades
    AUTHOR="helmuthdu and Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "AUR-PACKAGE-INSTALL-USAGE" "aur_package_install 1->(SPACE DELIMITED LIST OF PACKAGES TO INSTALL FROM AUR) 2->(NAME-OF-PACKAGE-MANAGER)" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-DESC"  "Install AUR Package using AUR_HELPER" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-NOTES" "Called from add_packagemanager, run in Live Mode: Install one at a time, check to see if its already installed, if fail, try again with confirm." "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "AUR-PACKAGE-INSTALL-WORKING-ON"     "AUR Package Install" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-TOTAL-INSTALL"  "Total and number for installed is not equal" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-CURRENTLY"      "currently Working on" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-OF"             "of" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-PACKAGES"       "packages" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-INSTALLED"      "Installed" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-FAIL"           "Fails" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-RETRIES"        "retries" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-REFRESH"        "Refreshing" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-ERROR-1"        "Error: Did not install AUR Package" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-ERROR-2"        "Package Manager" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-INTERNET"       "Internet check failed." "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-UPDATE"         "Updating" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-NOT-INSTALLED"  "Package(s) Not Installed" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-COMPLETE"       "AUR Package Manager Completed" "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "AUR-PACKAGE-INSTALL-TRY-AGAIN"      "Try install again"  "Comment: aur_package_install @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
aur_package_install()
{
    if [[ "$REFRESH_AUR" -eq 1 ]]; then
        REFRESH_AUR=0;
        # @FIX Do I need to do different arguments for each AUR Helper?
        su - "${USERNAME}" -c "$AUR_HELPER --noconfirm -Syu"; # Run as User
    fi
    local -i retry_times=0;
    local -i total_packages="$(echo "$1" | wc -w)";
    local -i number_installed=0;
    local -i number_failed=0;
    local -i current=0;
    local PACKAGE="";
    # install package from aur
    for PACKAGE in $1; do
        ((current++));
        if ! check_package "$PACKAGE" ; then # 1. Check pacman database
            AUR_CONFIRM="--noconfirm";
            retry_times=0;
            YN_OPTION=1;
            while [[ "$YN_OPTION" -ne 0 ]]; do
                ((retry_times++));
                print_this "AUR-PACKAGE-INSTALL-WORKING-ON" ": $AUR_HELPER $PACKAGE $(localize "AUR-PACKAGE-INSTALL-CURRENTLY") $current $(localize "AUR-PACKAGE-INSTALL-OF") $total_packages $(localize "AUR-PACKAGE-INSTALL-PACKAGES"), $(localize "AUR-PACKAGE-INSTALL-INSTALLED") $number_installed - $(localize "AUR-PACKAGE-INSTALL-FAILS") $number_failed -> $(localize "AUR-PACKAGE-INSTALL-RETRIES") = ${retry_times}.";
                install_download "${PACKAGE}" "$AUR_CONFIRM" 0;
                # check if the package was not installed
                # some packages do not register, i.e. mate and mate-extras, so this is a work around; so you do not get stuck in a loop @FIX make a list
                if ! check_package "$PACKAGE" ; then # 2. Failed Once, now check in Loop
                    print_error "AUR-PACKAGE-INSTALL-REFRESH" ": $AUR_HELPER $PACKAGE $(localize "AUR-PACKAGE-INSTALL-CURRENTLY") $current $(localize "AUR-PACKAGE-INSTALL-OF") $total_packages $(localize "AUR-PACKAGE-INSTALL-PACKAGES"), $(localize "AUR-PACKAGE-INSTALL-INSTALLED") $number_installed - $(localize "AUR-PACKAGE-INSTALL-FAILS") $number_failed -> $(localize "AUR-PACKAGE-INSTALL-RETRIES") = ${retry_times}.";
                    $AUR_HELPER -Syu;
                    # Manual Intervention may resolve this issue
                    install_download "${PACKAGE}" "$AUR_CONFIRM --force" 0;
                    if ! check_package "$PACKAGE" ; then # 3. Faild Twice, Now lets see if its a Known Failure in pacman
                        # @FIX try to find solution to why this is happening and put it here
                        if [[ "$INSTALL_NO_INTERNET" -eq 0 ]]; then
                            if ! is_internet ; then
                                restart_internet;
                                sleep 13;
                                if ! is_internet ; then
                                    failed_install_core "$PACKAGE";
                                    write_error "AUR-PACKAGE-INSTALL-ERROR-1" ": $AUR_HELPER - $PACKAGE - $(localize "AUR-PACKAGE-INSTALL-ERROR-2"): $2 - $(localize "AUR-PACKAGE-INSTALL-INTERNET") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                    print_error "AUR-PACKAGE-INSTALL-ERROR-1" ": $AUR_HELPER - $PACKAGE - $(localize "AUR-PACKAGE-INSTALL-ERROR-2"): $2 - $(localize "AUR-PACKAGE-INSTALL-INTERNET") : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                    if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
                                    # @FIX what to do now
                                    abort_install "$RUNTIME_MODE";
                                fi
                            fi
                        fi
                        print_this "AUR-PACKAGE-INSTALL-REFRESH" " - $(localize "AUR-PACKAGE-INSTALL-UPDATE"): $AUR_HELPER $PACKAGE $(localize "AUR-PACKAGE-INSTALL-CURRENTLY") $current $(localize "AUR-PACKAGE-INSTALL-OF") $total_packages $(localize "AUR-PACKAGE-INSTALL-PACKAGES"), $(localize "AUR-PACKAGE-INSTALL-INSTALLED") $number_installed - $(localize "AUR-PACKAGE-INSTALL-FAILS") $number_failed -> $(localize "AUR-PACKAGE-INSTALL-RETRIES") = ${retry_times}."
                        su "${USERNAME}" -c "$AUR_HELPER --noconfirm -Syu"; # Run as User
                        # Force install
                        install_download "${PACKAGE}" "$AUR_CONFIRM --force" 0;
                        if ! check_package "$PACKAGE" ; then
                            print_info "AUR-PACKAGE-INSTALL-NOT-INSTALLED" ": $PACKAGE -> $2 - retry_times=$retry_times - AUTOMAN=$AUTOMAN - INSTALL_WIZARD=$INSTALL_WIZARD - BYPASS=$BYPASS"
                            if [[ "$retry_times" -ge 1 ]]; then
                                read_input_yn "AUR-PACKAGE-INSTALL-TRY-AGAIN" " " 0; # Allow Bypass
                            else
                                read_input_yn "AUR-PACKAGE-INSTALL-TRY-AGAIN" " " 1; # Allow Bypass
                            fi
                            if [[ "$YN_OPTION" -eq 0 ]]; then
                                make_dir "${LOG_PATH}/failures/core/" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                                touch "${LOG_PATH}/failures/core/${PACKAGE}.log";
                                install_download "${PACKAGE}" "$AUR_CONFIRM --force" 0;
                                if ! check_package "$PACKAGE" ; then
                                    failed_install_aur "$PACKAGE";
                                fi
                            fi
                        else
                            installed_aur "$PACKAGE";
                            ((number_installed++)); # increment number installed
                            YN_OPTION=0; # Exit Loop
                        fi
                    else
                        installed_aur "$PACKAGE";
                        ((number_installed++)); # increment number installed
                        YN_OPTION=0; # Exit Loop
                    fi
                    # Manual Intervention may resolve this issue
                    AUR_CONFIRM=" ";
                    #sleep 30;
                    #if [[ "$((retry_times))" -gt 3 ]]; then
                    #    write_error "$AUR_HELPER did not install package $PACKAGE" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    #    print_error "$AUR_HELPER did not install package $PACKAGE; Retrying $retry_times of 3 times."
                    #    YN_OPTION=0
                    #fi
                else
                    installed_aur "$PACKAGE";
                    ((number_installed++)); # increment number installed
                    YN_OPTION=0; # Exit Loop
                fi
            done
        else
            installed_aur "$PACKAGE";
            ((number_installed++)); # increment number installed
        fi
    done
    print_this "AUR-PACKAGE-INSTALL-COMPLETE" ": $2";
    if [[ "$number_installed" -eq "$total_packages" ]]; then
        return 0;
    else
        print_error "AUR-PACKAGE-INSTALL-TOTAL-INSTALL" " $total_packages $(localize "AUR-PACKAGE-INSTALL-PACKAGES"), $(localize "AUR-PACKAGE-INSTALL-INSTALLED") $number_installed - $(localize "AUR-PACKAGE-INSTALL-FAILS") $number_failed : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        write_error "AUR-PACKAGE-INSTALL-TOTAL-INSTALL" " $total_packages $(localize "AUR-PACKAGE-INSTALL-PACKAGES"), $(localize "AUR-PACKAGE-INSTALL-INSTALLED") $number_installed - $(localize "AUR-PACKAGE-INSTALL-FAILS") $number_failed : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$DEBUGGING" -eq 1 ]]; then pause_function "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO"; fi
        return 1;
    fi
}
#}}}
# -----------------------------------------------------------------------------
#
# ADD AUR PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_aur_package";
    USAGE="$(localize "ADD-AUR-PACKAGE-USAGE")";
    DESCRIPTION="$(localize "ADD-AUR-PACKAGE-DESC")";
    NOTES="$(localize "ADD-AUR-PACKAGE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-AUR-PACKAGE-USAGE" "add_aur_package 1->(package)" "Comment: add_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-AUR-PACKAGE-DESC"  "Add AUR Package to PACKAGES array; for testing and building cache folder." "Comment: add_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-AUR-PACKAGE-NOTES" "Call per AUR Package Manager" "Comment: add_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "ADD-AUR-PACKAGE-ERROR"  "Wrong Parameters to" "Comment: add_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_aur_package()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$1" ]; then
        print_error "ADD-AUR-PACKAGE-ERROR" " add_aur_package : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        abort_install "$RUNTIME_MODE";
    fi
    CMD="$(rtrim $1)"
    if [[ -z "$CMD" || "$CMD" == "" ]]; then
        return 1;
    fi
    if ! is_in_array "AUR_PACKAGES[@]" "$1" ; then
        if [ "${#AUR_PACKAGES}" -eq 0 ]; then
            AUR_PACKAGES[0]="$1";
        else
            AUR_PACKAGES[${#AUR_PACKAGES[*]}]="$1";
        fi
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    add_aur_package "test package";
    MyTotal="${#AUR_PACKAGES[@]}";
    if [[ "$MyTotal" -eq 1 ]] ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  add_aur_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  add_aur_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# REMOVE AUR PACKAGE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_aur_package";
    USAGE="$(localize "REMOVE-AUR-PACKAGE-USAGE")";
    DESCRIPTION="$(localize "REMOVE-AUR-PACKAGE-DESC")";
    NOTES="$(localize "REMOVE-AUR-PACKAGE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-AUR-PACKAGE-USAGE" "remove_aur_package 1->(package)" "Comment: remove_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-AUR-PACKAGE-DESC"  "Remove AUR Package from PACKAGES array." "Comment: remove_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-AUR-PACKAGE-NOTES" "Call per AUR Package Manager" "Comment: remove_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "REMOVE-AUR-PACKAGE-ERROR"  "Wrong Parameters to" "Comment: remove_aur_package @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_aur_package()
{
    if [[ "$#" -ne "1" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [ -z "$1" ]; then
        print_error "REMOVE-AUR-PACKAGE-ERROR" " : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        abort_install "$RUNTIME_MODE";
    fi
    CMD="$(rtrim $1)";
    if [[ -z "$CMD" || "$CMD" == "" ]]; then
        return 1;
    fi
    if is_in_array "AUR_PACKAGES[@]" "$1" ; then
        remove_from_array "AUR_PACKAGES" "$1";
    fi
    return 0;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    remove_aur_package "test package";
    MyTotal="${#AUR_PACKAGES[@]}";
    if ! is_in_array "AUR_PACKAGES[@]" "test package" ; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  remove_aur_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed}$(gettext -s  "TEST-FUNCTION-FAILED")  remove_aur_package ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s  "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
#}}}
# -----------------------------------------------------------------------------
#
# ADD MODULE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="add_module";
    USAGE="$(localize "ADD-MODULE-USAGE")";
    DESCRIPTION="$(localize "ADD-MODULE-DESC")";
    NOTES="$(localize "ADD-MODULE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "ADD-MODULE-USAGE" "add_module 1->(Name of Module) 2->(Package Manager)" "Comment: add_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-MODULE-DESC"  "Add Module to Package Manager." "Comment: add_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-MODULE-NOTES" "Call per Module" "Comment: add_module @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
add_module()
{
    add_packagemanager "echo \"# Load $1 at boot\" > /etc/modules-load.d/${1}.conf; echo \"${1}\" >> /etc/modules-load.d/${1}.conf; modprobe $1" "$2";
}
#}}}
# -----------------------------------------------------------------------------
#
# REMOVE MODULE {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="remove_module";
    USAGE="$(localize "REMOVE-MODULE-USAGE")";
    DESCRIPTION="$(localize "REMOVE-MODULE-DESC")";
    NOTES="$(localize "REMOVE-MODULE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "REMOVE-MODULE-USAGE" "remove_module 1->(Package Manager)" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-MODULE-DESC"  "Remove Module from Package Manager." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "REMOVE-MODULE-NOTES" "Call per Module" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
remove_module()
{
    remove_packagemanager "$1";
}
#}}}
# -----------------------------------------------------------------------------
# DO PUSH {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="do_push";
    USAGE="$(localize "DO-PUSH-USAGE")";
    DESCRIPTION="$(localize "DO-PUSH-DESC")";
    NOTES="$(localize "DO-PUSH-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="11 Sep 2012";
    REVISION="5 Dec 2012";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "DO-PUSH-USAGE" "do_push 1->(Source-Path) 2->(Destination-Path) 3->(UserName) 4->(IP Address) 5->(Server-Name) 6->(Delete) 7->(Do Push)" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-DESC"  "Do Push Backup during Automated install." "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-NOTES" "" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "DO-PUSH-WORKING" "Working on" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-STORAGE-ERR" "Missing Storage Folder, will an empty create one." "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-RSYNC-PASS" "Folders Synchronized" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-RSYNC-FAILED" "Failed to Synchronize Folders" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-OFFLINE" "Off-Line" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DO-PUSH-CHOWN-FAIL" "Failed to chown" "Comment: do_push @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
do_push()
{
    if [[ "$#" -ne "7" ]]; then echo -e "${BRed}$(gettext -s "WRONG-NUMBER-ARGUMENTS-PASSED-TO") ${BWhite} ${FUNCNAME[1]} @ $(basename ${BASH_SOURCE[1]}) : ${BASH_LINENO[0]}  -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ${White}"; exit 1; fi
    if [[ "$7" -eq 1 ]]; then
        print_this "*************";
        print_this "DO-PUSH-WORKING" "$5";
        if [ ! -d "$1" ]; then
            print_warning "DO-PUSH-STORAGE-ERR" "$1 -> $5 -> $4";
            make_dir "$1" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        fi
        if is_online "$4" ; then
            if [[ "$6" -eq 1 ]]; then
                rsync -av --delete -e ssh -t -t "$1" "root@$4:$2;";
            else
                rsync -av -e ssh -t -t "$1" "root@$4:$2;";
            fi
            if [[ "$?" -eq 0 ]]; then
                print_this "DO-PUSH-RSYNC-PASS" "$5";
                ssh -t -t "root@$4" "chown -R $3:$3 $2;";
                if [[ "$?" -ne 0 ]]; then
                    print_warning "DO-PUSH-CHOWN-FAIL" "$4";
                fi
            else
                print_warning "DO-PUSH-RSYNC-FAILED" "$4";
                write_error "DO-PUSH-RSYNC-FAILED" "$4 $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                return 1;
            fi
        else
            print_warning "DO-PUSH-OFFLINE" "$4";
            write_error "DO-PUSH-OFFLINE" "$4" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            return 1;
        fi
        print_this "*************";
    fi # End Y Push
    return 0;
}
#}}}
# -------------------------------------
if [[ "$RUN_TEST" -eq 2 ]]; then
    if do_push "${FULL_SCRIPT_PATH}/Test/" "$Test_App_Path" "$Test_SSH_User" "$Test_SSH_IP" "$Farm_Name" "0" "1"; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")${BWhite}  do_push ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed}$(gettext -s "TEST-FUNCTION-FAILED")  do_push ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
#
# IS SSH KEYED {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_ssh_keyed";
    USAGE="$(localize "IS-SSH-KEYED-USAGE")";
    DESCRIPTION="$(localize "IS-SSH-KEYED-DESC")";
    NOTES="$(localize "IS-SSH-KEYED-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="16 May 2013";
    REVISION="16 May 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-SSH-KEYED-USAGE" "is_ssh_keyed 1->(ssh User@URL_IP)" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-SSH-KEYED-DESC"  "Checks to see if ssh is keyed and can log in." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-SSH-KEYED-NOTES" "returns 1 for true, 0 false" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_ssh_keyed()
{
    #echo "is_ssh_keyed start";
    if [[ $(ssh -t -t -qo BatchMode=yes "$1" echo 'OK' | grep 'OK' | wc -l) -eq 1 ]]; then
        #echo "is_ssh_keyed end";
        return 0;
    else
        #echo "is_ssh_keyed end";
        return 1;
    fi
}
#}}}
# -----------------------------------------------------------------------------
#
# IS SSH USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="is_ssh_user";
    USAGE="$(localize "IS-SSH-USER-USAGE")";
    DESCRIPTION="$(localize "IS-SSH-USER-DESC")";
    NOTES="$(localize "IS-SSH-USER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="16 May 2013";
    REVISION="16 May 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "IS-SSH-USER-USAGE" "is_ssh_user 1->(ssh User) 2->(ssh URL)" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-SSH-USER-DESC"  "Checks to see if ssh User exist." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-SSH-USER-NOTES" "returns 0 for true, 1 false" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
is_ssh_user()
{
    return $( ssh "root@${2}" "egrep -i "^${1}" /etc/passwd > /dev/null 2>&1; echo \"\$?\";" );
}
#}}}
# -----------------------------------------------------------------------------
#
# CREATE SSH USER {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="create_ssh_user";
    USAGE="$(localize "CREATE-SSH-USER-USAGE")";
    DESCRIPTION="$(localize "CREATE-SSH-USER-DESC")";
    NOTES="$(localize "CREATE-SSH-USER-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="16 May 2013";
    REVISION="16 May 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "CREATE-SSH-USER-USAGE"    "create_ssh_user 1->(ssh USERNAME) 2->(ssh URL or IP address) 3->(ssh User Password) 4->(ssh root Password) 5->(App_Path) 6->(App_Folder)" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-SSH-USER-DESC"     "Create SSH User." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-SSH-USER-NOTES"    "returns 0 for true, 1 false. You should not need root password, using Key which should be installed first." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "CREATE-SSH-USER-PASS"     "Created User" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-SSH-USER-FAIL"     "Failed to Create User" "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-SSH-USER-TYPE-1"   "Create folders for Type 1 Application install." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-SSH-USER-TYPE-1-F" "Failed to Create folders for Type 1 Application install." "Comment: remove_module @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
create_ssh_user()
{
    if [ $( ssh "root@${2}" "egrep -i \"^${1}\" /etc/group > /dev/null 2>&1; echo \"\$?\";" ) -eq 1 ]; then
        if [ $( ssh "root@${2}" "groupadd ${1}; echo \"\$?\";" ) -eq 0 ]; then
            if [ $( ssh "root@${2}" "useradd -m -g ${1} -G ${1},users -s /bin/bash ${1}; echo \"\$?\";" ) -eq 0 ]; then
                echo -e "${3}\n${3}\n" | ssh -t "root@${2}" "passwd $1";
                if [ "$?" -eq 0 ]; then
                    print_this "CREATE-SSH-USER-PASS" "$1";
                else
                    print_error "CREATE-SSH-USER-FAIL" "$1";
                fi
            fi
        fi
    fi
    if [[ "$((Install_Type-1))" -eq 0 ]]; then
        print_this "CREATE-SSH-USER-TYPE-1" "$1 -> ${4}${5}";
        ssh "root@${2}" "mkdir -p Scripts;mkdir -p ${5};mkdir -p ${5}${6};mkdir -p ${5}run;chown -R ${1}:${1} ${5};chmod -R 770 ${5};chmod -R 755 ${5}${6}; if [ -d "${5}run" ]; then exit 0; else exit 1; fi";
        if [ "$?" -ne 0 ]; then # you would have to keep track of each return to truly test for each error; this only shows the last; so I would make that a test
            print_error "CREATE-SSH-USER-TYPE-1-F" "$1";
        fi
        pause_function "$LINENO"
    fi
}
#}}}
# -----------------------------------------------------------------------------
#
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="key_website";
    USAGE="$(localize "KEY-WEBSITE-USAGE")";
    DESCRIPTION="$(localize "KEY-WEBSITE-DESC")";
    NOTES="$(localize "KEY-APP-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="10 Apr 2013";
    REVISION="10 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "KEY-WEBSITE-USAGE"     "key_website 1->(ssh USERNAME) 2->(ssh URL or IP address) 3->(ssh User Password) 4->(ssh root Password) 5->(App_Path) 6->(App_Folder) 7->(Create_User)" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-DESC"      "Key Website will prompt you to create a new key, or use an existing one, then copy it to the site." "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-NOTES"     "Install Key: ssh key." "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "KEY-WEBSITE-LINE-1"    "Key Website for Automated SSH Access." "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-LINE-2"    "You must create an SSH Key once, do not give it a password or phrase for automation, hit enter twice, or enter a password (not recommended), then copy it to account." "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-LINE-3"    "You might be required to type in password for server" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-FAIL"      "ssh-copy failed" "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-PING"      "Can not ping"    "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-PASS"      "ssh Key Passed"  "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-EXIST"     "SSH Key Exist"   "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-COMMENT-P" "commented mesg y in /etc/bashrc."   "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "KEY-WEBSITE-COMMENT-F" "Error commenting mesg y in /etc/bashrc."   "Comment: do_app @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
# 1. ssh-keygen -t rsa
# 2. ssh-copy-id -i ~/.ssh/id_rsa.pub USERNAME@remote_host
# 3. Enter ssh password when prompted; then try to log in using: ssh USERNAME@remote_host (it should not require password)
#
key_website()
{
    #echo "key_website start";
    #
    local -i Is_Ok=0;
    # -------------------------
    # 1->(ssh URL or IP address)
    fix_tty()
    {
        #
        if [[ "$BashRc_Path" != '' ]]; then
            # No use looking for fail, press on if it fails
            sshpass -p "$2" ssh -t -t "root@$1" "BashRcPath=\"${BashRc_Path}\"; [[ -f \"\$BashRcPath\" ]] && [[ \$(egrep -ic 'mesg y' \"\$BashRcPath\") -gt 0 ]] && sed -i 's/^mesg/#mesg/g' \"\$BashRcPath\";"
        fi
    }
    # -------------------------
    # 1->(ssh USERNAME) 2->(ssh URL or IP address) 3->(ssh User Password) 4->(ssh root Password) 5->(App_Path) 6->(App_Folder) 7->(Create_User)
    create_ssh_account()
    {
        # Now test for user
        if is_ssh_user "${1}" "${2}"; then
            print_this "KEY-WEBSITE-PASS" "[${1}@${2}]";
        else
            # Create account
            if [[ "$7" -eq 1 ]]; then
               create_ssh_user "$1" "$2" "$3" "$4" "$5" "$6";
            fi
        fi
    }
    # -------------------------
    # 1->(index)
    get_ssh_public_key()
    {
        if [ -f "${HOME}/.ssh/known_hosts" ]; then
            if ! is_string_in_file "${HOME}/.ssh/known_hosts" "${1}" ; then # look for the key
                ssh-keyscan -t "${SSH_Keygen_Type}" "${1}" 2>&1 >> "${HOME}/.ssh/known_hosts"
            fi
        else
            ssh-keyscan -t "${SSH_Keygen_Type}" "${1}" 2>&1 >> "${HOME}/.ssh/known_hosts"
        fi
    }
    # -------------------------
    if [ ! -f "$HOME/.ssh/id_${SSH_Keygen_Type}.pub" ] ; then # $HOME is /root if su
        print_this "KEY-WEBSITE-LINE-1";
        print_this "KEY-WEBSITE-LINE-2";
        print_this "KEY-WEBSITE-LINE-3";
        pause_function "$(gettext -s 'KEY-WEBSITE-LINE-1')" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        if [[ "$SSH_Keygen_Type" == 'rsa' ]]; then
            ssh-keygen -t rsa;
        else
            ssh-keygen -t dsa;
        fi
        Is_Ok="$?";
    fi
    #
    if is_online "${2}" ; then
        # mkdir -p "${Destination_PATH}/${Destination[$i]}/"
        #echo "ssh-copy-id -i ~/.ssh/id_rsa.pub ${User_Names[$i]}@${Domain_Name}"
        # ssh-copy-id -i ~/.ssh/id_rsa.pub "${Test_SSH_User}@${Test_SSH_IP}"
        # Could not figure out how to do this, so I did it manually
        #echo -e \"yes\n$Passwords\n$Passwords\" | ssh-copy-id -i ~/.ssh/id_rsa.pub "${User_Names[$i]}@${Domain_Name}"
        # expect script
        # Public key ~/.ssh/id_dsa.pub
        # Private key ~/.ssh/id_dsa
        # Install for user
        #
        # Install a root key first
        if is_ssh_keyed "root@${2}"; then
            print_test "KEY-WEBSITE-PASS" "[root@${2}]";
        else
            print_caution "KEY-WEBSITE-FAIL" "root@${2} -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
            print_this "KEY-WEBSITE-LINE-3" ": root@${2}";
            #
            get_ssh_public_key "$2";
            #
            fix_tty "$2" "$4";
            #
            sshpass -p "$4" ssh-copy-id -i "${HOME}/.ssh/id_${SSH_Keygen_Type}.pub" "root@${2}";
            if [[ "$?" -eq 0 ]]; then
                print_test "KEY-WEBSITE-PASS" "root@${2}";
                Is_Ok=0;
            else
                ssh-keygen -R "${2}";    # May have reinstalled VM
                get_ssh_public_key "$2"; # Get new Key
                sshpass -p "$4" ssh-copy-id -i "${HOME}/.ssh/id_${SSH_Keygen_Type}.pub" "root@${2}";
                if [[ "$?" -eq 0 ]]; then
                    Is_Ok=0;
                else
                    print_warning "KEY-WEBSITE-FAIL" "root@${2} [password = $4] [key = ${HOME}/.ssh/id_${SSH_Keygen_Type}.pub] -> $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    write_error "KEY-WEBSITE-FAIL" "root@${2} $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    pause_function "root@${2} : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                    Is_Ok=1;
                fi
            fi
            #
            if [[ "$Is_Ok" -eq 0 ]]; then
                create_ssh_account "$1" "$2" "$3" "$4" "$5" "$6" "$7";

                echo "Here ************************************ $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO ";

            fi
        fi
        # Now Key User
        if is_ssh_keyed "${1}@${2}"; then
            print_test "KEY-WEBSITE-PASS" "[${1}@${2}]";
        else
            #
            create_ssh_account "$1" "$2" "$3" "$4" "$5" "$6" "$7";
            print_caution "KEY-WEBSITE-FAIL" "${HOME}/.ssh/id_${SSH_Keygen_Type}.pub -> ${1}@${2}";
            print_this "KEY-WEBSITE-LINE-3" ": ${1}@${2}";
            sshpass -p "$3" ssh-copy-id -i "${HOME}/.ssh/id_${SSH_Keygen_Type}.pub" "${1}@${2}";
            if [[ "$?" -eq 0 ]]; then
                print_this "KEY-WEBSITE-PASS" "${1}@${2}";
            else
                print_warning "KEY-WEBSITE-FAIL" "${1}@${2}";
                write_error "KEY-WEBSITE-FAIL" "${1}@${2} $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                pause_function "${1}@${2} : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
                Is_Ok=1;
            fi
        fi
    else
        print_warning "KEY-WEBSITE-PING" "${2}";
        write_error "KEY-WEBSITE-PING ${2}" "$FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        pause_function "key_website : $FUNCNAME @ $(basename $BASH_SOURCE) : $LINENO";
        Is_Ok=1;
    fi
    #echo "key_website end";
    return "$Is_Ok";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 2 ]]; then
    #
    if is_ssh_keyed "${Test_SSH_User}@${Test_SSH_IP}"; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_ssh_keyed ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        if key_website "${Test_SSH_User}" "${Test_SSH_IP}" "$Test_SSH_PASSWD" "$Test_SSH_Root_PASSWD" "$Test_App_Path" "$Test_App_Folder" "1"; then
            if is_ssh_keyed "${Test_SSH_User}@${Test_SSH_IP}"; then
                echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  key_website ${White} @ $(basename $BASH_SOURCE) : $LINENO";
            else
                echo -e "\t${BRed}$(gettext -s "TEST-FUNCTION-FAILED")  key_website ${Test_SSH_User}@${Test_SSH_IP} -> ${White} @ $(basename $BASH_SOURCE) : $LINENO";
                read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
            fi
        else
            echo -e "\t${BRed}$(gettext -s "TEST-FUNCTION-FAILED")  key_website ${White} @ $(basename $BASH_SOURCE) : $LINENO";
            read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
        fi
    fi
fi
#}}}
# -----------------------------------------------------------------------------
# UNPACK BOOLS  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="unpack_bools";
    USAGE="$(localize "UNPACK-BOOLS-USAGE")";
    DESCRIPTION="$(localize "UNPACK-BOOLS-DESC")";
    NOTES="$(localize "UNPACK-BOOLS-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "UNPACK-BOOLS-USAGE"  "unpack_bools 1->(Package)" "Comment: unpack_bools @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UNPACK-BOOLS-DESC"   "unpack_bools" "Comment: unpack_bools @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UNPACK-BOOLS-NOTES"  "Format:Install_Apache=0:Install_WittyWizard=1" "Comment: unpack_bools @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
unpack_bools()
{
    local OLD_IFS="$IFS"; IFS=$':'; # Very Important
    local Packed=( $(echo "$1") );
    for x in "${Packed[@]}" ; do
       # Install_Apache=0:Install_WittyWizard=1:Install_PostgreSQL=1:Install_SQlite=1:Install_HaProxy=1:Install_Monit=1:Install_FTP=0:Create_User=1:Create_Key=1:Rsync_Delete_Push=0:Rsync_Delete_Pull=0
       eval "$(string_split "$x" "=" 1)=$(string_split "$x" "=" 2)";
       #echo "$(string_split "$x" "=" 1)=$(string_split "$x" "=" 2)";
       #pause_function "Rsync_Delete_Push=$Rsync_Delete_Push"
    done
    IFS="$OLD_IFS";
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    A=0; B=0; C=0;
    unpack_bools "A=1:B=2:C=3";
    if [[ "$A" -eq '1' && "$B" -eq '2' && "$C" -eq '3' ]]; then # look for this static text
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  unpack_bools ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  unpack_bools ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# UNPACK THIS VAR  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="unpack_this_var";
    USAGE="$(localize "UNPACK-THIS-VAR-USAGE")";
    DESCRIPTION="$(localize "UNPACK-THIS-VAR-DESC")";
    NOTES="$(localize "UNPACK-THIS-VAR-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "UNPACK-THIS-VAR-USAGE"  "unpack_this_var 1->(Packed Parameters) 2->(Var) 3->(Default Value)" "Comment: unpack_this_var @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UNPACK-THIS-VAR-DESC"   "Unpack this Var" "Comment: unpack_this_var @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "UNPACK-THIS-VAR-NOTES"  "Format:Install_Apache=0:Install_WittyWizard=1" "Comment: unpack_this_var @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
unpack_this_var()
{
    local OLD_IFS="$IFS"; IFS=$':'; # Very Important
    local Packed=( $(echo "$1") );
    for x in "${Packed[@]}" ; do
        if [[ "$2" == "$(string_split "$x" "=" 1)" ]]; then
           # Install_Apache=0:Install_WittyWizard=1:Install_PostgreSQL=1:Install_SQlite=1:Install_HaProxy=1:Install_Monit=1:Install_FTP=0:Create_User=1:Create_Key=1:Rsync_Delete_Push=0:Rsync_Delete_Pull=0
           echo "$(string_split "$x" "=" 2)";
           return 0;
        fi
    done
    IFS="$OLD_IFS";
    echo "$3";
    return 1;
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    if [[ "$(unpack_this_var "A=1:B=2:C=3" 'A' '0')" -eq '1' ]]; then # look for this static text
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  unpack_this_var ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  unpack_this_var ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# RANDOM PASSWORD  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="random_password";
    USAGE="$(localize "RANDOM-PASSWORD-USAGE")";
    DESCRIPTION="$(localize "RANDOM-PASSWORD-DESC")";
    NOTES="$(localize "RANDOM-PASSWORD-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "RANDOM-PASSWORD-USAGE"  "random_password 1->(number of characters; defaults to 32) 2->(include special characters; 1 = yes, 0 = no; defaults to 1)" "Comment: random_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RANDOM-PASSWORD-DESC"   "Generate a Random Password" "Comment: random_password @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RANDOM-PASSWORD-NOTES"  "Uses sha256sum" "Comment: random_password @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
random_password()
{
    #local CHAR;
    #[ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]";
    #cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32};
    #echo '';
    date +%s | sha256sum | base64 | head -c "$1" ; echo; # no Special Characters
}
# -----------------------------------------------------------------------------
# SELECT FILE  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="select_file";
    USAGE="$(localize "SELECT-FILE-USAGE")";
    DESCRIPTION="$(localize "SELECT-FILE-DESC")";
    NOTES="$(localize "SELECT-FILE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SELECT-FILE-USAGE"  "select_file 1->(Filter)" "Comment: select_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-FILE-DESC"   "select_file" "Comment: select_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-FILE-NOTES"  "" "Comment: select_file @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "SELECT-FILE-TITLE"  "Load Farm File" "Comment: select_file @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SELECT-FILE-INFO"   "Please choose a Farm File" "Comment: select_file @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
select_file()
{
    MyFile=$(dialog --stdout --title "$(gettext -s "SELECT-FILE-INFO")" --fselect "$1" 21 80);
    if [[ "$?" -eq 0 ]]; then
       echo "$MyFile";
    else
       echo "1";
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 4 ]]; then
    echo -e "\t${BBlue}$(select_file "$(pwd)" ) ${White}";
fi
# -----------------------------------------------------------------------------
# PASSWORD SAFE  {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="password_safe";
    USAGE="$(localize "PASSWORD-SAFE-USAGE")";
    DESCRIPTION="$(localize "PASSWORD-SAFE-DESC")";
    NOTES="$(localize "PASSWORD-SAFE-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="17 Apr 2013";
    REVISION="18 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "PASSWORD-SAFE-USAGE"  "password_safe 1->(Text) 2->(Password) 3->(encrypt or decrypt)" "Comment: password_safe @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PASSWORD-SAFE-DESC"   "Password Safe allows you to send in Text and Password and encrypt or decrypt text using openssl." "Comment: password_safe @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PASSWORD SAFE-NOTES"  "" "Comment: password_safe @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
password_safe()
{
    if [[ "$3" == 'encrypt' ]]; then
        echo -e "$1" | openssl enc -aes-128-cbc -a -salt -pass pass:"$2";
    else
        echo -e "$1" | openssl enc -aes-128-cbc -a -d -salt -pass pass:"$2";
    fi
}
# -------------------------------------
if [[ "$RUN_TEST" -eq 1 ]]; then
    MyString='Abc123456*!@#$%^&d|Password';
    MyReturn=$(password_safe "$MyString" 'MyPassword' 'encrypt' );
    if [[ $(password_safe "$MyReturn" 'MyPassword' 'decrypt' ) == "$MyString" ]]; then
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  password_safe ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  password_safe ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# -----------------------------------------------------------------------------
# *****************************************************************************
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "SCRIPT-ID1" "Arch Linux Wizard Installation Script" "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SCRIPT-ID2" "Versions" "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SCRIPT-ID3" "Last updated" "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    # Menu
    localize_info "Make-Choose" "Make a Choose:" "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    # PROMPT {{{
    localize_info "ENTER-OPTION"  "Enter your Option:" "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ENTER-OPTIONS" "Enter n° of options (ex: 1 2 3 or 1-3 or 1,2,3 d b q r): "  "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    #}}}
    # All others that need to run before function is hit
    localize_info "LOCALIZER-COMPLETED" "Localizer Completed." "Comment: FunctionName @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # create_help
    localize_info "CREATE-HELP-USAGE"   "create_help 1->(NAME of Function.) 2->(USAGE) 3->(DESCRIPTION) 4->(NOTES) 5->(AUTHOR) 6->(VERSION) 7->(CREATED) 8->(REVISION) 9->(Source File and LINENO)" "Comment: create_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-HELP-DESC"    "Create an HTML Help File on the Fly" "Comment: create_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-HELP-NOTES"   "This Allows easy reading and Look up of all Functions in Program.<br />${HELP_TAB}This Function must be first Function all scripts see, so put it at the top of file.<br />${HELP_TAB}You can get as elaborate with help files as you want." "Comment: create_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "CREATE-HELP-WORKING" "Create Help Working" "Comment: create_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-HELP-ERROR"    "Help Array Empty!" "Comment: create_help @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # print_help
    localize_info "PRINT-HELP-DESC"  "Print an HTML Help File on the Fly" "Comment: print_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-HELP-NOTES" "This Allows easy reading and Look up of all Functions in Program." "Comment: print_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-HELP-TITLE" "Arch Wizard Help File Generated on" "Comment: print_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PRINT-HELP-FUNCT" "Function" "Comment: print_help @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # add_leading_char
    localize_info "ADD-LEADING-CHAR-USAGE"   "add_leading_char 1->('String') 2->(Character to add)" "Comment: add_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-LEADING-CHAR-USAGE"   "Given String, returns with trailing char added if it did not existed." "Comment: add_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "ADD-LEADING-CHAR-USAGE"   "Escape * i.e. \*" "Comment: add_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # strip_leading_char
    localize_info "STRIP-LEADING-CHAR-USAGE"   "strip_leading_char 1->('String') 2->(Character to remove)" "Comment: strip_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRIP-LEADING-CHAR-USAGE"   "Given String, returns with leading char removed if it existed." "Comment: strip_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRIP-LEADING-CHAR-USAGE"   "Escape * i.e. \*" "Comment: strip_leading_char @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # strip_trailing_char
    localize_info "STRIP-TRAILING-CHAR-USAGE"   "strip_trailing_char 1->('String') 2->(Character to remove)" "Comment: strip_trailing_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRIP-TRAILING-CHAR-USAGE"   "Given String, returns with trailing char removed if it existed." "Comment: strip_trailing_char @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRIP-TRAILING-CHAR-USAGE"   "Escape * i.e. \*" "Comment: strip_trailing_char @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # string_len
    localize_info "STRING-LEN-USAGE"   "string_len 1->('String')" "Comment: string_len @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-LEN-DESC"    "Given String, returns Length." "Comment: string_len @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-LEN-NOTES"   "Calls C function." "Comment: string_len @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # string_split
    localize_info "STRING-SPLIT-USAGE"   "string_split 1->('String') 2->(delimiter) 3->(First_Half)" "Comment: string_split @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-SPLIT-DESC"    "Split String into half's, returns First Half if 1, if 0 second half." "Comment: string_split @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-SPLIT-NOTES"   "bla@some.com;john@doe.com | path:root" "Comment: string_split @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # string_replace
    localize_info "STRING-REPLACE-USAGE"   "string_replace 1->('String') 2->(Replace) 3->(With this)" "Comment: string_replace @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-REPLACE-DESC"    "Replace String occurrence with something else." "Comment: string_replace @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "STRING-REPLACE-NOTES"   "string_replace ' ' '_' " "Comment: string_replace @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # sub_string
    localize_info "SUB-STRING-USAGE"   "sub_string 1->('String') 2->(Search) 3->(1=Beginning, 2=End, 3=Remove) <- returns in var MyString" "Comment: sub_string @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SUB-STRING-DESC"    "Returns Sub Strings" "Comment: sub_string @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SUB-STRING-NOTES"   "See Run Test examples." "Comment: sub_string @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # pause_function
    localize_info "PAUSE-FUNCTION-USAGE"   "pause_function 1->(Description Debugging Information)" "Comment: pause_function @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PAUSE-FUNCTION-DESC"    "Pause function" "Comment: pause_function @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "PAUSE-FUNCTION-NOTES"   "Localized: Arguments passed in are not Localize, this is used for passing in Function names, that can not be localized; if required: localize before passing in." "Comment: pause_function @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "PRESS-ANY-KEY-CONTINUE" "Press any key to continue" "Comment: pause_function @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # write_error
    localize_info "WRITE-ERROR-USAGE" "write_error 1->(Error) 2->(Debugging Information)" "Comment: write_error @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRITE-ERROR-DESC"  "Write Error to log." "Comment: write_error @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRITE-ERROR-NOTES" "Localized." "Comment: write_error @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "WRITE-ERROR-ARG"   "Wrong Number of Arguments passed to write_error!" "Comment: write_error @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "NOT-FOUND"         "Not Found" "Comment: write_error @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # trim
    localize_info "TRIM-DESC"   "Remove space on Right and Left of string" "Comment: trim @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TRIM-NOTES"  "MY_SPACE=' Left and Right '<br />${HELP_TAB}MY_SPACE=&#36;(trim &#34;&#36;MY_SPACE&#34;)<br />${HELP_TAB}echo &#34;|&#36;(trim &#34;&#36;MY_SPACE&#34;)|&#34;"   "Comment: trim @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LTRIM-NOTES" "MY_SPACE=' Left and Right '<br />${HELP_TAB}MY_SPACE=&#36;(ltrim &#34;&#36;MY_SPACE&#34;)<br />${HELP_TAB}echo &#34;|&#36;(ltrim &#34;&#36;MY_SPACE&#34;)|&#34;" "Comment: trim @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RTRIM-NOTES" "MY_SPACE=' Left and Right '<br />${HELP_TAB}MY_SPACE=&#36;(rtrim &#34;&#36;MY_SPACE&#34;)<br />${HELP_TAB}echo &#34;|&#36;(rtrim &#34;&#36;MY_SPACE&#34;)|&#34;" "Comment: trim @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # ltrim
    localize_info "LEFT-TRIM-DESC"  "Remove space on Left of string" "Comment: ltrim @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # rtrim
    localize_info "RIGHT-TRIM-USAGE" "rtrim 1->(' String to Trim ')" "Comment: rtrim @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "RIGHT-TRIM-DESC"  "Remove space on Right of string" "Comment: rtrim @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # is_in_array
    localize_info "IS-IN-ARRAY-USAGE" "is_in_array 1->(Array{@}) 2->(Search)" "Comment: is_in_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-IN-ARRAY-DESC"  "Is Search in Array{@}; return true (0) if found" "Comment: is_in_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-IN-ARRAY-NOTES" "Use of Global ARR_INDEX can be used in array index: if is_in_array 'Array{@}' 'Search' ; then MyArray{ARR_INDEX}=1 ; fi; much like get_index; which bombs on not found; takes more code to write it." "Comment: is_in_array @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # is_needle_in_haystack
    localize_info "IS-NEEDLE-IN-HAYSTACK-USAGE" "is_needle_in_haystack 1->(Needle to search in Haystack) 2->(Haystack to search in) 3->(Type of Search: 1=Exact, 2=Beginning, 3=End, 4=Middle, 5=Anywhere)" "Comment: is_needle_in_haystack @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-NEEDLE-HAYSTACK-DESC"  "Search for a Needle in the Haystack" "Comment: is_needle_in_haystack @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-NEEDLE-HAYSTACK-NOTES" "None." "Comment: is_needle_in_haystack @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # load_2d_array
    localize_info "LOAD-2D-ARRAY-USAGE"   'Array=( &#36;(load_2d_array 1->(/Path/ArrayName.ext) 2->(0=First Array, 1=Second Array) ) )' "Comment: load_2d_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-2D-ARRAY-DESC"    "Load a saved 2D Array from Disk"                                     "Comment: load_2d_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-2D-ARRAY-NOTES"   "This Function Expects a file, bombs if not found."                   "Comment: load_2d_array @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-2D-ARRAY-MISSING" "Missing File"                                                        "Comment: load_2d_array @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # localize_save
    localize_info "LOCALIZE-SAVE-USAGE" "localize 1->(Localize ID) 2->(Message to Localize) 3->(Print this with no Localization)" "Comment: localize_save @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOCALIZE-SAVE-DESC"  "Localize ID and Message in &#36;{FULL_SCRIPT_PATH}/Localize/en.po file."                 "Comment: localize_save @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOCALIZE-SAVE-NOTES" "Localization Support, function will not overwrite msgid's, delete all files if you want it to create new ones, else its only going to add new ones." "Comment: localize_save @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # localize_info
    localize_info "LOCALIZE-INFO-DESC"  "Localize Info creates the &#36;{FULL_SCRIPT_PATH}/Localize/en.po file used for Localization." "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOCALIZE-INFO-NOTES" "Localized." "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOCALIZE-INFO-USAGE" "localize_info 1->(Localize ID) 2->(Message to Localize) 3->(Comment)" "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "WRONG-NUMBER-ARGUMENTS-PASSED-TO" "Wrong Number of Arguments passed to " "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "IS-STRING-IN-FILE-USAGE" "is_string_in_file 1->(/full-path/file) 2->(search for string)" "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-STRING-IN-FILE-DESC"  "Return true if string is in file." "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "IS-STRING-IN-FILE-NOTES" "Used to test files for Updates." "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "IS-STRING-IN-FILE-FNF" "File Not Found" "Comment: localize_info @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # show_help
    localize_info "SHOW-HELP-INFO-USAGE-1"  "Usage:" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-2"  "./$SCRIPT_NAME &nbsp;&nbsp;   # Run Script in Interactive Mode." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-3"  "./$SCRIPT_NAME -l # Run Localizer" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-4"  "./$SCRIPT_NAME -h # Build Help File, must run -l first." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-5"  "./$SCRIPT_NAME -a # Automatically Run Scripts without Prompts." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-6"  "./$SCRIPT_NAME -t # Run Test in mode 1" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-7"  "./$SCRIPT_NAME -s # Run Special Test in mode 2" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-USAGE-8"  "./$SCRIPT_NAME -x # Run eXtra Test in mode 3" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # debugger
    localize_info "DEBUGGER-USAGE" "debugger 1->(1=On, x=Off)" "Comment: debugger @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DEBUGGER-DESC"  "Add Option: Ran from Task Manager." "Comment: debugger @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "DEBUGGER-NOTES" "None." "Comment: debugger @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # show_help About
    localize_info "SHOW-HELP-INFO-1"  "The Wizard API script was designed to help in writing complex scripts, it handles must of the input and handles common functions." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-2"  "Wizard API:" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-3"  "&nbsp;&nbsp;&nbsp;&nbsp; The Wizard API is the base of the script engine used to write this script, which in itself only writes another script," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-4"  "&nbsp;&nbsp;&nbsp;&nbsp; so this is known as a script engine, whereas the API or Application Programming Interface, is the syntax," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-5"  "&nbsp;&nbsp;&nbsp;&nbsp; which is the parameters sent to the function, as such Documenting all the functions would be a huge undertaking in most projects this size," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-6"  "&nbsp;&nbsp;&nbsp;&nbsp; so I decided to make this script self Documenting, as well as self Localizing, a non-localized script is worthless to the world," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-7"  "&nbsp;&nbsp;&nbsp;&nbsp; in a perfect Society we would all talk the same Language, for me that would be C++, " "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-8"  "&nbsp;&nbsp;&nbsp;&nbsp; so lets just say that no one can agree on what Language to speak in, let alone program in, so even this text needs to be translated," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-9"  "&nbsp;&nbsp;&nbsp;&nbsp; for those that do not read English; and this is static text; so these instructions really need to be in the script itself;" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-10" "&nbsp;&nbsp;&nbsp;&nbsp; which is why its self Documenting; so it can translate that into the language the person reading it can read it in," "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-11" "&nbsp;&nbsp;&nbsp;&nbsp; so that is it for this static file, all other Documentation will be built in." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-12" "&nbsp;&nbsp;&nbsp;&nbsp; Every program ever write should do 3 things, besides running flawlessly:" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-13" "&nbsp;&nbsp;&nbsp;&nbsp; 1. Localized for every language that will be using it." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-14" "&nbsp;&nbsp;&nbsp;&nbsp; 2. Self Documenting." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-15" "&nbsp;&nbsp;&nbsp;&nbsp; 3. Self Testing, ability to run Test and Determine if program is working correctly." "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-16" "" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-17" "" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-18" "" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "SHOW-HELP-INFO-19" "" "Comment: show_help @ $(basename $BASH_SOURCE) : $LINENO";
    # -----------------------------------------------------------------------------
    # Troubleshooting Functions
    localize_info "TEST-FUNCTION-LOADED-FILE" "Loaded File" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-PASSED"      "Test Passed" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-FAILED"      "Test Failed" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-RUN"         "Running Test" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-FNF"         "File Not Found" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-REMOVE"      "Test Removed" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "TEST-FUNCTION-FAIL-REMOVE" "Test Failed to Removed" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "WRONG-NUMBER-OF-ARGUMENTS" "Wrong Number of Arguments" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-MENU-RECOMMENDED"  "Recommended Menu Options" "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "INSTALL-MENU-COMPLETED"    "Completed." "Comment: Troubleshooting-Functions @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -----------------------------------------------------------------------------
show_help()
{
    echo -e "<hr />";
    echo -e "<br />";
    # Usage
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-1")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-2")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-3")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-4")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-5")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-6")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-7")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-USAGE-8")<br />";
    #
    echo '<br />';
    echo -e "$(gettext -s "SHOW-HELP-INFO-1")<br />";
    echo '<br />';
    echo -e "$(gettext -s "SHOW-HELP-INFO-2")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-3")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-4")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-5")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-6")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-7")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-8")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-9")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-10")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-11")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-12")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-13")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-14")<br />";
    echo -e "$(gettext -s "SHOW-HELP-INFO-15")<br />";
}
#}}}
declare TEXT_SCRIPT_ID="$(localize "SCRIPT-ID1"): $SCRIPT_NAME $(localize "SCRIPT-ID2"): $SCRIPT_VERSION $(localize "SCRIPT-ID3"): $LAST_UPDATE";
# -------------------------------------
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "READ-INPUT-OPTIONS-TEST-TITLE" "Test Options Menu." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-TEST-1"  "Test Options." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-TEST-2"  "Option :" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-TEST-3"  "Testing Menu System with Options: " "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-TEST-4"  "Status of Option :" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-TEST-5"  "Menu System Test" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    #
    localize_info "READ-INPUT-OPTIONS-MENU-1"    "Menu 1" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-1-I"         "Menu 1: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-1-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-1-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-1-SB"        "Status Bar Notice Test Menu Item 1" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-2"    "Menu 2" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-2-I"         "Menu 2: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-2-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-2-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-2-SB"        "Status Bar Notice Test Menu Item 2" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-3"    "Menu 3" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-3-I"         "Menu 3: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-3-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-3-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-3-SB"        "Status Bar Notice Test Menu Item 3" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-4"    "Menu 4" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-4-I"         "Menu 4: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-4-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-4-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-4-SB"        "Status Bar Notice Test Menu Item 4" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-5"    "Menu 5" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-5-I"         "Menu 5: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-5-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-5-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-5-SB"        "Status Bar Notice Test Menu Item 5" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-6"    "Menu 6" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-6-I"         "Menu 6: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-6-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-6-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-6-SB"        "Status Bar Notice Test Menu Item 6" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-7"    "Menu 7" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-7-I"         "Menu 7: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-7-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-7-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-7-SB"        "Status Bar Notice Test Menu Item 7" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-8"    "Menu 8" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-8-I"         "Menu 8: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-8-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-8-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-8-SB"        "Status Bar Notice Test Menu Item 8" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-9"    "Menu 9" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-9-I"         "Menu 9: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-9-C"         "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-9-W"         "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-9-SB"        "Status Bar Notice Test Menu Item 9" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-10"   "Menu 10" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-10-I"        "Menu 10: Information." "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-10-C"        "Caution" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-10-W"        "Warning" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "READ-INPUT-OPTIONS-MENU-10-SB"       "Status Bar Notice Test Menu Item 10" "Comment: test_read_input_options @ $(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_TEST" -eq 10 || "$RUN_TEST" -eq 3 ]]; then
    test_read_input_options()
    {
        local -r menu_name="TestMenu";    # You must define Menu Name here
        local Breakable_Key="Q";           # Q=Quit, D=Done, B=Back
        local RecommendedOptions="1-3 4"; # Recommended Options to run in AUTOMAN or INSTALL_WIZARD Mode
        #
        if [[ "$INSTALL_WIZARD" -eq 1 ]]; then
            RecommendedOptions="1,2,3 6 6";
        elif [[ "$AUTOMAN" -eq 1 ]]; then
            RecommendedOptions="1 2 3 7 7";
        fi
        RecommendedOptions="$RecommendedOptions $Breakable_Key";
        #
        OLD_IFS="$IFS"; IFS=$'\n\t'; # Very Important when reading Arrays from files that end with a new line or tab
        local -a Menu_Checks=( $(create_data_array 0 0 ) );
        IFS="$OLD_IFS";
        #
        local Status_Bar_1="READ-INPUT-OPTIONS-TEST-1";
        local Status_Bar_2=": $RecommendedOptions";
        #
        while [[ 1 ]]; do
            #
            print_title "READ-INPUT-OPTIONS-TEST-TITLE";
            print_line;
            print_info "READ-INPUT-OPTIONS-TEST-5";
            print_caution "${Status_Bar_1}" "${Status_Bar_2}";
            #
            local -a Menu_Items=(); local -a Menu_Info=(); RESET_MENU=1; # Reset
            local -i ThisMenuItem=1;
            #
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-1-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-2-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-3-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-4-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-5-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-6-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-7-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-8-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-9-I"  "MenuTheme[@]"; ((ThisMenuItem++));
            add_menu_item "Menu_Checks" "Menu_Items" "Menu_Info" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-C" "READ-INPUT-OPTIONS-MENU-$ThisMenuItem-W" "READ-INPUT-OPTIONS-MENU-10-I" "MenuTheme[@]"; ((ThisMenuItem++));
            #
            print_menu "Menu_Items[@]" "Menu_Info[@]" "$Breakable_Key";
            #
            read_input_options "$RecommendedOptions" "$Breakable_Key";
            RecommendedOptions="" # Clear All previously entered Options so we do not repeat them
            #
            for S_OPT in "${OPTIONS[@]}"; do
                case "$S_OPT" in
                    1)  # Option 1
                        Menu_Checks["$((S_OPT - 1))"]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-${S_OPT-SB}");
                        Status_Bar_2="$S_OPT";
                        ;;
                    2)  # Option 2
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    3)  # Option 3
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    4)  # Option 4
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    5)  # Option 5
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    6)  # Option 6
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    7)  # Option 7
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    8)  # Option 8
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    9)  # Option 9
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                   10)  # Option 10
                        Menu_Checks[$((S_OPT - 1))]=1;
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
                        Status_Bar_1=$(localize "READ-INPUT-OPTIONS-MENU-$S_OPT-SB");
                        Status_Bar_2="$S_OPT";
                        ;;
                    *)  # Not programmed key
                        print_warning "READ-INPUT-OPTIONS-TEST-2" "$S_OPT";
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
    #
    AUTOMAN=1;
    INSTALL_WIZARD=0;
    print_this "READ-INPUT-OPTIONS-TEST-3" "AUTOMAN=$AUTOMAN and INSTALL_WIZARD=$INSTALL_WIZARD";
    test_read_input_options;
    #
    AUTOMAN=0;
    INSTALL_WIZARD=1;
    print_this "READ-INPUT-OPTIONS-TEST-3" "AUTOMAN=$AUTOMAN and INSTALL_WIZARD=$INSTALL_WIZARD";
    test_read_input_options;
    #
    AUTOMAN=0;
    INSTALL_WIZARD=0;
    print_this "READ-INPUT-OPTIONS-TEST-3" "AUTOMAN=$AUTOMAN and INSTALL_WIZARD=$INSTALL_WIZARD";
    test_read_input_options;
fi
# -------------------------------------
# Run Test down here to avoid function calls before they are defined.
if [[ "$RUN_TEST" -eq 1 ]]; then
    HayStack="1 2 3 4 5";
    Needle="1 2 3 4 5"; # 1=Exact     : 1 2 3 4 5
    if $(is_needle_in_haystack "$Needle" "$HayStack" 1) ; then # 1=Exact
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    Needle="1";         # 2=Beginning : 1, 1 2 3 4, 1 2 3, 1 2
    if $(is_needle_in_haystack "$Needle" "$HayStack" 2) ; then # 2=Beginning
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    Needle="5";         # 3=End       : 5, 2 3 4 5, 3 4 5, 4 5
    if $(is_needle_in_haystack "$Needle" "$HayStack" 3) ; then # 3=End
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    Needle="3";         # 4=Middle    : 2 3, 2 3 4, 3 4, 3, 4
    if $(is_needle_in_haystack "$Needle" "$HayStack" 4) ; then # 4=Middle
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    HayStack="1ABS 2ABS 1POS 2POS";
    Needle="ABS POS";       # 5=Anywhere  : 1 5, 5 1, 1 2 3 5, 2 1 3 4 5, ...
    if $(is_needle_in_haystack "$Needle" "$HayStack" 5) ; then # 5=Anywhere
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
    HayStack="1 4 5 12 3 15";
    Needle="1 3";       # 6=Anywhere Exactly  : Not found
    if $(is_needle_in_haystack "$Needle" "$HayStack" 6) ; then # 6=Anywhere Exactly
        echo -e "\t${BBlue}$(gettext -s "TEST-FUNCTION-PASSED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
    else
        echo -e "\t${BRed} $(gettext -s "TEST-FUNCTION-FAILED")  is_needle_in_haystack ${White} @ $(basename $BASH_SOURCE) : $LINENO";
        read -e -sn 1 -p "$(gettext -s "PRESS-ANY-KEY-CONTINUE")";
    fi
fi
# ************************************* END OF SCRIPT *************************
