"""API package: exposes a blueprint for the JSON API.

The API modules register endpoints under the `api` blueprint. The package
imports the submodules to register routes on import.
"""

from flask import Blueprint

bp = Blueprint('api', __name__)

from app.api import users, errors, tokens

