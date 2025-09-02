from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import config
import os

# Initialize extensions
db = SQLAlchemy()
jwt = JWTManager()
cors = CORS()

def create_app(config_name=None):
    """Application factory pattern"""
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'default')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Initialize extensions with app
    db.init_app(app)
    jwt.init_app(app)
    cors.init_app(app)
    
    # Register blueprints
    from routers.auth import auth_bp
    from routers.tasks import tasks_bp
    from routers.monitoring import monitoring_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(tasks_bp)
    app.register_blueprint(monitoring_bp)
    
    # Create database tables and register models
    with app.app_context():
        # Import and create models using factory functions
        from models.user import create_user_model
        from models.task import create_task_model
        
        # Create model classes and register them globally
        User = create_user_model(db)
        Task = create_task_model(db)
        
        # Make models available globally for routers
        app.User = User
        app.Task = Task
        
        db.create_all()
    
    return app

