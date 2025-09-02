# 📱 Send Reminder Feature

## Overview
The Send Reminder feature allows users to send payment reminders to friends who owe them money. When a reminder is sent, the friend receives both an **in-app notification** and a **push notification** that appears in their mobile notification drawer, even when the app is closed.

## How It Works

### 1. **Where to Find Reminder Buttons**

#### **Debt Item Widget** (Individual Transactions)
- **Location**: Friend Detail Screen → Individual debt/transaction cards
- **Visibility**: Only visible to creditors (people who are owed money) when debt status is "Pending"
- **Button**: Orange "Send Reminder" button with notification icon
- **Access**: 
  - Quick button: Appears directly on debt card
  - Options menu: Available in transaction options when you tap on a debt

#### **Friends Screen Tabs**
- **"They Owe" Tab**: Reminder button next to amounts for direct debts
- **"Splits" Tab**: Reminder button next to amounts for group expenses (only when friend owes you)

### 2. **What Happens When You Send a Reminder**

#### **For the Sender (You)**
1. Loading dialog appears: "Sending reminder..."
2. Success/failure message shows in snackbar
3. Reminder is logged in Firestore for tracking

#### **For the Receiver (Your Friend)**
1. **Push Notification** 📱
   - Appears in mobile notification drawer
   - Works even when app is closed
   - Shows amount owed and sender name
   - Includes context (days since debt created)

2. **In-App Notification** 🔔
   - Appears in app's notification center
   - Accessible via notification icon in app bar
   - Persistent until marked as read
   - Contains debt details and action buttons

### 3. **Notification Types**

#### **Direct Debt Reminders**
- **Title**: "💰 Payment Reminder" or "💸 Payment Due"
- **Message**: "[Friend] reminded you about ₹[amount] you owe them"
- **Context**: Includes debt description and days since created

#### **Group Expense Reminders**
- **Title**: "💰 Group Expense Reminder" or "💸 Group Expense Due"
- **Message**: "[Friend] reminded you about ₹[amount] for group expense"
- **Context**: Includes expense description and days since created

### 4. **Technical Implementation**

#### **Services Used**
- `ReminderService`: Core reminder logic
- `BackgroundNotificationService`: Push notifications
- `InAppNotificationProvider`: In-app notifications
- `FirebaseFirestore`: Reminder tracking and storage

#### **Data Flow**
1. User clicks "Send Reminder" button
2. `ReminderService.sendDebtReminder()` or `sendGroupExpenseReminder()` called
3. Reminder data saved to Firestore
4. Push notification sent via `BackgroundNotificationService`
5. In-app notification added via `InAppNotificationProvider`
6. Success/failure feedback shown to sender

#### **Firestore Structure**
```
reminders/
  ├── {reminderId}/
      ├── debtId: string
      ├── senderId: string
      ├── senderName: string
      ├── receiverId: string
      ├── receiverName: string
      ├── amount: number
      ├── description: string
      ├── reminderType: string
      ├── daysSince: number
      ├── timestamp: timestamp
      └── debtType: string
```

### 5. **User Experience Features**

#### **Smart Context**
- Shows days since debt was created
- Includes debt/expense description
- Different messages for direct vs group expenses

#### **Visual Feedback**
- Loading states during reminder sending
- Success/error messages with appropriate colors
- Orange notification icons for easy recognition

#### **Accessibility**
- Tooltip text on reminder buttons
- Clear button labels and icons
- Proper contrast and sizing

### 6. **Usage Examples**

#### **Scenario 1: Direct Debt**
- You lent ₹500 to John for lunch 3 days ago
- John hasn't paid back yet
- You click reminder button on the debt
- John receives: "You owe ₹500 to [Your Name] (3 days ago) for 'Lunch money'"

#### **Scenario 2: Group Expense**
- You paid ₹1000 for group dinner, John owes ₹250
- You send reminder from Splits tab
- John receives: "You owe ₹250 to [Your Name] for group expense 'Group dinner'"

### 7. **Benefits**

#### **For Creditors (People Owed Money)**
- Easy way to remind friends without awkward conversations
- Track when reminders were sent
- Multiple access points for convenience

#### **For Debtors (People Who Owe Money)**
- Clear notifications about pending payments
- Context about what the money is for
- Persistent reminders until debt is resolved

#### **For App Engagement**
- Increases app usage through notifications
- Encourages debt resolution
- Improves user satisfaction with debt management

### 8. **Future Enhancements**
- Reminder frequency limits (prevent spam)
- Customizable reminder messages
- Reminder scheduling (send later)
- Reminder history and analytics
- Auto-reminders based on due dates
