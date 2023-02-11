#!/usr/bin/env python3
import imaplib
import email
from email.header import decode_header
from email.header import make_header
import uuid
import subprocess
import os
import logging
import re
import datetime
import traceback

# login username
username = "frapposelli@vmware.com"
# login password (using keyring to save credentials)
password = "foobar"
imap_server = "localhost"
imap_port = 1143
# get current year (my mailboxes are year-based)
year = datetime.datetime.now().date().strftime("%Y")
# DT database name
database = "Mail"
# group in DT database
group = "/" + year
# current path of this script
script_path = os.path.dirname(__file__)

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

try:
	mail = imaplib.IMAP4(imap_server,imap_port)
	mail.login(username,password)

	count = 0
	
	for mailbox_name in ["Inbox", "Sent"]:

		uid_filename = os.path.join(script_path, ".uid." + mailbox_name)
		
		if not os.path.exists(uid_filename):
			uid_file = open(uid_filename, "w")
			a = uid_file.write("1 1")
			uid_file.close()

		logging.info("Reading UID validity file...")

		uid_file = open(uid_filename, "r")
		uid_line = uid_file.readline().split(" ")

		uidnext_prev = int(uid_line[0])
		uidvalidity_prev = int(uid_line[1])

		logging.info("fetching status from mail...")

		status = mail.status(mailbox_name, '(UIDNEXT UIDVALIDITY)')
		logging.info("status dump: %s", status)
		if status[0] == "OK":
			uidnext_now = int(re.search(r"UIDNEXT (\d*)",str(status[1][0].decode())).group(1))
			uidvalidity_now = int(re.search(r"UIDVALIDITY (\d*)",str(status[1][0].decode())).group(1))

			if not (uidvalidity_prev == uidvalidity_now):
				exit("UIDVALIDITY of " + mailbox_name + " has changed - stopping")
		else:
			exit("Can't get mailbox status of " + mailbox_name)

		logging.info("checking if uidnext_now is > uidnext_prev. is %s > %s ?", uidnext_now, uidnext_prev)

		if uidnext_now > uidnext_prev:
			logging.info("downloading message and storing...")
			mail.select(mailbox_name,True)
			type, data = mail.search(None, 'UID ' + str(uidnext_prev) + ':*')
			id_list = data[0].split()
			for num in id_list:
				resp, data = mail.fetch(num, '(RFC822)')
				raw_email = data[0][1]
				raw_email_string = raw_email.decode('utf-8')
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


					subject = str(make_header(decode_header(msg['subject']))).replace("\\n", "")
					logging.info("Downloading %s",subject)
					count = count + 1

					os.remove(filename)

			uid_file = open(uid_filename, "w")
			a = uid_file.write(str(uidnext_now) + " " + str(uidvalidity_now))
			uid_file.close()
			mail.close()

	if count > 0:
		logging.info("Downloaded %s messages",count)

	mail.logout()


except Exception as e:
	traceback.print_exc()
	print (str(e))
