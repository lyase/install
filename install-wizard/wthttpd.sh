#!/bin/bash
#
# LAST_UPDATE="24 Jun 2014 16:33"
#
# nano -c /home/wittywizard/wthttpd.sh
#
# /home/wittywizard/public_html/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 168.144.134.184 9090
# or
# /home/wittywizard/wthttpd.sh start /home/wittywizard/WittyWizard.wt 8060 a 108.59.251.28
# /home/wittywizard/wthttpd.sh stop  /home/wittywizard/WittyWizard.wt 8060 a 108.59.251.28
#
# service monit stop
# service monit start
# service monit restart
#
# service haproxy stop
# service haproxy start
#
# nano /etc/monit.conf
# Witty Wizard Setup
#check process WittyWizard.wt with pidfile /home/wittywizard./run/WittyWizard.wt-9090.pid
#  start program = "/home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 0.0.0.0 9090" with timeout 60 seconds
#  stop program  = "/home/wittywizard/wthttpd.sh stop  /home/wittywizard/public/WittyWizard.wt 9090"
#  if failed port 9090 protocol http request /monittoken-9090 then restart
#
#check process WittyWizard.wt with pidfile /home/wittywizard./run/WittyWizard.wt-9091.pid
#  start program = "/home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 0.0.0.0 9091" with timeout 60 seconds
#  stop program  = "/home/wittywizard/wthttpd.sh stop  /home/wittywizard/public/WittyWizard.wt 9091"
#  if failed port 9091 protocol http request /monittoken-9091-a then restart
#
# nano /etc/haproxy/haproxy.cfg
#global
#    log 127.0.0.1 local0
#    log 127.0.0.1 local1 notice
#    maxconn 4096
#    user haproxy
#    group haproxy
#    daemon
#
#defaults
#    log           global
#    mode          http
#    option        httplog
#    option        dontlognull
#    retries       3
#    option        redispatch
#    maxconn       10000
#    contimeout    5000
#    clitimeout    50000
#    srvtimeout    50000
#
#frontend wt
#        bind 0.0.0.0:80
#        acl srv1 url_sub wtd=wt-9090
#        acl srv2 url_sub wtd=wt-9091
#        acl srv1_up nbsrv(bck1) gt 0
#        acl srv2_up nbsrv(bck2) gt 0
#        use_backend bck1 if srv1_up srv1
#        use_backend bck2 if srv2_up srv2
#        default_backend bck_lb
#
#backend bck_lb
#        balance roundrobin
#        server srv1 0.0.0.0:9090 track bck1/srv1
#        server srv2 0.0.0.0:9091 track bck2/srv2
#
#backend bck1
#        balance roundrobin
#        server srv1 0.0.0.0:9090 check
#
#backend bck2
#        balance roundrobin
#        server srv2 0.0.0.0:9091 check
#

# Arguments:
# 1 = Command: start stop
# 2 = Application full path and Name
# 3 = Port Number
# 4 = IP Address
# 5 = Type: a=App, s=Static
#
ShowUsage()
{
    echo $"Usage: wthttpd.sh 1->[start] 2->[/path/to/app.wt] 3->[Port#] 4->[Type(a=App, s=Static)] 5->[IP-Address]";
    echo $"Usage: wthttpd.sh 1->[stop]  2->[/path/to/app.wt] 3->[Port#] 4->[Type(a=App, s=Static)] 5->[IP-Address]";
    echo $"Usage: wthttpd.sh {start|stop} 1->[/path/to/app.wt] 2->[IP-Address] 3->[Port#] 4->[Type(a=App, s=Static)] 5->[IP-Address]";
}
#
#if [ $# -lt "5" ]; then
if [ "$#" -ne "5" ]; then
    ShowUsage;
    exit 1;
fi

#
if [ ! -f $2 ]; then
   echo $"Could not locate application: $2";
   exit 1;
fi
#
declare Action=$(basename "$1");
declare ExeName=$(basename "$2");
declare MyPath=$(dirname "$2");
declare Port="$3";
declare TypeThread="$4";
declare IpAddress="$5";
declare DocRoot="./doc_root";
declare AppRoot="./app_root";
declare DeployPath="/ww";
#
case "$Action" in
    'start')
        IpAddress="$5";
        if cd "$MyPath"; then
            touch "monittoken-${Port}-${TypeThread}";
            ulimit -s 1024;
            "./$ExeName" -p "./run/${ExeName}-${Port}-${TypeThread}.pid" --docroot="${DocRoot};./public_html/media" --approot="$AppRoot" --deploy-path="$DeployPath" --http-address="$IpAddress" --http-port="$Port" --session-id-prefix="wt-${Port}-${TypeThread}"  >> "./run/${ExeName}-${Port}-${TypeThread}.log" 2>&1 &
            export jobpid=$!;
            sleep 1;
        fi
        ;;
    'stop')
        if cd "$MyPath"; then
            pid=$( cat "./run/${ExeName}-${Port}-${TypeThread}.pid" );
            if [[ "$pid" =~ ^[0-9]+$ ]] ; then
                kill "$pid";
                sleep 3;
                pid=$( cat "./run/${ExeName}-${Port}-${TypeThread}.pid" );
                if [[ "$pid" =~ ^[0-9]+$ ]] ; then
                    kill -9 "$pid";
                    sleep 1;
                fi
                echo "Removing pid: ./run/${ExeName}-${Port}-${TypeThread}.pid";
                rm -f "./run/${ExeName}-${Port}-${TypeThread}.pid";
            else
                echo "No pid found.";
            fi
        fi
        declare MyPids=$(pidof "./$ExeName");
        for MyPid in ${MyPids[@]}; do
            echo "Searching: ${ExeName}-${MyPid}-${TypeThread} ${IpAddress}";
            pgrep -f "./${ExeName} -p ./run/${ExeName}-${MyPid}-${TypeThread}.pid --docroot=${DocRoot};./public_html/media --approot=$AppRoot --deploy-path=$DeployPath --http-address=${IpAddress} --http-port=${MyPid} --session-id-prefix=wt-${MyPid}-${TypeThread}";
            if [[ "$?" ]]; then
                echo "kill $MyPid";
                kill "$MyPid";    # Ask it
                sleep 1;
                kill -15 "$MyPid" # Be Gracefully
                sleep 1;
                Kill -9  "$MyPid" # By Force
            fi
        done
        ;;
    *)
        ShowUsage;
        exit 1;
esac


