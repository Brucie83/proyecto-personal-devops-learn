from datetime import datetime

def create_task_model(db):
    """Factory function to create Task model with db instance"""
    
    class Task(db.Model):
        __tablename__ = 'tasks'
        
        id = db.Column(db.Integer, primary_key=True)
        title = db.Column(db.String(200), nullable=False)
        description = db.Column(db.Text)
        completed = db.Column(db.Boolean, default=False)
        priority = db.Column(db.String(20), default='medium')
        created_at = db.Column(db.DateTime, default=datetime.utcnow)
        updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
        user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

        def to_dict(self):
            """Convert task to dictionary"""
            return {
                'id': self.id,
                'title': self.title,
                'description': self.description,
                'completed': self.completed,
                'priority': self.priority,
                'created_at': self.created_at.isoformat(),
                'updated_at': self.updated_at.isoformat(),
                'user_id': self.user_id
            }

        def __repr__(self):
            return f'<Task {self.title}>'
    
    return Task
