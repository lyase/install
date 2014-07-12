#!/bin/bash
echo "Logs" > /home/wittywizard/run/system.log 
echo "*************" >> /home/wittywizard/run/system.log 
echo "dmesg" >> /home/wittywizard/run/system.log 
cat /var/log/dmesg >> /home/wittywizard/run/system.log
echo "*************" >> /home/wittywizard/run/system.log 
echo "messages" >> /home/wittywizard/run/system.log 
cat /var/log/messages >> /home/wittywizard/run/system.log
echo "*************" >> /home/wittywizard/run/system.log 
echo "monit.log" >> /home/wittywizard/run/system.log 
cat /var/log/monit.log >> /home/wittywizard/run/system.log
echo "*************" >> /home/wittywizard/run/system.log 
echo "syslog" >> /home/wittywizard/run/system.log 
cat /var/log/syslog >> /home/wittywizard/run/system.log
echo "*************" >> /home/wittywizard/run/system.log 
echo "postgresql" >> /home/wittywizard/run/system.log 
cat /var/log/postgresql/postgresql-9.1-main.log >> /home/wittywizard/run/system.log
echo "*************" >> /home/wittywizard/run/system.log 
echo "EOF" >> /home/wittywizard/run/system.log 

