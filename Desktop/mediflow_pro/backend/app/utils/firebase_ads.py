import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase
def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        cred_path = "firebase-credentials.json"
        if not os.path.exists(cred_path):
            print("⚠️ Firebase credentials not found")
            return None
        
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        print("✅ Firebase initialized for ads")
        return db
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        return None

def get_ads_from_firebase(clinic_id=None):
    """Fetch ads from Firebase Firestore"""
    try:
        db = initialize_firebase()
        if not db:
            return []
        
        # Query active ads
        ads_ref = db.collection('ads')
        query = ads_ref.where('isActive', '==', True)
        
        # Filter by clinic if specified
        if clinic_id:
            # Get both global ads and clinic-specific ads
            global_ads = ads_ref.where('isActive', '==', True).where('clinicId', '==', None).stream()
            clinic_ads = ads_ref.where('isActive', '==', True).where('clinicId', '==', clinic_id).stream()
            
            ads_list = []
            seen_ids = set()
            
            for ad in global_ads:
                ad_data = ad.to_dict()
                ad_data['id'] = ad.id
                if ad_data['id'] not in seen_ids:
                    ads_list.append(ad_data)
                    seen_ids.add(ad_data['id'])
            
            for ad in clinic_ads:
                ad_data = ad.to_dict()
                ad_data['id'] = ad.id
                if ad_data['id'] not in seen_ids:
                    ads_list.append(ad_data)
                    seen_ids.add(ad_data['id'])
            
            # Sort by priority in Python (no index needed)
            ads_list.sort(key=lambda x: x.get('priority', 0), reverse=True)
            return ads_list
        else:
            # Get all active ads and sort in Python
            docs = query.stream()
            ads_list = []
            for doc in docs:
                ad_data = doc.to_dict()
                ad_data['id'] = doc.id
                ads_list.append(ad_data)
            
            # Sort by priority in Python (no index needed)
            ads_list.sort(key=lambda x: x.get('priority', 0), reverse=True)
            return ads_list
            
    except Exception as e:
        print(f"Error fetching ads from Firebase: {e}")
        return []
