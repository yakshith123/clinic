import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging
from typing import Optional, List
import os
from app.config import settings

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK for sending notifications"""
    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    
    if not os.path.exists(cred_path):
        print(f"Firebase credentials file not found: {cred_path}")
        print("Push notifications will be disabled.")
        return False
    
    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully")
        return True
    except Exception as e:
        print(f"Failed to initialize Firebase: {e}")
        return False

def send_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[dict] = None
) -> bool:
    """Send a push notification to a specific device"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending notification: {e}")
        return False

def send_topic_notification(
    topic: str,
    title: str,
    body: str,
    data: Optional[dict] = None
) -> bool:
    """Send a push notification to all devices subscribed to a topic"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            topic=topic,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending notification: {e}")
        return False

def subscribe_to_topic(tokens: List[str], topic: str) -> bool:
    """Subscribe devices to a topic"""
    try:
        response = messaging.subscribe_to_topic(tokens, topic)
        print(f"Successfully subscribed: {response.success_count}")
        return True
    except Exception as e:
        print(f"Error subscribing to topic: {e}")
        return False

def unsubscribe_from_topic(tokens: List[str], topic: str) -> bool:
    """Unsubscribe devices from a topic"""
    try:
        response = messaging.unsubscribe_from_topic(tokens, topic)
        print(f"Successfully unsubscribed: {response.success_count}")
        return True
    except Exception as e:
        print(f"Error unsubscribing from topic: {e}")
        return False

# Initialize Firebase on module import
firebase_initialized = initialize_firebase()

