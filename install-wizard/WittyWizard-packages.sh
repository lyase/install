#!/bin/bash
#
# LAST_UPDATE="14 June 2013 16:33"
#
# Software Packages:
# If I declare them here, I can use them in menus
# I could make this multi-distro by putting in if $DISTRO == Arch statements
#
# Boost http://www.boost.org/users/download/
# GraphicsMagick http://www.graphicsmagick.org/
# Moses
# http://www.speech.sri.com/projects/srilm/download.html
#
#
#
#
declare Required_Wizard='';        # Apps required for the Wizard
declare DEV_TOOLS_Install='';      # Development Tools
declare Group_Install='';          # Group Install Package
declare APPS_REQUIRED_Install='';  # Required Applications
declare WT_REQUIRED_Install='';    # Wt Requirements
declare POSTGRESQL_Install='';     # PostgreSQL
declare SQLITE_Install='';         # SQLite
declare MYSQL_Install='';          # MySQL
declare HAPROXY_Install='';        # haproxy
declare HAPROXY_Requirements='';   # haproxy Requirements
declare MONIT_Install='';          # monit
declare APACHE_Install='';         # apache
declare Moses_Install='';          # moses
declare FTP_Install='';            # FTP
declare Yaourt_Install='';         # Yaourt for Pacman
declare Boost_Install='';          # boost
declare Graphics_Install='';       # Graphics
declare PDF_Install='';            # PDF Support Install
declare PDF_Lib='';                # PDF Support Library Repo
declare PDF_Lib_Key='';            # PDF Support Repo key
declare Repo_Extra='';             # Extra Repos: EPEL
declare Repo_Extra_Key='';         # Extra Repos Key
declare Extra_Install='';          # Extra Applications
declare Master_Install='';         # Master Install only
declare Run_This='';               # Run This Command
declare Repo_FTP='';               # FTP Repo
declare BashRc_Path='/etc/bashrc'; # Used to fix tty error
declare Repo_File='';              # File to edit Repository enteries
declare -a My_Distros=('archlinux' 'debian' 'redhat');
#
# Supported Repos Installations
declare -a OS_Distros=('linux:redhat:redhat-centos-fedora:redhat:6' 'linux:redhat:redhat-centos-fedora:redhat:5' 'linux:archlinux:Archlinux:archlinux:0' 'linux:debian:Debian:debian:0' 'linux:debian:Debian:squeeze:0' 'linux:debian:Debian:wheezy:0' 'linux:debian:Debian:lenny:0' 'linux:debian:LMDE:lmde:0' 'linux:debian:Ubuntu:raring:0' 'linux:debian:Ubuntu:quantal:0' 'linux:debian:Ubuntu:precise:0' 'linux:debian:Ubuntu:oneiric:0' 'linux:debian:Ubuntu:lucid:0' 'linux:debian:Ubuntu:hardy:0');
#
# -----------------------------------------------------------------------------
# LOAD PACKAGES {{{
if [[ "$RUN_HELP" -eq 1 ]]; then
    NAME="load_packages";
    USAGE="$(localize "LOAD-PACKAGES-USAGE")";
    DESCRIPTION="$(localize "LOAD-PACKAGES-DESC")";
    NOTES="$(localize "LOAD-PACKAGES-NOTES")";
    AUTHOR="Flesher";
    VERSION="1.0";
    CREATED="26 Apr 2013";
    REVISION="26 Apr 2013";
    create_help "$NAME" "$USAGE" "$DESCRIPTION" "$NOTES" "$AUTHOR" "$VERSION" "$CREATED" "$REVISION" "$(basename $BASH_SOURCE) : $LINENO";
fi
if [[ "$RUN_LOCALIZER" -eq 1 ]]; then
    localize_info "LOAD-PACKAGES-USAGE" "load_packages 1->(Server_OS[@]) 2->(Arch) 3->(Index)"  "Comment: load_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-PACKAGES-DESC"  "Load Packages for Repository Installation." "Comment: load_packages @ $(basename $BASH_SOURCE) : $LINENO";
    localize_info "LOAD-PACKAGES-NOTES" "Value returned in: echo. All strings should not have terminator (;) at end." "Comment: load_packages @ $(basename $BASH_SOURCE) : $LINENO";
fi
# -------------------------------------
function load_packages()
{
    local This_OS="$(string_split "$1" ":" 1)";                  # linux
    local This_Distro="$(string_split "$1" ":" 2)";              # redhat,archlinux,debian
    local This_PSUEDONAME="$(string_split "$1" ":" 3)";          # centos,fedora,Ubuntu,LMDE
    local This_Distro_Version="$(string_split "$1" ":" 4)";      # squeeze,wheezy,lenny,raring,quantal,precise
    local This_Version="$(string_split "$1" ":" 5)";             # 5,6
    # These are the Distrobutions we support...
    if [[ "$This_Distro" == "redhat" ]]; then # ---------------------------------------- Redhat, Centos, Fedora
        #
        DEV_TOOLS_Install='Development Tools'; # see Group Install
        Group_Install='Development Tools';     # Group Install
        Boost_Install='boost boost-devel';
        Graphics_Install='GraphicsMagick GraphicsMagick-devel';
        PDF_Install='libharu libharu-devel';   # install using repo remi
        APPS_REQUIRED_Install="gcc gcc-c++ autoconf automake cmake openssl pango pango-devel libtiff zlib glibc nano gd gd-devel rsync yum-utils bind-utils doxygen $Boost_Install $Graphics_Install";
        WT_REQUIRED_Install='wt wt-devel wt-dbo wt-examples jasper-libs lcms-libs libICE libSM libwmf-lite urw-fonts'; # wt requires fcgi; libwt libwtext libwthttp libwttest not found
        POSTGRESQL_Install='wt-dbo-postgres postgresql-server postgresql-contrib postgresql-devel';
        SQLITE_Install='sqlite';
        MYSQL_Install='mysql-server mysql';
        Required_Wizard='sshpass rsync openssh-server openssh-client';
        HAPROXY_Requirements='socat';
        HAPROXY_Install="haproxy $HAPROXY_Requirements";
        MONIT_Install='monit';
        APACHE_Install='httpd'; # Install or Remove
        Moses_Install='';       # Master only, unless you run Redhat as Master
        # FTP 0=None,1=ProFTP,2=VsFTP,3=Pure-FTP
        if [[ "${FTP_Server[$3]}" -eq 1 ]]; then 
            FTP_Install='vsftpd';            # 
        elif [[ "${FTP_Server[$3]}" -eq 2 ]]; then 
            FTP_Install='proftpd';           # proftpd not in any repo, epel or rpmforge
        elif [[ "${FTP_Server[$3]}" -eq 3 ]]; then 
            FTP_Install='pure-ftpd';         # 
        fi
        Run_This='yum erase -y php-common; yum install yum-complete-transaction';
        BashRc_Path='/etc/bashrc';
        Repo_File='/etc/yum.repos.d/CentOS-Base.repo';
        # Remi for haru repo        
        if [[ "$This_Version" == "5" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                PDF_Lib="rpm -Uvh http://rpms.famillecollet.com/enterprise/5/remi/x86_64/remi-release-5-8.el5.remi.noarch.rpm";  #
                PDF_Lib_Key='rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi';                                       #
            else
                PDF_Lib="rpm -Uvh http://rpms.famillecollet.com/enterprise/5/remi/i386/remi-release-5-8.el5.remi.noarch.rpm";    #
                PDF_Lib_Key='rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi';                                       #
            fi
        elif [[ "$This_Version" == "6" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                PDF_Lib="rpm -Uvh http://rpms.famillecollet.com/enterprise/6/remi/x86_64/remi-release-6-2.el6.remi.noarch.rpm";  #
                PDF_Lib_Key='rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi';                                       #
            else
                PDF_Lib="rpm -Uvh http://rpms.famillecollet.com/enterprise/6/remi/i386/remi-release-6-2.el6.remi.noarch.rpm";    #
                PDF_Lib_Key='rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi';                                       #
            fi
        fi
        # EPEL
        if [[ "$This_Version" == "5" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                Repo_Extra="rpm -Uvh http://download.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm";  #
                Repo_Extra_Key='rpm --import https://fedoraproject.org/static/0608B895.txt; rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms';
            else
                Repo_Extra="rpm -Uvh http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm";    #
                Repo_Extra_Key='rpm --import https://fedoraproject.org/static/0608B895.txt; rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms';
            fi
        elif [[ "$This_Version" == "6" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                Repo_Extra="rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm";  #
                Repo_Extra_Key='rpm --import https://fedoraproject.org/static/0608B895.txt; rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms';
            else
                Repo_Extra="rpm -Uvh http://centos.karan.org/kbsingh-CentOS-Extras.repo";    #
                Repo_Extra_Key='rpm --import https://fedoraproject.org/static/0608B895.txt; rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms';
            fi
        fi
        # RPM FORGE http://wiki.centos.org/AdditionalResources/Repositories/RPMForge
        if [[ "$This_Version" == "5" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                Repo_FTP="rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm";  #
            else
                Repo_FTP="rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.i386.rpm";  #
            fi
        elif [[ "$This_Version" == "6" ]]; then 
            if [[ "$Install_Arch" -eq 1 ]]; then
                Repo_FTP="rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm";  #
            else
                Repo_FTP="rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.i686.rpm";  #
            fi
        fi
        #        
    elif [[ "$This_Distro" == "archlinux" ]]; then # ----------------------------------- Archlinux: This_PSUEDONAME = Archlinux Distros
        #
        DEV_TOOLS_Install='base-devel wget rsync nano gcc autoconf automake cmake clang qt4 net-tools inetutils lshw doxygen';
        Boost_Install='graphicsmagick';
        Graphics_Install='boost boost-libs';
        PDF_Install='libharu';
        HAPROXY_Install='haproxy';            # Currently in AUR
        HAPROXY_Requirements='socat';
        APPS_REQUIRED_Install="openssl pango libtiff zlib glibc gd $Boost_Install $Graphics_Install";
        WT_REQUIRED_Install='wt jasper lcms libice libsm libwmf gsfonts socat';
        POSTGRESQL_Install='postgresql postgresql-libs';
        Required_Wizard='sshpass rsync openssh-server openssh-client';
        SQLITE_Install='sqlite';              #
        MYSQL_Install='mysql';
        MONIT_Install='monit';                #
        APACHE_Install='apache';              # Install or Remove
        Moses_Install='mosesdecoder giza-pp'; # Currently in AUR
        FTP_Install='proftpd';                #
        Yaourt_Install='yaourt';              # AUR Helper
        Run_This='';
        BashRc_Path='/etc/bashrc';
        Repo_File='/etc/pacman.conf';
        #
    elif [[ "$This_Distro" == "debian" ]]; then # -------------------------------------- Debian: This_PSUEDONAME = Ubuntu, LMDE - Distros
        #
        if [[ "$This_PSUEDONAME" == "Debian" ]]; then
            if [[ "$This_Distro_Version" == 'lenny' ]]; then
                Extra_Install='automake libboost-test-dev -t lenny-backports';
            fi
            DEV_TOOLS_Install='build-essential aptitude gtkorphan rsync cmake gcc g++ doxygen';
            Boost_Install='libboost-all-dev libboost-dev libboost-test-dev libboost-program-options-dev libevent-dev automake libtool flex bison pkg-config g++ libssl-dev libboost-date-time-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libboost-system-dev libboost-thread-dev libboost-thread-dev libboost-random-dev libboost-test-dev';
            Graphics_Install='graphicsmagick libgraphicsmagick1-dev libgraphicsmagick3';
            PDF_Install='libhpdf libhpdf-dev';
            APPS_REQUIRED_Install="gcc cmake doxygen openssh-server openssh-client dnsutils $Boost_Install $Graphics_Install";
            WT_REQUIRED_Install='libwt* witty-dbg witty-examples libjasper-dev libjasper-runtime libjasper1 lcms libice libsm libsm-dev libwmf-bin';
            POSTGRESQL_Install='wt-dbo-postgres postgresql postgresql-contrib libpq-dev';
            Master_Install='pgadmin3'; 
            Required_Wizard='sshpass rsync openssh-server openssh-client';
            SQLITE_Install='sqlite'
            MYSQL_Install='mysql';
            HAPROXY_Requirements='socat';
            HAPROXY_Install="haproxy $HAPROXY_Requirements";
            MONIT_Install='monit';
            APACHE_Install='httpd'; # Install or Remove
            #Moses_Install='automake libtool zlib1g-dev libssl-dev csh tcl tcl-dev libelf-dev';
            FTP_Install='proftpd';
            Run_This='';
            BashRc_Path='/etc/bashrc';
            Repo_File='';
            # 
            if [[ "$This_Distro_Version" == "squeeze" ]]; then 
                if [[ "$Install_Arch" -eq 1 ]]; then
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                else
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                fi
                HAPROXY_Install='haproxy -t squeeze-backports-sloppy'; # apt-get install haproxy -t squeeze-backports-sloppy
            elif [[ "$This_Distro_Version" == "wheezy" ]]; then 
                if [[ "$Install_Arch" -eq 1 ]]; then
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                else
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                fi
                HAPROXY_Install='haproxy -t wheezy-backports'; # apt-get install haproxy -t wheezy-backports
            elif [[ "$This_Distro_Version" == "lenny" ]]; then 
                if [[ "$Install_Arch" -eq 1 ]]; then
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                else
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                fi
            elif [[ "$This_Distro_Version" == "sid" ]]; then 
                if [[ "$Install_Arch" -eq 1 ]]; then
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                else
                    Repo_Extra="deb http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0 ./";  #
                    Repo_Extra_Key='wget -O - http://download.opensuse.org/repositories/home:/pgquiles:/Wt/Debian_6.0/Release.key | apt-key add -';
                fi
                HAPROXY_Install='haproxy -t experimental'; # apt-get install haproxy -t experimental
            fi
            #
        elif [[ "$This_PSUEDONAME" == "LMDE" ]]; then # *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            #
            DEV_TOOLS_Install='build-essential aptitude gtkorphan rsync cmake gcc g++ doxygen';
            Boost_Install='libboost-all-dev libboost-dev libboost-test-dev libboost-program-options-dev libevent-dev automake libtool flex bison pkg-config g++ libssl-dev libboost-date-time-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libboost-system-dev libboost-thread-dev libboost-thread-dev libboost-random-dev libboost-test-dev';
            Graphics_Install='graphicsmagick libgraphicsmagick1-dev libgraphicsmagick3';
            PDF_Install='libhpdf libhpdf-dev';
            APPS_REQUIRED_Install="gcc cmake doxygen openssh-server openssh-client dnsutils $Boost_Install $Graphics_Install";
            WT_REQUIRED_Install='libwt* witty-dbg witty-examples libjasper-dev libjasper-runtime libjasper1 lcms libice libsm libsm-dev libwmf-bin';
            POSTGRESQL_Install='wt-dbo-postgres postgresql postgresql-contrib libpq-dev';
            Required_Wizard='sshpass rsync openssh-server openssh-client';
            Master_Install='pgadmin3'; 
            SQLITE_Install='sqlite'
            MYSQL_Install='mysql';
            HAPROXY_Requirements='socat';
            HAPROXY_Install="haproxy $HAPROXY_Requirements";
            MONIT_Install='monit';
            APACHE_Install='httpd'; # Install or Remove
            #Moses_Install='automake libtool zlib1g-dev libssl-dev csh tcl tcl-dev libelf-dev';
            FTP_Install='proftpd';
            Repo_Extra="";  #
            Repo_Extra_Key='';
            Run_This='aptitude purge -y live-boot live-boot-initramfs-tools live-config live-config-sysvinit live-installer';
            BashRc_Path='/etc/bashrc'; # Not required
            Repo_File='';
            #
        elif [[ "$This_PSUEDONAME" == "Ubuntu" ]]; then # *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            # Wt Repo
            if [[ "$This_Distro_Version" == 'raring' ]]; then
                Repo_Extra="deb http://ppa.launchpad.net/pgquiles/wt/ubuntu raring main";  
                Repo_Extra_Key='deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu raring main';
                Extra_Install='';
            elif [[ "$This_Distro_Version" == 'quantal' ]]; then
                Repo_Extra="deb http://ppa.launchpad.net/pgquiles/wt/ubuntu quantal main";  
                Repo_Extra_Key='deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu quantal main';
                Extra_Install='';
            elif [[ "$This_Distro_Version" == 'precise' ]]; then
                # Wt and Qt and gcc
                Repo_Extra="add-apt-repository ppa:pgquiles/wt; apt-add-repository ppa:ubuntu-sdk-team/ppa; add-apt-repository ppa:ubuntu-toolchain-r/test";  # deb http://ppa.launchpad.net/pgquiles/wt/ubuntu precise main
                Repo_Extra_Key=''; # deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu precise main
                Extra_Install='';
            elif [[ "$This_Distro_Version" == 'oneiric' ]]; then
                Repo_Extra="deb http://ppa.launchpad.net/pgquiles/wt/ubuntu oneiric main";  
                Repo_Extra_Key='deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu oneiric main';
                Extra_Install='';
            elif [[ "$This_Distro_Version" == 'lucid' ]]; then
                Repo_Extra="deb http://ppa.launchpad.net/pgquiles/wt/ubuntu lucid main";  
                Repo_Extra_Key='deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu lucid main';
                Extra_Install='';
            elif [[ "$This_Distro_Version" == 'hardy' ]]; then
                Repo_Extra="deb http://ppa.launchpad.net/pgquiles/wt/ubuntu hardy main";  
                Repo_Extra_Key='deb-src http://ppa.launchpad.net/pgquiles/wt/ubuntu hardy main';
                Extra_Install='';
            fi
            #
            Required_Wizard='sshpass rsync openssh-server openssh-client';
            DEV_TOOLS_Install='build-essential aptitude gtkorphan rsync cmake doxygen automake qtdeclarative5-dev qt5-default python-software-properties gcc-4.7 g++-4.7 nano doxygen';
            Boost_Install='libevent-dev libtool flex bison pkg-config libboost-all-dev libboost-dev libboost-test-dev libboost-program-options-dev libssl-dev libboost-date-time-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libboost-system-dev libboost-thread-dev libboost-thread-dev libboost-random-dev libboost-test-dev';
            Graphics_Install='graphicsmagick libgraphicsmagick1-dev libgraphicsmagick3';
            PDF_Install='libhpdf libhpdf-dev';
            APPS_REQUIRED_Install="openssh-server openssh-client dnsutils $Boost_Install $Graphics_Install";
            WT_REQUIRED_Install='witty-dev witty-dbg witty-examples libjasper-dev libjasper-runtime libjasper1 libwmf-bin'; # libwt* lcms libice libsm libsm-dev
            POSTGRESQL_Install='postgresql postgresql-contrib libpq-dev'; # wt-dbo-postgres
            Master_Install='pgadmin3'; 
            SQLITE_Install='sqlite'
            MYSQL_Install='mysql';
            HAPROXY_Requirements='socat';
            HAPROXY_Install="haproxy $HAPROXY_Requirements";
            MONIT_Install='monit sysstat';
            #APACHE_Install='httpd'; # Install or Remove
            APACHE_Install='apache2'; # Install or Remove
            #Moses_Install='automake libtool zlib1g-dev libssl-dev csh tcl tcl-dev libelf-dev';
            FTP_Install='proftpd';
            Run_This='update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 60;update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.7 50';
            BashRc_Path='';
            Repo_File='';
        fi
    fi
}
# ********** End Of Script ****************************************************
