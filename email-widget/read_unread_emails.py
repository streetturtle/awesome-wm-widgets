import imaplib
import email
import html2text
import re
from email.header import make_header, decode_header
from pathlib import Path  
import os
from dotenv import load_dotenv

path_to_env = Path(__file__).parent / '.env'
load_dotenv(path_to_env)
EMAIL = os.getenv("EMAIL")
PASSWORD = os.getenv("PASSWORD")

MAX_MSG_COUNT = int(os.getenv("MAX_MSG_COUNT", 5))
MAX_BODY_LENGTH = int(os.getenv("MAX_BODY_LENGTH", 100))

GREEN = "\033[1;32m"
END_COLOR = "\033[0m"

UNSEEN_FLAG = "(UNSEEN)"
BODY_PEEK_FLAG = "(BODY.PEEK[])"
def colorful_text(text, color):
    """
    Function to format text with Pango markup for color.
    """
    return f"<span foreground='{color}'>{text}</span>"

def format_body(body, max_length=MAX_BODY_LENGTH):
    body = body.decode("utf-8", errors="ignore")

    if "DOCTYPE" in body:
        body = html2text.html2text(body)
    body = body.replace("\n", "").replace("\r\n", "").replace(" ", "")
    body = re.sub(r"\[.*\]\(.*\)", "", body)

    return body if len(body) < max_length else body[:max_length] + "..."

def get_short_email_str(M, num_emails=MAX_MSG_COUNT):
    rv, data = M.search(None, UNSEEN_FLAG)
    email_list = list(reversed(data[0].split()))[:num_emails]

    for num in email_list:
        try:
            rv, data = M.fetch(num, BODY_PEEK_FLAG)
            if rv != "OK":
                print("ERROR getting message", num)
                continue

            msg = email.message_from_bytes(data[0][1])

            sender = make_header(decode_header(msg["From"]))
            subject = make_header(decode_header(msg["Subject"]))
            date = make_header(decode_header(msg["Date"]))

            email_info = (
                f"From: {colorful_text(str(sender).replace('<', '').replace('>', ''), 'green')}\n"
                f"Subject: {colorful_text(str(subject), 'red')}\n"
                f"Date: {date}\n"
            )

            if msg.is_multipart():
                for part in msg.walk():
                    content_type = part.get_content_type()
                    content_disposition = str(part.get("Content-Disposition"))

                    if (
                        content_type == "text/plain"
                        and "attachment" not in content_disposition
                    ):
                        body = part.get_payload(decode=True)
                        email_info += format_body(body)
                        break
                    elif (
                        content_type == "text/html"
                        and "attachment" not in content_disposition
                    ):
                        body = part.get_payload(decode=True)
                        body = html2text.html2text(
                            body.decode("utf-8", errors="ignore")
                        )
                        email_info += format_body(body)
                        break
            else:
                body = msg.get_payload(decode=True)
                email_info += format_body(body)

            email_info += "\n" + "=" * 50 + "\n"
            yield email_info

        except Exception:
            print("ERROR  processing message: ", num)

if __name__ == "__main__":
    # Example usage:
    # read_unread_emails.py
    import time
    start = time.time()

    M = imaplib.IMAP4_SSL("imap.gmail.com", 993)
    try:
        M.login(EMAIL, PASSWORD)
        rv, data = M.select("INBOX")

        if rv == "OK":
            for email_str in get_short_email_str(M, MAX_MSG_COUNT):
                print(email_str)
        else:
            print("Error selecting INBOX")
    except Exception:
        print("Error logging in: ", EMAIL)
    finally:
        M.logout()

    print(f"Time taken: {time.time() - start:.2f} seconds")