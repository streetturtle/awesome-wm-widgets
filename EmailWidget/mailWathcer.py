#!/usr/bin/python

import imaplib
import email
import datetime

def process_mailbox(M):
  rv, data = M.search(None, "UNSEEN")
  if rv != 'OK':
      print "No messages found!"
      return

  for num in data[0].split():
      # rv, data = M.fetch(num, '(RFC822)')
      rv, data = M.fetch(num, '(BODY.PEEK[])')
      if rv != 'OK':
          print "ERROR getting message", num
          return

      msg = email.message_from_string(data[0][1])
      print 'From:', msg['From']
      print 'Subject: %s' % (msg['Subject'])
      print 'Raw Date:', msg['Date']
      date_tuple = email.utils.parsedate_tz(msg['Date'])
      if date_tuple:
          local_date = datetime.datetime.fromtimestamp(
              email.utils.mktime_tz(date_tuple))
          print "Local Date:", \
              local_date.strftime("%a, %d %b %Y %H:%M:%S")


M=imaplib.IMAP4_SSL("imap.cern.ch", 993)
M.login("pavel.makhov@cern.ch","cB#h8g!2n")

# status, counts = M.status("INBOX","(MESSAGES UNSEEN)")
# # status, counts = M.status("INBOX/!Edh-team","(MESSAGES UNSEEN)")

# unread = counts[0].split()[4][:-1]

# # print(status) 
# print(unread)
rv, data = M.select("INBOX")
if rv == 'OK':
    print "Processing mailbox...\n"
    process_mailbox(M) # ... do something with emails, see below ...
    M.close()
M.logout()


# M.select("INBOX")
# status, response = M.search('INBOX', '(UNSEEN)')

# unread_msg_nums = response[0].split()

# # Print the count of all unread messages
# print len(unread_msg_nums)

# print 'HEADER:'
# typ, msg_data = M.fetch('1', '(BODY.PEEK[HEADER])')
# for response_part in msg_data:
#   if isinstance(response_part, tuple):
#       print response_part[1]




# da = []
# # for e_id in unread_msg_nums:
# _, response = M.fetch(1, '(BODY.PEEK[TEXT])')
# 	# _, response = M.fetch(e_id, '(UID BODY[TEXT])')
# da.append(response[0][1])
# print da



# typ, data = M.select ("INBOX/!Edh-team")

# status, response = imap.search('INBOX', '(UNSEEN)')

# unread_msg_num = response[0].split()

# Print the count of all unread messages

#print typ
#print data

# for num in data[0].split():
#   typ, data = M.fetch(num, '(RFC822)')
#   print 'Message %s\n%s\n' % (num, data[0][1])

# for response_part in data:
#    if isinstance(response_part, tuple):
#       msg = email.message_from_string(response_part[1])
#       for header in [ 'subject', 'to', 'from' ]:
#          print '%-8s: %s' % (header.upper(), msg[header])



# M.close()
# M.logout()
