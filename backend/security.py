import os
import datetime
import jwt
import requests
from fastapi import Security, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv

load_dotenv()

# Cryptographic local token configs
SECRET_KEY = os.getenv("SECRET_KEY", "3ac7d466188e15790ac428d87c45a97cb960da53e53bde5bce9c6f95d1476595")
ALGORITHM = "HS256"

# Firebase Configs
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")
GOOGLE_CERT_URL = "https://www.googleapis.com/robot/v1/metadata/x5509/securetoken-system@system.gserviceaccount.com"

security_bearer = HTTPBearer()

def create_access_token(data: dict, expires_delta: datetime.timedelta = None) -> str:
    """Generates a secure, cryptographically signed local JWT."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.datetime.utcnow() + expires_delta
    else:
        expire = datetime.datetime.utcnow() + datetime.timedelta(days=7)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_firebase_public_keys():
    """Fetches Google's public certificates used to sign Firebase ID tokens."""
    try:
        response = requests.get(GOOGLE_CERT_URL)
        if response.status_code == 200:
            return response.json()
    except Exception as e:
        print(f"Error fetching Google certs: {e}")
    return {}

def verify_firebase_token(token: str) -> dict:
    """
    Decodes and cryptographically verifies an Authorization Token (Local JWT or Firebase ID Token).
    Throws a strict 401 exception on any validation failure, preventing any simulated/sandbox access.
    """
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization Token"
        )
    
    # 1. Check if it is a local JWT first
    try:
        decoded = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if "phone_number" in decoded or "uid" in decoded:
            return {
                "uid": decoded.get("uid") or decoded.get("sub") or "local_user",
                "phone_number": decoded.get("phone_number"),
                "name": decoded.get("name") or "Local User",
                "role": decoded.get("role") or "farmer",
                "auth_type": "local"
            }
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Local session has expired")
    except (jwt.InvalidSignatureError, jwt.InvalidTokenError):
        # Proceed to check if it's a Firebase token if it fails local verification
        pass

    # 2. Production Cryptographic Firebase JWT Verification
    if not FIREBASE_PROJECT_ID or FIREBASE_PROJECT_ID == "kissanai-auth":
        raise HTTPException(
            status_code=401,
            detail="Production Firebase is not configured. Local cryptographic auth is active."
        )

    try:
        headers = jwt.get_unverified_header(token)
        kid = headers.get("kid")
        if not kid:
            raise HTTPException(status_code=401, detail="Invalid token header: missing kid")
        
        certs = get_firebase_public_keys()
        public_key = certs.get(kid)
        if not public_key:
            raise HTTPException(status_code=401, detail="Invalid token kid: public certificate not found")
        
        # Verify Firebase JWT signature and standard claims
        decoded = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=FIREBASE_PROJECT_ID,
            issuer=f"https://securetoken.google.com/{FIREBASE_PROJECT_ID}"
        )
        return {
            "uid": decoded.get("user_id") or decoded.get("sub") or "fb_user",
            "phone_number": decoded.get("phone_number"),
            "name": decoded.get("name") or "Firebase User",
            "auth_type": "firebase"
        }
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Firebase token has expired")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase Token: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")

async def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security_bearer)) -> dict:
    """Dependency to retrieve the currently logged-in user from the active request context."""
    token = credentials.credentials
    claims = verify_firebase_token(token)
    return claims

