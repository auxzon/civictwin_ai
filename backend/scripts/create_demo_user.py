import sys
from pathlib import Path
import firebase_admin
from firebase_admin import credentials, auth, firestore

# Allow running from the backend/ root
sys.path.append(str(Path(__file__).resolve().parent.parent))

from config.settings import get_settings
from core.logging import configure_logging, get_logger

configure_logging()
logger = get_logger(__name__)

def run() -> None:
    settings = get_settings()

    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.google_application_credentials)
        firebase_admin.initialize_app(cred, options={"projectId": settings.firebase_project_id})

    email = "test@civictwin.dev"
    password = "TestPassword123!"

    try:
        # Check if user already exists
        user = auth.get_user_by_email(email)
        logger.info("Demo user '%s' already exists (UID: %s).", email, user.uid)
        
        # Ensure password matches
        auth.update_user(user.uid, password=password)
        logger.info("Password updated successfully for '%s'.", email)
    except auth.UserNotFoundError:
        # Create user
        user = auth.create_user(
            email=email,
            email_verified=True,
            password=password,
            display_name="Demo User"
        )
        logger.info("Demo user '%s' created successfully (UID: %s).", email, user.uid)

    # Provision user document in Firestore to satisfy isUser() security rule check
    db = firestore.client()
    user_ref = db.collection("users").document(user.uid)
    user_ref.set({
        "uid": user.uid,
        "name": "Demo User",
        "role": "MP",
        "constituency_id": "const_mumbai_north",
        "created_at": firestore.SERVER_TIMESTAMP
    })
    logger.info("Firestore user document created/updated successfully for UID: %s", user.uid)

if __name__ == "__main__":
    run()
