from threading import Thread
import time
import smtplib
from flask import current_app
from flask_mail import Message
from app import mail


def send_async_email(app, msg):
    """Send an email using Flask-Mail inside the given app context.

    Use an explicit connection and log exceptions so background threads
    don't silently die (common with SMTP connection errors).
    """
    with app.app_context():
        # Retry a few times for transient SMTP failures (network hiccups,
        # temporary SMTP server disconnects). This makes background tasks
        # more robust in development when using lightweight SMTP servers.
        max_attempts = 3
        for attempt in range(1, max_attempts + 1):
            try:
                with mail.connect() as conn:
                    conn.send(msg)
                return
            except (smtplib.SMTPServerDisconnected, smtplib.SMTPException):
                app.logger.exception("SMTP error sending email (attempt %s/%s)", attempt, max_attempts)
            except Exception:
                app.logger.exception("Unexpected error sending email (attempt %s/%s)", attempt, max_attempts)

            if attempt < max_attempts:
                # short backoff before retrying
                time.sleep(0.5 * attempt)

        app.logger.error("All attempts to send email failed; giving up")


def send_email(subject, sender, recipients, text_body, html_body,
               attachments=None, sync=False):
    msg = Message(subject, sender=sender, recipients=recipients)
    msg.body = text_body
    msg.html = html_body
    if attachments:
        for attachment in attachments:
            msg.attach(*attachment)
    if sync:
        try:
            mail.send(msg)
        except Exception:
            current_app.logger.exception("Failed to send email (sync)")
    else:
        # Spawn a background thread to send email so web requests are not
        # blocked. Thread is daemon so it won't prevent process shutdown.
        Thread(target=send_async_email,
               args=(current_app._get_current_object(), msg),
               daemon=True).start()
