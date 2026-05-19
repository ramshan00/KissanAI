import os
import sqlite3
from pathlib import Path
from dotenv import load_dotenv

# Load env variables
load_dotenv()

# Determine database url
DATABASE_URL = os.getenv("DATABASE_URL")
IS_POSTGRES = DATABASE_URL and DATABASE_URL.startswith("postgresql://")

# SQLite fallback path
DB_PATH = Path(__file__).parent / "kissanai.db"

def get_connection():
    """Returns a database connection. Automatically routes to PostgreSQL or SQLite based on configuration."""
    if IS_POSTGRES:
        try:
            import psycopg2
            from psycopg2.extras import RealDictConnection
            # Connect to PostgreSQL using standard psycopg2 driver
            conn = psycopg2.connect(DATABASE_URL, connection_factory=RealDictConnection)
            return conn
        except ImportError:
            print("WARNING: psycopg2 not installed. Falling back to SQLite local database.")
    
    # SQLite local driver fallback
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initializes the database schema (PostgreSQL or SQLite compatible). Seeding initial operators and farmers."""
    conn = get_connection()
    cur = conn.cursor()
    
    # Dialect specific auto-increment
    pk_auto = "SERIAL PRIMARY KEY" if IS_POSTGRES else "INTEGER PRIMARY KEY AUTOINCREMENT"
    timestamp_default = "CURRENT_TIMESTAMP"
    
    # Users table
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS users (
            id {pk_auto},
            phone TEXT UNIQUE NOT NULL,
            name TEXT,
            role TEXT DEFAULT 'farmer',
            created_at TIMESTAMP DEFAULT {timestamp_default}
        )
    """)
    
    # SQLite migration: add column if exists without it
    if not IS_POSTGRES:
        try:
            cur.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'farmer'")
        except Exception:
            pass
    
    # Providers (Machinery Operators) table
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS providers (
            id {pk_auto},
            name TEXT NOT NULL,
            service_type TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            availability INTEGER DEFAULT 1,
            rating REAL DEFAULT 0,
            completed_jobs INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT {timestamp_default}
        )
    """)
    
    # Bookings table
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS bookings (
            id {pk_auto},
            user_id INTEGER NOT NULL,
            provider_id INTEGER,
            service_type TEXT NOT NULL,
            location TEXT NOT NULL,
            urgency TEXT,
            scheduled_time TEXT,
            status TEXT DEFAULT 'pending',
            price REAL,
            created_at TIMESTAMP DEFAULT {timestamp_default}
        )
    """)
    
    # Tracking logs table (Telemetry logs)
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS tracking_logs (
            id {pk_auto},
            booking_id INTEGER NOT NULL,
            provider_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TIMESTAMP DEFAULT {timestamp_default}
        )
    """)

    # Seed providers if table is empty
    # Check count query
    if IS_POSTGRES:
        cur.execute("SELECT COUNT(*) FROM providers")
        count = cur.fetchone()["count"]
    else:
        cur.execute("SELECT COUNT(*) FROM providers")
        count = cur.fetchone()[0]

    if count == 0:
        providers = [
            ("Tariq Mahmood", "tractor", 31.5204, 74.3587, 1, 4.8, 42),
            ("Muhammad Asif", "harvester", 31.4504, 73.1350, 1, 4.9, 58),
            ("Sajid Khan", "thresher", 30.1575, 71.5249, 1, 4.5, 19),
            ("Zafar Iqbal", "seeder", 32.0740, 72.6861, 1, 4.7, 31),
            ("Ahmed Ali", "tractor", 31.5580, 74.3900, 1, 4.2, 12),
            ("Khurram Shahzad", "tractor", 31.4800, 74.2800, 0, 4.6, 25),
        ]
        
        insert_query = """
            INSERT INTO providers (name, service_type, latitude, longitude, availability, rating, completed_jobs)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """ if IS_POSTGRES else """
            INSERT INTO providers (name, service_type, latitude, longitude, availability, rating, completed_jobs)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        
        cur.executemany(insert_query, providers)

    # Seed users if table is empty
    if IS_POSTGRES:
        cur.execute("SELECT COUNT(*) FROM users")
        count_users = cur.fetchone()["count"]
    else:
        cur.execute("SELECT COUNT(*) FROM users")
        count_users = cur.fetchone()[0]

    if count_users == 0:
        users = [
            ("+923001234567", "Bashir Ahmad", "farmer"),
            ("+923119876543", "Liaqat Ali", "provider"),
        ]
        
        insert_user_query = """
            INSERT INTO users (phone, name, role)
            VALUES (%s, %s, %s)
        """ if IS_POSTGRES else """
            INSERT INTO users (phone, name, role)
            VALUES (?, ?, ?)
        """
        
        cur.executemany(insert_user_query, users)

    conn.commit()
    conn.close()

# Initialize DB on startup
try:
    init_db()
except Exception as e:
    print(f"Database initialization error: {e}. Moving forward.")
