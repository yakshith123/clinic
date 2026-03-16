from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Optional
from ..models.ad import Ad
from ..models.user import User
from ..utils.security import get_current_user
from ..utils.firebase_ads import get_ads_from_firebase
import uuid
from datetime import datetime

router = APIRouter(prefix="/api/ads", tags=["ads"])

# In-memory storage (replace with database in production)
ads_db: dict[str, Ad] = {}

@router.get("", response_model=List[dict])
async def get_ads(clinic_id: Optional[str] = None, current_user: User = Depends(get_current_user)):
    """Get all active ads from Firebase, optionally filtered by clinic"""
    try:
        # Fetch ads from Firebase Firestore
        ads_data = get_ads_from_firebase(clinic_id=clinic_id)
        return ads_data
    except Exception as e:
        print(f"Error fetching ads: {e}")
        return []

@router.post("", response_model=Ad, status_code=status.HTTP_201_CREATED)
async def create_ad(ad: Ad, current_user: User = Depends(get_current_user)):
    """Create a new ad (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    
    ad.id = str(uuid.uuid4())
    ad.created_at = datetime.now()
    ad.updated_at = datetime.now()
    ads_db[ad.id] = ad
    return ad

@router.put("/{ad_id}", response_model=Ad)
async def update_ad(ad_id: str, ad: Ad, current_user: User = Depends(get_current_user)):
    """Update an existing ad (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    
    if ad_id not in ads_db:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ad not found")
    
    ad.id = ad_id
    ad.updated_at = datetime.now()
    ads_db[ad_id] = ad
    return ad

@router.delete("/{ad_id}")
async def delete_ad(ad_id: str, current_user: User = Depends(get_current_user)):
    """Delete an ad (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    
    if ad_id not in ads_db:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ad not found")
    
    del ads_db[ad_id]
    return {"message": "Ad deleted successfully"}

@router.get("/active", response_model=List[Ad])
async def get_active_ads(current_user: User = Depends(get_current_user)):
    """Get all active ads"""
    return [ad for ad in ads_db.values() if ad.is_active]
