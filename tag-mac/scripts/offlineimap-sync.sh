#!/usr/bin/env bash
USER="fabio"
OFFLINEIMAP_BIN=$(which offlineimap)

if ! pgrep -l -f davmail.DavGateway; then
        echo "DavMail not running, opening DavMail"
	su - ${USER} -c "JAVA_HOME=$(/usr/libexec/java_home -v 1.8) open -a DavMail.app"
	sleep 10
fi

su - ${USER} -c "${OFFLINEIMAP_BIN} -u basic"

# Closing DavMail every single time as it leaks memory
echo "Shutting down DavMail"
su - ${USER} -c "osascript -e 'quit app \"DavMail\"'"
