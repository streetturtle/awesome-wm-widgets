#!/usr/bin/python

import imaplib
import email

M=imaplib.IMAP4_SSL("imap.whatever.com", 993)
M.login("username","password")

status, counts = M.status("INBOX","(MESSAGES UNSEEN)")

if status == "OK":
	unread = int(counts[0].split()[4][:-1])
else:
	unread = "N/A" 

print(unread)
