#!/usr/bin/env bash
USER="fabio"
GETMAIL_BIN=$(which getmail)

if ! pgrep -l -f davmail.DavGateway; then
        echo "DavMail not running, opening DavMail"
	su - ${USER} -c "JAVA_HOME=$(/usr/libexec/java_home -v 1.8) open -a DavMail.app"
	sleep 10
fi

su - ${USER} -c "${GETMAIL_BIN}"

# Closing DavMail every single time as it leaks memory
echo "Shutting down DavMail"
su - ${USER} -c "osascript -e 'quit app \"DavMail\"'"
