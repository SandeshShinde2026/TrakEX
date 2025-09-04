from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import os
import pandas as pd
from datetime import datetime
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global variable to store the model
model = None

def load_model():
    """Load the trained model"""
    global model
    try:
        model_path = 'models/expense_categorization_model.joblib'
        if os.path.exists(model_path):
            model = joblib.load(model_path)
            logger.info("Model loaded successfully")
            return True
        else:
            logger.error(f"Model file not found at {model_path}")
            return False
    except Exception as e:
        logger.error(f"Error loading model: {e}")
        return False

def preprocess_description(text):
    """Clean and normalize expense descriptions"""
    if pd.isna(text) or text is None:
        return ""
    return str(text).lower().strip()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': model is not None
    })

@app.route('/predict', methods=['POST'])
def predict_category():
    """Predict expense category for a given description"""
    try:
        # Check if model is loaded
        if model is None:
            return jsonify({
                'error': 'Model not loaded',
                'success': False
            }), 500
        
        # Get data from request
        data = request.get_json()
        
        if not data or 'description' not in data:
            return jsonify({
                'error': 'Missing description field',
                'success': False
            }), 400
        
        description = data['description']
        
        # Validate description
        if not description or description.strip() == '':
            return jsonify({
                'error': 'Description cannot be empty',
                'success': False
            }), 400
        
        # Preprocess the description
        cleaned_description = preprocess_description(description)
        
        # Make prediction
        predicted_category = model.predict([cleaned_description])[0]
        
        # Get prediction probabilities for confidence
        probabilities = model.predict_proba([cleaned_description])[0]
        confidence = max(probabilities)
        
        # Get all categories with their probabilities
        categories = model.classes_
        category_probabilities = {
            category: float(prob) for category, prob in zip(categories, probabilities)
        }
        
        # Sort categories by probability
        sorted_categories = sorted(
            category_probabilities.items(), 
            key=lambda x: x[1], 
            reverse=True
        )
        
        response = {
            'success': True,
            'predicted_category': predicted_category,
            'confidence': float(confidence),
            'description': description,
            'cleaned_description': cleaned_description,
            'all_predictions': sorted_categories[:5],  # Top 5 predictions
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Prediction: '{description}' -> {predicted_category} (confidence: {confidence:.3f})")
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in prediction: {e}")
        return jsonify({
            'error': f'Prediction failed: {str(e)}',
            'success': False
        }), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    """Predict categories for multiple descriptions"""
    try:
        if model is None:
            return jsonify({
                'error': 'Model not loaded',
                'success': False
            }), 500
        
        data = request.get_json()
        
        if not data or 'descriptions' not in data:
            return jsonify({
                'error': 'Missing descriptions field',
                'success': False
            }), 400
        
        descriptions = data['descriptions']
        
        if not isinstance(descriptions, list):
            return jsonify({
                'error': 'Descriptions must be a list',
                'success': False
            }), 400
        
        # Process each description
        results = []
        for i, description in enumerate(descriptions):
            try:
                if not description or description.strip() == '':
                    results.append({
                        'index': i,
                        'description': description,
                        'error': 'Empty description'
                    })
                    continue
                
                cleaned_description = preprocess_description(description)
                predicted_category = model.predict([cleaned_description])[0]
                probabilities = model.predict_proba([cleaned_description])[0]
                confidence = max(probabilities)
                
                results.append({
                    'index': i,
                    'description': description,
                    'predicted_category': predicted_category,
                    'confidence': float(confidence)
                })
                
            except Exception as e:
                results.append({
                    'index': i,
                    'description': description,
                    'error': str(e)
                })
        
        return jsonify({
            'success': True,
            'results': results,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in batch prediction: {e}")
        return jsonify({
            'error': f'Batch prediction failed: {str(e)}',
            'success': False
        }), 500

@app.route('/categories', methods=['GET'])
def get_categories():
    """Get all available categories"""
    try:
        if model is None:
            return jsonify({
                'error': 'Model not loaded',
                'success': False
            }), 500
        
        categories = model.classes_.tolist()
        
        return jsonify({
            'success': True,
            'categories': categories,
            'count': len(categories),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error getting categories: {e}")
        return jsonify({
            'error': f'Failed to get categories: {str(e)}',
            'success': False
        }), 500

@app.route('/retrain', methods=['POST'])
def retrain_model():
    """Retrain the model with new data (for future use)"""
    return jsonify({
        'message': 'Retraining endpoint not implemented yet',
        'success': False
    }), 501

if __name__ == '__main__':
    # Load the model on startup
    if load_model():
        print("🚀 Flask backend starting...")
        print("📊 Model loaded successfully")
        print("🌐 API available at: http://localhost:5001")
        print("\n📚 Available endpoints:")
        print("  GET  /health - Health check")
        print("  POST /predict - Predict single expense category")
        print("  POST /predict/batch - Predict multiple expense categories")
        print("  GET  /categories - Get all available categories")
        print("\n💡 Example prediction request:")
        print("  POST /predict")
        print("  Body: {\"description\": \"coffee at starbucks\"}")
        
        app.run(debug=True, host='0.0.0.0', port=5001)
    else:
        print("❌ Failed to load model. Please run train_model.py first.")