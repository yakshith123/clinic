from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class AdType(str, Enum):
    BANNER = "banner"
    POPUP = "popup"
    VIDEO = "video"

class Ad(BaseModel):
    id: Optional[str] = None
    title: str
    image_url: str
    target_url: Optional[str] = None
    ad_type: AdType = AdType.BANNER
    is_active: bool = True
    priority: int = 0  # Higher number = higher priority
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    clinic_id: Optional[str] = None  # None means all clinics
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        json_schema_extra = {
            "example": {
                "title": "Special Offer",
                "image_url": "https://example.com/ad.jpg",
                "target_url": "https://example.com/offer",
                "ad_type": "banner",
                "is_active": True,
                "priority": 1,
                "clinic_id": None
            }
        }
