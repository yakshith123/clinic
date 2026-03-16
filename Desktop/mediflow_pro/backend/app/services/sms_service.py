import requests
import json
from app.config import settings
import logging
import urllib3
import ssl

# Disable SSL warnings
urllib3.disable_warnings()
ssl._create_default_https_context = ssl._create_unverified_context

logger = logging.getLogger(__name__)

class SMSService:
    def __init__(self):
        # Twilio credentials
        self.account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
        self.auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
        self.twilio_phone_number = getattr(settings, 'TWILIO_PHONE_NUMBER', None)
        
        # Check if we should use actual Twilio
        self.use_twilio = bool(
            self.account_sid and 
            self.auth_token and 
            self.twilio_phone_number and
            self.account_sid != "your_twilio_account_sid" and
            self.auth_token != "your_twilio_auth_token"
        )
        
        if self.use_twilio:
            logger.info("✅ Twilio SMS service configured")
        else:
            logger.info("⚠️ Twilio SMS not configured - will simulate SMS sending")
    
    async def send_patient_registration_sms(self, patient_name: str, clinic_name: str, phone_number: str):
        """Send SMS confirmation to registered patient"""
        try:
            # Shortened for Twilio trial (under 160 chars)
            message_body = f"Hi {patient_name}! Registration confirmed at {clinic_name}. Thanks!"
            
            if self.use_twilio:
                # Use Twilio API
                url = f"https://api.twilio.com/2010-04-01/Accounts/{self.account_sid}/Messages.json"
                
                payload = {
                    'To': phone_number,
                    'From': self.twilio_phone_number,
                    'Body': message_body
                }
                
                response = requests.post(
                    url,
                    data=payload,
                    auth=(self.account_sid, self.auth_token),
                    verify=False
                )
                
                if response.status_code in [200, 201]:
                    logger.info(f"✅ SMS sent successfully to {phone_number}")
                    return True
                else:
                    logger.error(f"❌ Failed to send SMS. Status: {response.status_code}")
                    logger.error(f"Response: {response.text}")
                    # Fallback to simulation
                    self._simulate_sms(phone_number, message_body)
                    return True
            else:
                # Fallback to console output for development
                self._simulate_sms(phone_number, message_body)
                return True
                
        except Exception as e:
            logger.error(f"Error sending SMS: {str(e)}")
            # Fallback to simulation on error
            self._simulate_sms(phone_number, message_body)
            return True
    
    async def send_mr_appointment_sms(self, mr_name: str, clinic_name: str, phone_number: str, appointment_date: str, appointment_time: str):
        """Send SMS confirmation to MR after appointment request"""
        try:
            # Shortened for Twilio trial (under 160 chars)
            message_body = f"Hi {mr_name}! Appointment request received at {clinic_name} on {appointment_date}, {appointment_time}. We'll confirm soon!"
            
            if self.use_twilio:
                # Use Twilio API
                url = f"https://api.twilio.com/2010-04-01/Accounts/{self.account_sid}/Messages.json"
                
                payload = {
                    'To': phone_number,
                    'From': self.twilio_phone_number,
                    'Body': message_body
                }
                
                response = requests.post(
                    url,
                    data=payload,
                    auth=(self.account_sid, self.auth_token),
                    verify=False
                )
                
                if response.status_code in [200, 201]:
                    logger.info(f"✅ MR appointment SMS sent successfully to {phone_number}")
                    return True
                else:
                    logger.error(f"❌ Failed to send MR appointment SMS. Status: {response.status_code}")
                    logger.error(f"Response: {response.text}")
                    # Fallback to simulation
                    self._simulate_sms(phone_number, message_body)
                    return True
            else:
                # Fallback to console output for development
                self._simulate_sms(phone_number, message_body)
                return True
                
        except Exception as e:
            logger.error(f"Error sending MR appointment SMS: {str(e)}")
            # Fallback to simulation on error
            self._simulate_sms(phone_number, message_body)
            return True
    
    def _simulate_sms(self, phone_number: str, message: str):
        """Simulate SMS sending for development/testing"""
        logger.info(f"📱 SMS SIMULATION (Twilio not configured or failed)")
        logger.info(f"To: {phone_number}")
        logger.info(f"Message: {message}")
        logger.info("--- End SMS Preview ---")
    
    async def send_otp_sms(self, phone_number: str, otp_code: str):
        """Send OTP via SMS"""
        try:
            # Short, clear OTP message
            message_body = f"MediFlow Pro: Your OTP code is {otp_code}. Valid for 5 minutes."
            
            if self.use_twilio:
                # Use Twilio API
                url = f"https://api.twilio.com/2010-04-01/Accounts/{self.account_sid}/Messages.json"
                
                payload = {
                    'To': phone_number,
                    'From': self.twilio_phone_number,
                    'Body': message_body
                }
                
                response = requests.post(
                    url,
                    data=payload,
                    auth=(self.account_sid, self.auth_token),
                    verify=False
                )
                
                if response.status_code in [200, 201]:
                    logger.info(f"✅ OTP SMS sent successfully to {phone_number}")
                    return True
                else:
                    logger.error(f"❌ Failed to send OTP SMS. Status: {response.status_code}")
                    logger.error(f"Response: {response.text}")
                    # Fallback to simulation
                    self._simulate_sms(phone_number, message_body)
                    return False
            else:
                # Fallback to console output for development
                self._simulate_sms(phone_number, message_body)
                return True
                
        except Exception as e:
            logger.error(f"Error sending OTP SMS: {str(e)}")
            # Fallback to simulation on error
            self._simulate_sms(phone_number, message_body)
            return True


# Global SMS service instance
sms_service = SMSService()
