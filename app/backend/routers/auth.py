from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token
from app import db

auth_bp = Blueprint('auth', __name__, url_prefix='/api')

@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    data = request.get_json()
    
    # Validate required fields
    if not data or not all(k in data for k in ('username', 'email', 'password')):
        return jsonify({'error': 'Faltan campos requeridos'}), 400
    
    # Get User model from current app
    User = current_app.User
    
    # Check if user already exists
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Usuario ya existe'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email ya registrado'}), 400
    
    # Create new user
    user = User(username=data['username'], email=data['email'])
    user.set_password(data['password'])
    
    try:
        db.session.add(user)
        db.session.commit()
        return jsonify({'message': 'Usuario creado exitosamente'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Error al crear usuario'}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticate user and return JWT token"""
    data = request.get_json()
    
    # Validate required fields
    if not data or not all(k in data for k in ('username', 'password')):
        return jsonify({'error': 'Username y password requeridos'}), 400
    
    # Get User model from current app
    User = current_app.User
    
    # Find user and verify password
    user = User.query.filter_by(username=data['username']).first()
    
    if user and user.check_password(data['password']):
        access_token = create_access_token(identity=user.id)
        return jsonify({
            'access_token': access_token,
            'user': user.to_dict()
        })
    
    return jsonify({'error': 'Credenciales inválidas'}), 401
