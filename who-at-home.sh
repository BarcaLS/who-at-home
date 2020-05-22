#!/bin/bash
# who-at-home.sh
#
# Script which allows you to check if specified host is alive and send information about it to server.
# For example it can be used to check which householder is at home or outside the home (and how long) just by specifying his or her cellphone's IP.
# It's designed to be run on your LAN's server and to upload information to external server.
# Logging via keys is necessary.
# Script should be run from cron, e.g. every 1 minute. It runs constantly, can't be run in multiple instances.
# Script may have to be run by root (e.g. when only root can use sockets - necessary for "ping" command).

############
# Settings #
############

LOCAL_USER="user" # local user on this host who can keylessly ssh to SSH_HOST
SSH_HOST="somebody@host.com" # host to connect to
SSH_DIR="/home/user/domains/host.com/public_html/householders" # remote directory to upload status information
SCRIPT_DIR="/volume1/homes/user/scripts/who-at-home" # directory with this script
SENDER="Home <home@host.com>" # sender of e-mail
SENDEMAIL="/home/user/scripts/sendEmail/sendEmail" # path on $SSH_HOST to sendEmail (needed to send e-mail)
SMTP_SERVER="mail.host.com" # SMTP server
SMTP_USER="user@host.com" # SMTP user
SMTP_PASS="password" # SMTP password
CHECK_CMD="ping -c 1 -W 30 \$LOCAL_IP" # command to check host's status, \$LOCAL_IP will be replaced by script with IP to check
# examples:
# arping -I eth0 -c 1 -w 30 \$LOCAL_IP
# ping -c 1 -W 30 \$LOCAL_IP
# traceroute -m 1 \$LOCAL_IP | grep \" ms\"; ( exit \${PIPESTATUS[1]} )
PAUSE="10" # pause in seconds after checking queue of householders
# hosts to check:
# 1) IP address or hostname
# 2) arbitrary name
# 3) e-mail address to send notification about that householder; you can specify more addresses separating them with comas
# 4) IP address or hostname to check if it is at home (notification won't be sent when recipient is at home because he knows best who leaves or enters into that house);
#    typically you'll want to enter here phone belonging to person which e-mail address you precised
# Example: 192.168.66.50 Wife husband@home.com,daughter@home.com husband.phone.home.com
PARAMETERS=(
	192.168.66.50 Wife husband@home.com daughter@home.com husband.phone.home.com
)

#############
# Main Part #
#############

while true; do

    # check if this script is currently running
    NUMBER_OF_THIS_SCRIPTS_RUNNING=`ps aux | grep who-at-home.sh | grep -v grep | grep -v sudo | wc -l`
    if [ "$NUMBER_OF_THIS_SCRIPTS_RUNNING" -gt 2 ]; then
	echo "This script is currently running. Exiting."; exit
    fi

    # function executed when householder appeared or disappeared at home
    appeared_or_disappeared () {
	CURRENT_CHECK_CMD=`echo $CHECK_CMD | sed -e "s/\\$LOCAL_IP/$WHO_CANT_BE_AT_HOME_TO_NOTIFY/g"` # insert $LOCAL_IP instead of LOCAL_IP string
	eval $CURRENT_CHECK_CMD &>/dev/null; AT_HOME=$?
	if [ "$AT_HOME" != "0" ]; then # recipient of notification is away from home (checking)
	    MSG="$LOCAL_NAME $STATUS $DAY $HOUR"
	    CMD="$SENDEMAIL -q -f \"$SENDER\" -t $EMAIL -u \"$MSG\" -m \" \" -s $SMTP_SERVER -o tls=no -o message-charset=utf-8 -xu $SMTP_USER -xp $SMTP_PASS"
		    
	    echo "$WHO_CANT_BE_AT_HOME_TO_NOTIFY is outside the house so I'm sending e-mail to $EMAIL."
	    sudo -u $LOCAL_USER ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -A $SSH_HOST "$CMD" &>/dev/null

	    # save to log and rotate logs to last 1000 lines
	    echo "$DAY $HOUR $LOCAL_NAME $STATUS" >> $SCRIPT_DIR/logs/emails.log
	    TMP=$(tail -n 1000 $SCRIPT_DIR/logs/emails.log)
	    echo "${TMP}" > $SCRIPT_DIR/logs/emails.log
	fi
    }

    NUMBER=${#PARAMETERS[@]}
    NUMBER=`expr $NUMBER - 1`
    COUNTER=-1
    while [ ! "$COUNTER" = "$NUMBER" ]
    do
    	LOCAL_IP="${PARAMETERS[$COUNTER + 1]}"
	LOCAL_NAME="${PARAMETERS[$COUNTER + 2]}"
	EMAIL="${PARAMETERS[$COUNTER + 3]}"
	WHO_CANT_BE_AT_HOME_TO_NOTIFY="${PARAMETERS[$COUNTER + 4]}"

	# checking if alive
	echo -n "Checking $LOCAL_NAME - $LOCAL_IP. Status: "
		
	CURRENT_CHECK_CMD=`echo $CHECK_CMD | sed -e "s/\\$LOCAL_IP/\$LOCAL_IP/g"` # insert $LOCAL_IP instead of LOCAL_IP string
	eval $CURRENT_CHECK_CMD &>/dev/null; STATE=$?
	if [ "$STATE" != "0" ]; then STATE=1; fi # command results 1 if host is down and 0 if host is up
	echo "$STATE"
	
	# getting and saving current data
	DAY=`date +"%Y-%m-%d"`
	HOUR=`date +"%H:%M:%S"`
	echo "$DAY $HOUR $STATE" >> $SCRIPT_DIR/logs/$LOCAL_NAME.log
	
	# rotate logs to last 1000 lines
	TMP=$(tail -n 10000 $SCRIPT_DIR/logs/$LOCAL_NAME.log)
	echo "${TMP}" > $SCRIPT_DIR/logs/$LOCAL_NAME.log
	
	# reading last 12 lines of data
	tail -n 12 $SCRIPT_DIR/logs/$LOCAL_NAME.log > $SCRIPT_DIR/logs/tmp.log
	LINE=1
	while read -r DAY_TMP HOUR_TMP STATE_LAST; do
    	    case "$LINE" in
		1)  STATE_LAST1=$STATE_LAST;
		    ;;
		2)  STATE_LAST2=$STATE_LAST
    		    ;;
    		3)  STATE_LAST3=$STATE_LAST
    		    ;;
    		4)  STATE_LAST4=$STATE_LAST
    		    ;;
		5)  STATE_LAST5=$STATE_LAST
		    ;;
		6)  STATE_LAST6=$STATE_LAST
		    ;;
		7)  STATE_LAST7=$STATE_LAST
		    ;;
		8)  STATE_LAST8=$STATE_LAST
		    ;;
	        9)  STATE_LAST9=$STATE_LAST
		    ;;
		10) STATE_LAST10=$STATE_LAST
		    ;;
		11) STATE_LAST11=$STATE_LAST
	    	    ;;
		12) STATE_LAST12=$STATE_LAST
		    ;;
	    esac
	    (( LINE ++ ))
	done < $SCRIPT_DIR/logs/tmp.log
	
	# householder has appeared or disappeared		
	CHANGE=""
	if [[ "$STATE_LAST1$STATE_LAST2$STATE_LAST3$STATE_LAST4$STATE_LAST5$STATE_LAST6$STATE_LAST7$STATE_LAST8$STATE_LAST9$STATE_LAST10$STATE_LAST11$STATE_LAST12" =~ 111111111110 ]]; then STATUS="w domu"; appeared_or_disappeared; fi
	if [[ "$STATE_LAST1$STATE_LAST2$STATE_LAST3$STATE_LAST4$STATE_LAST5$STATE_LAST6$STATE_LAST7$STATE_LAST8$STATE_LAST9$STATE_LAST10$STATE_LAST11$STATE_LAST12" =~ 011111111111 ]]; then STATUS="poza domem"; appeared_or_disappeared; fi

	# updating current status on remote server (but only once every minute - due to ssh logs capacity on remote server)
	# householder is in the house if his status was 0 at least one time in last probes (variable STATE)
	SECOND=`date +"%S"`
	if [ "$SECOND" = "00" ] || [ "$SECOND" == "01" ] || [ "$SECOND" == "02" ] || [ "$SECOND" == "03" ]; then # it's 00, 01, 02 or 03 seconds of every minute so we can update current status on remote server
	    if [[ "$STATE_LAST1$STATE_LAST2$STATE_LAST3$STATE_LAST4$STATE_LAST5$STATE_LAST6$STATE_LAST7$STATE_LAST8$STATE_LAST9$STATE_LAST10$STATE_LAST11$STATE_LAST12" =~ 0 ]]; then STATE="0"; else STATE="1"; fi
	    DATA_UNIX=`date +%s`
	    TEXT='<?php \$data_unix = \"'$DATA_UNIX'\"; \$state = \"'$STATE'\"; ?>'
	    echo "Updating $LOCAL_NAME's status on remote server."
	    sudo -u $LOCAL_USER ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -A $SSH_HOST "echo \"$TEXT\" > $SSH_DIR/$LOCAL_NAME.log" &>/dev/null
	fi
	
	# next iteration
	COUNTER=`expr $COUNTER + 4`
    done
    
    # pause
    echo "Queue done. Sleeping $PAUSE seconds."
    sleep $PAUSE

done
