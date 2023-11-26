import imaplib
import re
from dotenv import load_dotenv
from pathlib import Path  
import os
path_to_env = Path(__file__).parent / '.env'
load_dotenv(path_to_env)
EMAIL = os.getenv("EMAIL")
PASSWORD = os.getenv("PASSWORD")
if not EMAIL or not PASSWORD:
    print("ERROR:Email or password not set in .env file.")
    exit(0)


M = imaplib.IMAP4_SSL("imap.gmail.com", 993)
M.login(EMAIL, PASSWORD)

status, counts = M.status("INBOX", "(MESSAGES UNSEEN)")

if status == "OK":
    unread = re.search(r"UNSEEN\s(\d+)", counts[0].decode("utf-8")).group(1)
else:
    unread = "N/A"

print(unread)
