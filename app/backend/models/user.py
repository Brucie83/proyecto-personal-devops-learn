from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

def create_user_model(db):
    """Factory function to create User model with db instance"""
    
    class User(db.Model):
        __tablename__ = 'users'
        
        id = db.Column(db.Integer, primary_key=True)
        username = db.Column(db.String(80), unique=True, nullable=False)
        email = db.Column(db.String(120), unique=True, nullable=False)
        password_hash = db.Column(db.String(120), nullable=False)
        created_at = db.Column(db.DateTime, default=datetime.utcnow)
        tasks = db.relationship('Task', backref='user', lazy=True, cascade='all, delete-orphan')

        def set_password(self, password):
            """Hash and set password"""
            self.password_hash = generate_password_hash(password)

        def check_password(self, password):
            """Check if provided password matches hash"""
            return check_password_hash(self.password_hash, password)

        def to_dict(self):
            """Convert user to dictionary"""
            return {
                'id': self.id,
                'username': self.username,
                'email': self.email,
                'created_at': self.created_at.isoformat()
            }

        def __repr__(self):
            return f'<User {self.username}>'
    
    return User
