from fastapi import APIRouter, HTTPException, Depends, Security
from pydantic import BaseModel
from typing import Optional
from backend.database import get_connection
from backend.security import get_current_user, verify_firebase_token, create_access_token

router = APIRouter()

class TokenAuthRequest(BaseModel):
    id_token: str
    role: str = "farmer"  # "farmer" or "provider"
    name: Optional[str] = None

class LocalRegisterRequest(BaseModel):
    phone: str
    name: str
    role: str = "farmer"  # "farmer" or "provider"

class LocalLoginRequest(BaseModel):
    phone: str

@router.post("/register_local")
async def register_local(payload: LocalRegisterRequest):
    """
    Registers a new user in the local database and generates a cryptographically signed JWT.
    """
    phone = payload.phone.strip()
    name = payload.name.strip()
    role = payload.role.strip()
    
    if not phone or not name:
        raise HTTPException(status_code=400, detail="Phone number and name are required")
        
    conn = get_connection()
    cur = conn.cursor()
    
    import os
    is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")
    
    query_check = "SELECT * FROM users WHERE phone = %s" if is_postgres else "SELECT * FROM users WHERE phone = ?"
    cur.execute(query_check, (phone,))
    existing = cur.fetchone()
    
    if existing:
        conn.close()
        raise HTTPException(status_code=400, detail="Phone number already registered. Please sign in instead.")
        
    # Insert new user
    query_insert = """
        INSERT INTO users (phone, name, role)
        VALUES (%s, %s, %s)
    """ if is_postgres else """
        INSERT INTO users (phone, name, role)
        VALUES (?, ?, ?)
    """
    cur.execute(query_insert, (phone, name, role))
    conn.commit()
    
    # Fetch user details
    cur.execute(query_check, (phone,))
    user = dict(cur.fetchone())
    
    # Create default provider entry if role is provider
    if role == "provider":
        query_prov = "SELECT * FROM providers WHERE id = %s" if is_postgres else "SELECT * FROM providers WHERE id = ?"
        cur.execute(query_prov, (user["id"],))
        prov_row = cur.fetchone()
        
        if not prov_row:
            query_insert_prov = """
                INSERT INTO providers (id, name, service_type, latitude, longitude, availability, rating, completed_jobs)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """ if is_postgres else """
                INSERT INTO providers (id, name, service_type, latitude, longitude, availability, rating, completed_jobs)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            cur.execute(query_insert_prov, (user["id"], name, "tractor", 31.5204, 74.3587, 1, 4.8, 0))
            conn.commit()
            
    conn.close()
    
    # Generate cryptographically signed JWT
    token = create_access_token({"uid": str(user["id"]), "phone_number": phone, "name": name, "role": role})
    return {"status": "success", "token": token, "user": user}

@router.post("/login_local")
async def login_local(payload: LocalLoginRequest):
    """
    Logs in an existing user locally by phone and generates a cryptographically signed JWT.
    """
    phone = payload.phone.strip()
    if not phone:
        raise HTTPException(status_code=400, detail="Phone number is required")
        
    conn = get_connection()
    cur = conn.cursor()
    
    import os
    is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")
    
    query_check = "SELECT * FROM users WHERE phone = %s" if is_postgres else "SELECT * FROM users WHERE phone = ?"
    cur.execute(query_check, (phone,))
    user_row = cur.fetchone()
    conn.close()
    
    if not user_row:
        raise HTTPException(status_code=404, detail="Phone number not registered. Please sign up first.")
        
    user = dict(user_row)
    
    # Generate cryptographically signed JWT
    token = create_access_token({"uid": str(user["id"]), "phone_number": phone, "name": user["name"], "role": user["role"]})
    return {"status": "success", "token": token, "user": user}

@router.post("/login_with_token")
async def login_with_token(payload: TokenAuthRequest):
    """
    Accepts a Firebase ID Token, verifies it, and synchronizes the user 
    in our local PostgreSQL/SQLite database (creates a new record if they don't exist).
    """
    try:
        # 1. Verify token and get phone claims
        claims = verify_firebase_token(payload.id_token)
        phone = claims.get("phone_number")
        
        if not phone:
            raise HTTPException(status_code=400, detail="Phone number claim not found in Firebase Token")
        
        # Determine name
        name = payload.name or claims.get("name") or "Farmer"
        if payload.role == "provider" and name == "Farmer":
            name = "Provider Operator"
            
        # 2. Check if user exists in our local database
        conn = get_connection()
        cur = conn.cursor()
        
        # Check SQLite vs Postgres syntax
        import os
        is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")
        
        query_check = "SELECT * FROM users WHERE phone = %s" if is_postgres else "SELECT * FROM users WHERE phone = ?"
        cur.execute(query_check, (phone,))
        user_row = cur.fetchone()
        
        if not user_row:
            # Create new user in our DB
            query_insert = """
                INSERT INTO users (phone, name, role)
                VALUES (%s, %s, %s)
            """ if is_postgres else """
                INSERT INTO users (phone, name, role)
                VALUES (?, ?, ?)
            """
            cur.execute(query_insert, (phone, name, payload.role))
            conn.commit()
            
            # Fetch the newly inserted user
            cur.execute(query_check, (phone,))
            user_row = cur.fetchone()
            
        user = dict(user_row)
        
        # 3. If they are a provider, check if they exist in the providers table
        if user["role"] == "provider":
            query_prov = "SELECT * FROM providers WHERE id = %s" if is_postgres else "SELECT * FROM providers WHERE id = ?"
            cur.execute(query_prov, (user["id"],))
            prov_row = cur.fetchone()
            
            if not prov_row:
                # Add default provider listing
                query_insert_prov = """
                    INSERT INTO providers (id, name, service_type, latitude, longitude, availability, rating, completed_jobs)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """ if is_postgres else """
                    INSERT INTO providers (id, name, service_type, latitude, longitude, availability, rating, completed_jobs)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """
                cur.execute(query_insert_prov, (user["id"], name, "tractor", 31.5204, 74.3587, 1, 4.8, 0))
                conn.commit()
        
        conn.close()
        return {"status": "success", "user": user}
        
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")

@router.get("/me")
async def get_me(current_user_claims: dict = Depends(get_current_user)):
    """
    Retrieves the currently authenticated user's profile.
    Uses the verified token's phone claim to query our database.
    """
    phone = current_user_claims.get("phone_number")
    if not phone:
        raise HTTPException(status_code=400, detail="Phone number claim not found in token")
        
    conn = get_connection()
    cur = conn.cursor()
    
    import os
    is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")
    
    query = "SELECT * FROM users WHERE phone = %s" if is_postgres else "SELECT * FROM users WHERE phone = ?"
    cur.execute(query, (phone,))
    user_row = cur.fetchone()
    conn.close()
    
    if not user_row:
        raise HTTPException(status_code=404, detail="User not found in local database")
        
    return dict(user_row)

