"""Authentication blueprint package.

This package registers the `auth` blueprint and exposes the routes
that implement user authentication flows.
"""

from flask import Blueprint

bp = Blueprint('auth', __name__)

from app.auth import routes
