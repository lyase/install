#!/bin/bash
#
#  LAST_UPDATE="29 Apr 2013 16:33"
#
# /home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 168.144.134.184 9090
# or
# /home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 0.0.0.0 9090
# /home/wittywizard/wthttpd.sh stop  /home/wittywizard/public/WittyWizard.wt 9090
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
#check process WittyWizard.wt with pidfile /home/wittywizard/run/WittyWizard.wt-9090.pid
#  start program = "/home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 0.0.0.0 9090" with timeout 60 seconds
#  stop program  = "/home/wittywizard/wthttpd.sh stop  /home/wittywizard/public/WittyWizard.wt 9090"
#  if failed port 9090 protocol http request /monittoken-9090 then restart
#
#check process WittyWizard.wt with pidfile /home/wittywizard/run/WittyWizard.wt-9091.pid
#  start program = "/home/wittywizard/wthttpd.sh start /home/wittywizard/public/WittyWizard.wt 0.0.0.0 9091" with timeout 60 seconds
#  stop program  = "/home/wittywizard/wthttpd.sh stop  /home/wittywizard/public/WittyWizard.wt 9091"
#  if failed port 9091 protocol http request /monittoken-9091 then restart
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
# 3 = IP Address
# 4 = Port
#
if [ $# -lt "2" ]; then
    echo $"Usage: wthttpd.sh {start|stop} /path/to/app.wt ...";
    exit 1;
fi
#
if [ ! -f $2 ]; then
   echo $"Could not locate application: $2";
   exit 1;
fi

declare ExeName="$(basename "$2")";
declare MyPath="$(dirname "$2")";

case "$1" in
    'start')
        if [ "$#" -ne "4" ]; then
            echo $"Usage: wthttpd.sh start /path/to/app.wt IP Port" ;
            exit 1;
        fi
        if cd "$MyPath"; then
            touch "monittoken-$4";
            ulimit -s 1024;
            ./$ExeName -p "../run/${ExeName}-${4}.pid" --docroot . --http-address $3 --http-port $4 --session-id-prefix="wt-${4}"  >> "../run/${ExeName}-${4}.log" 2>&1 &
            # jobpid=$!;
            sleep 1;
        fi
        ;;
    'stop')
        if [ "$#" -ne "3" ]; then
            echo $"Usage: wthttpd.sh stop /path/to/app.wt Port";
            exit 1;
        fi
        if cd "$MyPath"; then
            pid=$( cat "../run/${ExeName}-${3}.pid" );
            if [[ "$pid" =~ ^[0-9]+$ ]] ; then
                kill $pid; 
                sleep 3;
                pid=$( cat "../run/${ExeName}-${3}.pid" );
                if [[ "$pid" =~ ^[0-9]+$ ]] ; then
                    kill -9 $pid;
                    sleep 1;
                fi
            else
                echo "No pid found."
            fi    
        fi
        ;;
    *)
        echo $"Usage: wthttpd.sh {start|stop} /path/to/app.wt ...";
        exit 1;
esac

