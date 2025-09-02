
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
import joblib

# 1. Load Data
try:
    data = pd.read_csv('assets/expense_categorization_data.csv')
except FileNotFoundError:
    print("Error: 'assets/expense_categorization_data.csv' not found.")
    print("Please make sure the CSV file is in the 'assets' directory and you have run the previous steps.")
    exit()

# Filter out rows where 'description' or 'category' is NaN (empty)
data = data.dropna(subset=['description', 'category'])

print("Successfully loaded and cleaned data.")
print(f"Training with {len(data)} data points.")
print("\nFirst 5 rows of the dataset:")
print(data.head())
print("\nCategories found in the dataset:")
print(data['category'].value_counts())


# 2. Prepare Data and Train Model
# We will use a pipeline to combine the vectorizer and the classifier
# CountVectorizer: Converts text to a matrix of token counts
# MultinomialNB: A classifier suitable for text classification
model = make_pipeline(
    CountVectorizer(),
    MultinomialNB()
)

# Train the model on the entire dataset
X = data['description']
y = data['category']
model.fit(X, y)

print("\nModel training completed successfully.")

# 3. Save the trained model and the vectorizer
# We save the entire pipeline, which includes both the vectorizer and the model.
joblib.dump(model, 'expense_categorization_model.joblib')

print("\nSuccessfully saved the trained model to 'expense_categorization_model.joblib'")
print("\nNext steps:")
print("1. Run this script to train the model by executing: python train_model.py")
print("2. Once the 'expense_categorization_model.joblib' file is created, we can build a simple backend to serve this model.")

# Example of how to load the model and make a prediction
# print("\n--- Example Prediction ---")
# loaded_model = joblib.load('expense_categorization_model.joblib')
# predictions = loaded_model.predict(['chai and biscuits', 'new shoes from bata'])
# for desc, pred in zip(['chai and biscuits', 'new shoes from bata'], predictions):
#     print(f"Description: '{desc}' -> Predicted Category: '{pred}'")
