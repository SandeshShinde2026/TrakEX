# Firebase Security Rules for TrakEX

You're seeing a permission denied error because your Firebase security rules are preventing write access to the Firestore collections. Follow these steps to update your security rules:

## Step 1: Go to Firebase Console

1. Open your browser and go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **mujjarfunds**

## Step 2: Navigate to Firestore Database

1. In the left sidebar, click on **Firestore Database**
2. Click on the **Rules** tab at the top

## Step 3: Update Security Rules

Replace the current rules with the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read and write their own expenses
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Allow authenticated users to read and write their own budgets
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Allow authenticated users to read and write their own debts
    match /debts/{debtId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid ||
         resource.data.friendId == request.auth.uid);
    }
  }
}
```

## Step 4: Publish the Rules

1. Click the **Publish** button to save and apply the new rules

## Step 5: Test Your App Again

After updating the security rules, go back to your app and try adding an expense again. The permission denied error should be resolved.

## Understanding the Rules

These rules ensure that:

1. Users can only read and write their own data
2. For expenses and budgets, users can only access documents where they are the owner (userId matches their auth.uid)
3. For debts, users can access documents where they are either the owner or the friend

## Temporary Solution (Not Recommended for Production)

If you're still having issues and just want to get things working quickly for development, you can temporarily use these less secure rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Warning**: These rules allow any authenticated user to read and write any document in your database. Only use this for development and testing, not in production.
