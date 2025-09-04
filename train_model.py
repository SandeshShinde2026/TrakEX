import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix
import joblib
import os

# 1. Load and Validate Data
def load_and_validate_data():
    try:
        data = pd.read_csv('assets/expense_categorization_data.csv')
        print(f"Successfully loaded dataset with {len(data)} records")
    except FileNotFoundError:
        print("Error: 'assets/expense_categorization_data.csv' not found.")
        print("Please make sure the CSV file is in the 'assets' directory.")
        return None
    
    # Check required columns
    required_columns = ['description', 'category']
    if not all(col in data.columns for col in required_columns):
        print(f"Error: CSV must contain columns: {required_columns}")
        print(f"Found columns: {list(data.columns)}")
        return None
    
    # Clean data
    initial_count = len(data)
    data = data.dropna(subset=['description', 'category'])
    data = data[data['description'].str.strip() != '']
    
    print(f"Cleaned data: {len(data)} valid records (removed {initial_count - len(data)} invalid records)")
    return data

# 2. Preprocess text data
def preprocess_description(text):
    """Clean and normalize expense descriptions"""
    if pd.isna(text):
        return ""
    return str(text).lower().strip()

# 3. Train and evaluate model
def train_and_evaluate_model(data):
    # Preprocess descriptions
    data['description'] = data['description'].apply(preprocess_description)
    
    # Prepare features and labels
    X = data['description']
    y = data['category']
    
    print("\nDataset Overview:")
    print(f"Total records: {len(data)}")
    print(f"\nCategory distribution:")
    category_counts = data['category'].value_counts()
    print(category_counts)
    
    # Check for data imbalance
    min_samples = category_counts.min()
    max_samples = category_counts.max()
    if max_samples / min_samples > 5:
        print(f"\nWarning: Data imbalance detected! Largest category has {max_samples} samples, smallest has {min_samples}")
        print("Consider adding more samples for underrepresented categories")
    
    # Create model with improved parameters
    model = make_pipeline(
        CountVectorizer(
            lowercase=True,
            stop_words='english',  # Remove common English stop words
            ngram_range=(1, 2),    # Include both unigrams and bigrams
            max_features=1000,     # Limit vocabulary size for small dataset
            min_df=1,              # Include words that appear at least once
            max_df=0.95            # Exclude words that appear in >95% of documents
        ),
        MultinomialNB(alpha=0.1)   # Lower alpha for small dataset
    )
    
    # For small datasets, use cross-validation instead of train/test split
    if len(data) < 100:
        print(f"\nUsing 5-fold cross-validation (dataset size: {len(data)})")
        cv_scores = cross_val_score(model, X, y, cv=5, scoring='accuracy')
        print(f"Cross-validation accuracy: {cv_scores.mean():.3f} (+/- {cv_scores.std() * 2:.3f})")
        
        # Train on full dataset for final model
        model.fit(X, y)
        
        # Show predictions on training data for demonstration
        y_pred = model.predict(X)
        print(f"\nTraining accuracy: {accuracy_score(y, y_pred):.3f}")
        
    else:
        # Use train/test split for larger datasets
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        
        accuracy = accuracy_score(y_test, y_pred)
        print(f"\nModel Performance:")
        print(f"Training samples: {len(X_train)}")
        print(f"Test samples: {len(X_test)}")
        print(f"Test accuracy: {accuracy:.3f}")
        
        print("\nDetailed Classification Report:")
        print(classification_report(y_test, y_pred))
    
    return model

# 4. Save model and demonstrate predictions
def save_model_and_demo(model, data):
    # Create models directory if it doesn't exist
    os.makedirs('models', exist_ok=True)
    
    # Save the trained model
    model_path = 'models/expense_categorization_model.joblib'
    joblib.dump(model, model_path)
    print(f"\nModel saved to: {model_path}")
    
    # Demo predictions with confidence scores
    print("\n--- Demo Predictions ---")
    sample_descriptions = [
        'coffee and pastry at starbucks',
        'grocery shopping at walmart', 
        'gas station fill up',
        'movie tickets from bookmyshow',
        'uber ride to airport',
        'electricity bill payment',
        'gym membership fee',
        'vada pav from street vendor',
        'zomato food delivery',
        'jio mobile recharge'
    ]
    
    predictions = model.predict(sample_descriptions)
    probabilities = model.predict_proba(sample_descriptions)
    
    for desc, pred, prob in zip(sample_descriptions, predictions, probabilities):
        confidence = max(prob)
        print(f"'{desc}' -> {pred} (confidence: {confidence:.3f})")

# 5. Load model function for testing
def test_model_loading():
    """Test loading and using the saved model"""
    try:
        model_path = 'models/expense_categorization_model.joblib'
        loaded_model = joblib.load(model_path)
        
        test_descriptions = ['chai and biscuits', 'new shoes from bata', 'petrol pump']
        predictions = loaded_model.predict(test_descriptions)
        
        print(f"\n--- Model Loading Test ---")
        for desc, pred in zip(test_descriptions, predictions):
            print(f"'{desc}' -> {pred}")
        
        print("✓ Model loading and prediction successful!")
        return True
    except Exception as e:
        print(f"✗ Error loading model: {e}")
        return False

# Main execution
if __name__ == "__main__":
    print("Training Expense Categorization Model...\n")
    
    # Load and validate data
    data = load_and_validate_data()
    if data is None:
        exit(1)
    
    # Train model
    model = train_and_evaluate_model(data)
    
    # Save model and demo
    save_model_and_demo(model, data)
    
    # Test model loading
    test_model_loading()
    
    print("\n=== Next Steps ===")
    print("1. Review the model performance metrics above")
    print("2. If accuracy is low, consider:")
    print("   - Adding more training data (especially for underrepresented categories)")
    print("   - Improving data quality and consistency")
    print("   - Using different preprocessing techniques")
    print("3. Integrate the model into your Flutter app via a Python backend")
    print("4. Test with real user data and gather feedback")
    print("5. Continuously retrain with new user data")
