import requests
import json
from jinja2 import Template
from app.config import settings
import logging
import urllib3
import ssl

# Disable SSL warnings
urllib3.disable_warnings()
ssl._create_default_https_context = ssl._create_unverified_context

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        self.api_key = settings.SENDGRID_API_KEY
        self.from_email = settings.SENDGRID_FROM_EMAIL
        self.from_name = settings.SENDGRID_FROM_NAME
        
        # Check if we should use actual SendGrid
        self.use_sendgrid = bool(self.api_key and self.api_key != "your_sendgrid_api_key_here")
        
    async def send_otp_email(self, to_email: str, otp_code: str, user_name: str):
        """Send OTP email for password reset using SendGrid API"""
        try:
            # Create email content using template
            template = self._get_otp_template()
            html_content = template.render(
                user_name=user_name,
                otp_code=otp_code,
                expiry_minutes=10
            )
            
            # Use actual SendGrid email sending
            if self.use_sendgrid:
                # SendGrid API endpoint
                url = "https://api.sendgrid.com/v3/mail/send"
                
                # Email payload
                payload = {
                    "personalizations": [
                        {
                            "to": [{"email": to_email}],
                            "subject": "Password Reset OTP - MediFlow Pro"
                        }
                    ],
                    "from": {
                        "email": self.from_email,
                        "name": self.from_name
                    },
                    "content": [
                        {
                            "type": "text/html",
                            "value": html_content
                        }
                    ]
                }
                
                # Headers
                headers = {
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                }
                
                # Send request with SSL verification disabled
                response = requests.post(
                    url, 
                    data=json.dumps(payload), 
                    headers=headers, 
                    verify=False
                )
                
                if response.status_code == 202:
                    logger.info(f"✅ OTP email sent successfully to {to_email}")
                    return True
                else:
                    logger.error(f"❌ Failed to send OTP email. Status: {response.status_code}")
                    logger.error(f"Response: {response.text}")
                    # Fallback to simulation mode
                    logger.info(f"📧 EMAIL SIMULATION (SendGrid failed)")
                    logger.info(f"To: {to_email}")
                    logger.info(f"Subject: Password Reset OTP - MediFlow Pro")
                    logger.info(f"OTP Code: {otp_code}")
                    logger.info(f"User: {user_name}")
                    logger.info("--- Email Content Preview ---")
                    logger.info(html_content[:500] + "..." if len(html_content) > 500 else html_content)
                    logger.info("--- End Email Preview ---")
                    return True
            else:
                # Fallback to console output for development
                logger.info(f"📧 EMAIL SIMULATION (No SendGrid API key configured)")
                logger.info(f"To: {to_email}")
                logger.info(f"Subject: Password Reset OTP - MediFlow Pro")
                logger.info(f"OTP Code: {otp_code}")
                logger.info(f"User: {user_name}")
                logger.info("--- Email Content Preview ---")
                logger.info(html_content[:500] + "..." if len(html_content) > 500 else html_content)
                logger.info("--- End Email Preview ---")
                return True
                
        except Exception as e:
            logger.error(f"Error sending OTP email: {str(e)}")
            # Fallback to simulation mode on error
            logger.info(f"📧 EMAIL SIMULATION (SendGrid error: {str(e)})")
            logger.info(f"To: {to_email}")
            logger.info(f"Subject: Password Reset OTP - MediFlow Pro")
            logger.info(f"OTP Code: {otp_code}")
            logger.info(f"User: {user_name}")
            logger.info("--- Email Content Preview ---")
            logger.info("Email content would be sent here...")
            logger.info("--- End Email Preview ---")
            return True
    
    async def send_patient_registration_email(self, patient_name: str, clinic_name: str, patient_email: str, visit_type: str, appointment_date: str):
        """Send registration confirmation email to patient"""
        try:
            template = self._get_patient_registration_template()
            html_content = template.render(
                patient_name=patient_name,
                clinic_name=clinic_name,
                visit_type=visit_type,
                appointment_date=appointment_date
            )
            
            if self.use_sendgrid:
                url = "https://api.sendgrid.com/v3/mail/send"
                
                payload = {
                    "personalizations": [
                        {
                            "to": [{"email": patient_email}],
                            "subject": f"Registration Confirmed - {clinic_name}"
                        }
                    ],
                    "from": {
                        "email": self.from_email,
                        "name": self.from_name
                    },
                    "content": [
                        {
                            "type": "text/html",
                            "value": html_content
                        }
                    ]
                }
                
                headers = {
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                }
                
                response = requests.post(
                    url, 
                    data=json.dumps(payload), 
                    headers=headers, 
                    verify=False
                )
                
                if response.status_code == 202:
                    logger.info(f"✅ Patient registration email sent successfully to {patient_email}")
                    return True
                else:
                    logger.error(f"❌ Failed to send patient email. Status: {response.status_code}")
                    self._simulate_email(patient_email, f"Registration Confirmed - {clinic_name}", html_content)
                    return True
            else:
                self._simulate_email(patient_email, f"Registration Confirmed - {clinic_name}", html_content)
                return True
                
        except Exception as e:
            logger.error(f"Error sending patient registration email: {str(e)}")
            self._simulate_email(patient_email, f"Registration Confirmed - {clinic_name}", "Email content would be sent here...")
            return True
    
    async def send_mr_appointment_email(self, mr_name: str, clinic_name: str, mr_email: str, appointment_date: str, appointment_time: str, specialty: str):
        """Send appointment confirmation email to MR"""
        try:
            template = self._get_mr_appointment_template()
            html_content = template.render(
                mr_name=mr_name,
                clinic_name=clinic_name,
                specialty=specialty,
                appointment_date=appointment_date,
                appointment_time=appointment_time
            )
            
            if self.use_sendgrid:
                url = "https://api.sendgrid.com/v3/mail/send"
                
                payload = {
                    "personalizations": [
                        {
                            "to": [{"email": mr_email}],
                            "subject": f"Appointment Request Received - {clinic_name}"
                        }
                    ],
                    "from": {
                        "email": self.from_email,
                        "name": self.from_name
                    },
                    "content": [
                        {
                            "type": "text/html",
                            "value": html_content
                        }
                    ]
                }
                
                headers = {
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                }
                
                response = requests.post(
                    url, 
                    data=json.dumps(payload), 
                    headers=headers, 
                    verify=False
                )
                
                if response.status_code == 202:
                    logger.info(f"✅ MR appointment email sent successfully to {mr_email}")
                    return True
                else:
                    logger.error(f"❌ Failed to send MR email. Status: {response.status_code}")
                    self._simulate_email(mr_email, f"Appointment Request Received - {clinic_name}", html_content)
                    return True
            else:
                self._simulate_email(mr_email, f"Appointment Request Received - {clinic_name}", html_content)
                return True
                
        except Exception as e:
            logger.error(f"Error sending MR appointment email: {str(e)}")
            self._simulate_email(mr_email, f"Appointment Request Received - {clinic_name}", "Email content would be sent here...")
            return True
    
    def _simulate_email(self, to_email: str, subject: str, content: str):
        """Simulate email sending for development/testing"""
        logger.info(f"📧 EMAIL SIMULATION (SendGrid not configured or failed)")
        logger.info(f"To: {to_email}")
        logger.info(f"Subject: {subject}")
        logger.info("--- Email Content Preview ---")
        logger.info(content[:500] + "..." if len(content) > 500 else content)
        logger.info("--- End Email Preview ---")
    
    def _get_patient_registration_template(self):
        """Get HTML template for patient registration confirmation"""
        template_str = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #1976D2; color: white; padding: 20px; text-align: center; }
                .content { padding: 30px; background: #f9f9f9; }
                .confirmation-box { background: #4CAF50; color: white; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0; }
                .details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
                .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>MediFlow Pro</h1>
                    <p>Healthcare Management System</p>
                </div>
                
                <div class="content">
                    <div class="confirmation-box">
                        <h2>✅ Registration Confirmed!</h2>
                    </div>
                    
                    <p>Dear <strong>{{ patient_name }}</strong>,</p>
                    
                    <p>Your registration at <strong>{{ clinic_name }}</strong> has been successfully confirmed.</p>
                    
                    <div class="details">
                        <h3>Appointment Details:</h3>
                        <p><strong>Visit Type:</strong> {{ visit_type }}</p>
                        <p><strong>Date:</strong> {{ appointment_date }}</p>
                        <p><strong>Clinic:</strong> {{ clinic_name }}</p>
                    </div>
                    
                    <p>Our team will contact you shortly with further details. Please arrive 15 minutes before your scheduled appointment time.</p>
                    
                    <p>Thank you for choosing {{ clinic_name }}!</p>
                </div>
                
                <div class="footer">
                    <p>© 2024 MediFlow Pro. All rights reserved.</p>
                    <p>This is an automated confirmation email.</p>
                </div>
            </div>
        </body>
        </html>
        """
        return Template(template_str)
    
    def _get_mr_appointment_template(self):
        """Get HTML template for MR appointment confirmation"""
        template_str = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #0D47A1; color: white; padding: 20px; text-align: center; }
                .content { padding: 30px; background: #f9f9f9; }
                .confirmation-box { background: #FF9800; color: white; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0; }
                .details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
                .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>MediFlow Pro</h1>
                    <p>Medical Representative Portal</p>
                </div>
                
                <div class="content">
                    <div class="confirmation-box">
                        <h2>✅ Appointment Request Received</h2>
                    </div>
                    
                    <p>Dear <strong>{{ mr_name }}</strong>,</p>
                    
                    <p>Your appointment request has been successfully submitted to <strong>{{ clinic_name }}</strong>.</p>
                    
                    <div class="details">
                        <h3>Requested Appointment Details:</h3>
                        <p><strong>Specialty:</strong> {{ specialty }}</p>
                        <p><strong>Preferred Date:</strong> {{ appointment_date }}</p>
                        <p><strong>Preferred Time:</strong> {{ appointment_time }}</p>
                        <p><strong>Clinic:</strong> {{ clinic_name }}</p>
                    </div>
                    
                    <p>The clinic administration will review your request and contact you shortly to confirm the appointment.</p>
                    
                    <p>Thank you for your interest!</p>
                </div>
                
                <div class="footer">
                    <p>© 2024 MediFlow Pro. All rights reserved.</p>
                    <p>This is an automated confirmation email.</p>
                </div>
            </div>
        </body>
        </html>
        """
        return Template(template_str)
    
    def _get_otp_template(self):
        """Get HTML template for OTP email"""
        template_str = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #0D47A1; color: white; padding: 20px; text-align: center; }
                .content { padding: 30px; background: #f9f9f9; }
                .otp-box { 
                    background: #1976D2; 
                    color: white; 
                    padding: 20px; 
                    text-align: center; 
                    font-size: 24px; 
                    font-weight: bold; 
                    letter-spacing: 5px;
                    margin: 20px 0;
                    border-radius: 8px;
                }
                .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
                .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>MediFlow Pro</h1>
                    <p>Healthcare Management System</p>
                </div>
                
                <div class="content">
                    <h2>Hello {{ user_name }}!</h2>
                    <p>You have requested to reset your password. Use the following verification code to proceed:</p>
                    
                    <div class="otp-box">
                        {{ otp_code }}
                    </div>
                    
                    <p>This code will expire in <strong>{{ expiry_minutes }} minutes</strong>.</p>
                    
                    <div class="warning">
                        <p><strong>⚠️ Security Notice:</strong> If you didn't request this password reset, please ignore this email or contact our support team immediately.</p>
                    </div>
                    
                    <p>If you're having trouble with the code, please contact our support team.</p>
                </div>
                
                <div class="footer">
                    <p>© 2024 MediFlow Pro. All rights reserved.</p>
                    <p>This is an automated message, please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
        """
        return Template(template_str)

# Global email service instance
email_service = EmailService()
