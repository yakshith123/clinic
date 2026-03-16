from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List
import os
from twilio.rest import Client

router = APIRouter(prefix="/sms", tags=["SMS"])

class SMSRequest(BaseModel):
    phone_number: str
    message: str

class BulkSMSRequest(BaseModel):
    recipients: List[dict]  # List of {phone_number, message}

@router.post("/send")
async def send_sms(sms_request: SMSRequest):
    """Send a single SMS using Twilio"""
    try:
        # Check if Twilio is configured
        account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        auth_token = os.getenv("TWILIO_AUTH_TOKEN")
        twilio_number = os.getenv("TWILIO_PHONE_NUMBER")
        
        if not all([account_sid, auth_token, twilio_number]):
            # Fallback: Just log the SMS (development mode)
            print(f"📱 [DEV MODE] SMS would be sent to {sms_request.phone_number}")
            print(f"   Message: {sms_request.message}")
            return {
                "success": True,
                "message": "SMS logged (Twilio not configured)",
                "dev_mode": True
            }
        
        # Send real SMS via Twilio
        client = Client(account_sid, auth_token)
        
        message = client.messages.create(
            body=sms_request.message,
            from_=twilio_number,
            to=f"+91{sms_request.phone_number}"  # Assuming India numbers
        )
        
        print(f"✅ SMS sent successfully to {sms_request.phone_number}: {message.sid}")
        
        return {
            "success": True,
            "message": "SMS sent successfully",
            "message_id": message.sid
        }
        
    except Exception as e:
        print(f"❌ Error sending SMS: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to send SMS: {str(e)}")

@router.post("/send-bulk")
async def send_bulk_sms(request: BulkSMSRequest):
    """Send SMS to multiple recipients"""
    results = []
    
    for recipient in request.recipients:
        try:
            sms_request = SMSRequest(
                phone_number=recipient["phone_number"],
                message=recipient["message"]
            )
            
            # Reuse single SMS endpoint
            result = await send_sms(sms_request)
            results.append({
                "phone_number": recipient["phone_number"],
                "success": True,
                "result": result
            })
            
        except Exception as e:
            results.append({
                "phone_number": recipient["phone_number"],
                "success": False,
                "error": str(e)
            })
    
    success_count = sum(1 for r in results if r["success"])
    total = len(results)
    
    return {
        "success": True,
        "message": f"Sent {success_count}/{total} SMS messages",
        "results": results,
        "summary": {
            "total": total,
            "successful": success_count,
            "failed": total - success_count
        }
    }
