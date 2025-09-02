from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from datetime import datetime

tasks_bp = Blueprint('tasks', __name__, url_prefix='/api')

@tasks_bp.route('/tasks', methods=['GET'])
@jwt_required()
def get_tasks():
    """Get all tasks for the authenticated user"""
    user_id = get_jwt_identity()
    Task = current_app.Task
    tasks = Task.query.filter_by(user_id=user_id).all()
    return jsonify([task.to_dict() for task in tasks])

@tasks_bp.route('/tasks', methods=['POST'])
@jwt_required()
def create_task():
    """Create a new task for the authenticated user"""
    user_id = get_jwt_identity()
    data = request.get_json()
    
    # Validate required fields
    if not data or 'title' not in data:
        return jsonify({'error': 'Title es requerido'}), 400
    
    # Get Task model from current app
    Task = current_app.Task
    
    # Validate priority
    valid_priorities = ['low', 'medium', 'high']
    priority = data.get('priority', 'medium')
    if priority not in valid_priorities:
        return jsonify({'error': 'Prioridad inválida'}), 400
    
    # Create new task
    task = Task(
        title=data['title'],
        description=data.get('description', ''),
        priority=priority,
        user_id=user_id
    )
    
    try:
        db.session.add(task)
        db.session.commit()
        return jsonify(task.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Error al crear tarea'}), 500

@tasks_bp.route('/tasks/<int:task_id>', methods=['PUT'])
@jwt_required()
def update_task(task_id):
    """Update a task for the authenticated user"""
    user_id = get_jwt_identity()
    Task = current_app.Task
    task = Task.query.filter_by(id=task_id, user_id=user_id).first()
    
    if not task:
        return jsonify({'error': 'Tarea no encontrada'}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Datos requeridos'}), 400
    
    # Validate priority if provided
    if 'priority' in data:
        valid_priorities = ['low', 'medium', 'high']
        if data['priority'] not in valid_priorities:
            return jsonify({'error': 'Prioridad inválida'}), 400
    
    # Update task fields
    task.title = data.get('title', task.title)
    task.description = data.get('description', task.description)
    task.completed = data.get('completed', task.completed)
    task.priority = data.get('priority', task.priority)
    task.updated_at = datetime.utcnow()
    
    try:
        db.session.commit()
        return jsonify(task.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Error al actualizar tarea'}), 500

@tasks_bp.route('/tasks/<int:task_id>', methods=['DELETE'])
@jwt_required()
def delete_task(task_id):
    """Delete a task for the authenticated user"""
    user_id = get_jwt_identity()
    Task = current_app.Task
    task = Task.query.filter_by(id=task_id, user_id=user_id).first()
    
    if not task:
        return jsonify({'error': 'Tarea no encontrada'}), 404
    
    try:
        db.session.delete(task)
        db.session.commit()
        return jsonify({'message': 'Tarea eliminada'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Error al eliminar tarea'}), 500
