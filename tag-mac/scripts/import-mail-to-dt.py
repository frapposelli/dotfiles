#!/opt/homebrew/bin/python3
import email
from email.header import decode_header
from email.header import make_header
import uuid
import subprocess
import sys
import os
import logging
import traceback

# DT database name
database = "VMware"
# group in DT database
group = "/Emails"
# current path of this script
script_path = os.path.dirname(__file__)

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

try:
  raw_email_string = sys.stdin.read()
  msg = email.message_from_string(raw_email_string)
  filename = os.path.join(script_path, str(uuid.uuid4()) + ".eml")
  file = open(filename, "w")
  a = file.write(str(msg))
  file.close()
  
  if os.path.exists(filename):

    script = '''
    tell application id "DNtp"
      if it is running
        set theGroup to create location "{group}" in database "{database}"
        set theRecord to import POSIX path of "{filename}" to theGroup
        set theMetadata to meta data of theRecord
        set theSubject to |kMDItemSubject| of theMetadata
        set name of theRecord to theSubject
        set unread of theRecord to false
        set modification date of theRecord to creation date of theRecord
        -- This does not work in DT 3.8.3 so we use a workaround by
        -- adding an 'import tag' (see calling AppleScript for details)
        --perform smart rule "Mail: replace attachments" record theRecord
        set tags of theRecord to {{"import"}}
      else
        error "DEVONthink not running" number -10000
      end if
    end tell
    '''

    proc = subprocess.Popen(['osascript', '-'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    proc_input = bytes(script.format(group=group,database=database,filename=filename),'utf-8')
    proc.communicate(input=proc_input)

    if not proc.returncode == 0:
      exit("Something went wrong importing the e-mail - is DT running?")	

    os.remove(filename)

except Exception as e:
	traceback.print_exc()
	print (str(e))
