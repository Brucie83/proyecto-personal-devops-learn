#!/usr/bin/env python3
"""
Main entry point for the Flask application.
This file creates and runs the Flask app using the application factory pattern.
"""

from app import create_app
import os

# Create the Flask application
app = create_app()

if __name__ == '__main__':
    # Get configuration from environment
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    # Run the application
    app.run(host=host, port=port, debug=debug)
