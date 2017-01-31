#!/usr/bin/python

import imaplib
import email

M=imaplib.IMAP4_SSL("mail.teenagemutantninjaturtles.com", 993)
M.login("mickey@tmnt.com","cowabunga")

status, counts = M.status("INBOX","(MESSAGES UNSEEN)")

if status == "OK":
	unread = counts[0].split()[4][:-1]
else:
	unread = "N/A" 

print(unread)