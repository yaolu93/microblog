import logging
from logging.handlers import SMTPHandler, RotatingFileHandler
import json
import os
from flask import Flask, request, current_app
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager
from flask_mail import Mail
from flask_moment import Moment
from flask_babel import Babel, lazy_gettext as _l
from elasticsearch import Elasticsearch
from redis import Redis
import rq
from config import Config
from prometheus_client import Counter, Histogram, Gauge
import time
import requests
from threading import Thread


"""
Application factory and extension initialization for the Microblog app.

This module exposes the `create_app` factory used to build Flask
application instances and top-level extension objects (`db`, `migrate`,
`login`, `mail`, `moment`, `babel`). The factory pattern keeps the
application configurable for different environments (dev/test/prod).
"""


def get_locale():
    return request.accept_languages.best_match(current_app.config['LANGUAGES'])


class JSONFormatter(logging.Formatter):
    """Format logs as JSON for Logstash"""
    def format(self, record):
        log_data = {
            'timestamp': self.formatTime(record),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        return json.dumps(log_data)


class LogstashHandler(logging.Handler):
    """Send logs to Logstash via HTTP"""
    def __init__(self, host='logstash', port=9600):
        super().__init__()
        self.url = f"http://{host}:{port}"
    
    def emit(self, record):
        try:
            log_data = json.loads(self.format(record))
            # 异步发送，避免阻塞
            Thread(target=self._send, args=(log_data,), daemon=True).start()
        except Exception:
            self.handleError(record)
    
    def _send(self, log_data):
        try:
            requests.post(self.url, json=log_data, timeout=2)
        except Exception as e:
            print(f"Failed to send log to Logstash: {e}")


db = SQLAlchemy()
migrate = Migrate()
login = LoginManager()
login.login_view = 'auth.login'
login.login_message = _l('Please log in to access this page.')
mail = Mail()
moment = Moment()
babel = Babel()

# Prometheus metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

db_connections = Gauge(
    'db_connections_total',
    'Database connections'
)

redis_connections = Gauge(
    'redis_connections_total',
    'Redis connections'
)

app_info = Gauge(
    'microblog_app_info',
    'Microblog application info',
    ['version']
)


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    login.init_app(app)
    mail.init_app(app)
    moment.init_app(app)
    babel.init_app(app, locale_selector=get_locale)
    app.elasticsearch = Elasticsearch([app.config['ELASTICSEARCH_URL']]) \
        if app.config['ELASTICSEARCH_URL'] else None
    app.redis = Redis.from_url(app.config['REDIS_URL'])
    app.task_queue = rq.Queue('microblog-tasks', connection=app.redis)

    # Setup Prometheus metrics middleware
    @app.before_request
    def before_request():
        request.start_time = time.time()

    @app.after_request
    def after_request(response):
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            http_requests_total.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown',
                status=response.status_code
            ).inc()
            http_request_duration_seconds.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown'
            ).observe(duration)
        return response

    # Register Prometheus metrics endpoint
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    
    @app.route('/metrics')
    def metrics():
        # Update connection metrics
        try:
            db_connections.set(1 if db.engine.pool.checkedout() >= 0 else 0)
        except:
            pass
        
        try:
            redis_connections.set(1 if app.redis.ping() else 0)
        except:
            pass
        
        app_info.labels(version='1.0').set(1)
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

    from app.errors import bp as errors_bp
    app.register_blueprint(errors_bp)

    from app.auth import bp as auth_bp
    app.register_blueprint(auth_bp, url_prefix='/auth')

    from app.main import bp as main_bp
    app.register_blueprint(main_bp)

    from app.cli import bp as cli_bp
    app.register_blueprint(cli_bp)

    from app.api import bp as api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    if not app.debug and not app.testing:
        if app.config['MAIL_SERVER']:
            auth = None
            if app.config['MAIL_USERNAME'] or app.config['MAIL_PASSWORD']:
                auth = (app.config['MAIL_USERNAME'],
                        app.config['MAIL_PASSWORD'])
            secure = None
            if app.config['MAIL_USE_TLS']:
                secure = ()
            mail_handler = SMTPHandler(
                mailhost=(app.config['MAIL_SERVER'], app.config['MAIL_PORT']),
                fromaddr='no-reply@' + app.config['MAIL_SERVER'],
                toaddrs=app.config['ADMINS'], subject='Microblog Failure',
                credentials=auth, secure=secure)
            mail_handler.setLevel(logging.ERROR)
            app.logger.addHandler(mail_handler)

        # Add Logstash handler
        try:
            logstash_handler = LogstashHandler(host='logstash', port=9600)
            logstash_handler.setFormatter(JSONFormatter())
            logstash_handler.setLevel(logging.INFO)
            app.logger.addHandler(logstash_handler)
        except Exception as e:
            print(f"Warning: Could not initialize Logstash handler: {e}")

        if app.config['LOG_TO_STDOUT']:
            stream_handler = logging.StreamHandler()
            stream_handler.setLevel(logging.INFO)
            app.logger.addHandler(stream_handler)
        else:
            if not os.path.exists('logs'):
                os.mkdir('logs')
            file_handler = RotatingFileHandler('logs/microblog.log',
                                               maxBytes=10240, backupCount=10)
            file_handler.setFormatter(logging.Formatter(
                '%(asctime)s %(levelname)s: %(message)s '
                '[in %(pathname)s:%(lineno)d]'))
            file_handler.setLevel(logging.INFO)
            app.logger.addHandler(file_handler)

        app.logger.setLevel(logging.INFO)
        app.logger.info('Microblog startup')

    return app


from app import models
