#!/usr/bin/env python3
"""Test script to check ads and their images"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_ads():
    print("🔍 Testing Ads API...")
    print("=" * 60)
    
    try:
        # Test getting ads
        response = requests.get(f"{BASE_URL}/api/ads")
        
        if response.status_code == 200:
            ads = response.json()
            print(f"\n✅ Found {len(ads)} ads\n")
            
            for i, ad in enumerate(ads, 1):
                print(f"📌 Ad #{i}:")
                print(f"   Title: {ad.get('title', 'N/A')}")
                print(f"   Image URL: {ad.get('image_url', 'N/A')}")
                print(f"   Active: {ad.get('is_active', False)}")
                print(f"   Type: {ad.get('ad_type', 'N/A')}")
                
                # Check if image URL exists
                image_url = ad.get('image_url')
                if not image_url or image_url.strip() == '':
                    print(f"   ⚠️  WARNING: No image URL!")
                else:
                    print(f"   ✅ Has image URL")
                    
                print()
        else:
            print(f"❌ Failed to get ads. Status: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_ads()
