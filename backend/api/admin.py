from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict
from backend.database import get_connection
from backend.security import get_current_user

router = APIRouter()

@router.get("/metrics")
async def get_admin_metrics():
    """
    Exposes high-level platform stats and KPIs for the Admin Dashboard.
    """
    try:
        conn = get_connection()
        cur = conn.cursor()
        
        from backend.database import IS_POSTGRES
        is_postgres = IS_POSTGRES
        
        # 1. Total users
        cur.execute("SELECT COUNT(*) FROM users")
        total_users = cur.fetchone()[0] if not is_postgres else cur.fetchone()["count"]
        
        # 2. Total active providers
        cur.execute("SELECT COUNT(*) FROM providers WHERE availability = 1")
        active_providers = cur.fetchone()[0] if not is_postgres else cur.fetchone()["count"]
        
        # 3. Total bookings
        cur.execute("SELECT COUNT(*) FROM bookings")
        total_bookings = cur.fetchone()[0] if not is_postgres else cur.fetchone()["count"]
        
        # 4. Status breakdown
        cur.execute("SELECT status, COUNT(*) FROM bookings GROUP BY status")
        rows_status = cur.fetchall()
        status_breakdown = {}
        for row in rows_status:
            r = dict(row) if is_postgres else row
            status_breakdown[r[0] if not is_postgres else r["status"]] = r[1] if not is_postgres else r["count"]
            
        # 5. Services breakdown
        cur.execute("SELECT service_type, COUNT(*) FROM bookings GROUP BY service_type")
        rows_services = cur.fetchall()
        services_breakdown = {}
        for row in rows_services:
            r = dict(row) if is_postgres else row
            services_breakdown[r[0] if not is_postgres else r["service_type"]] = r[1] if not is_postgres else r["count"]
            
        # 6. Active disputes
        cur.execute("SELECT * FROM bookings WHERE status = 'disputed' ORDER BY id DESC")
        active_disputes = [dict(r) for r in cur.fetchall()]
        
        conn.close()
        
        return {
            "total_users": total_users,
            "active_providers": active_providers,
            "total_bookings": total_bookings,
            "status_breakdown": status_breakdown,
            "services_breakdown": services_breakdown,
            "active_disputes": active_disputes
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch admin metrics: {str(e)}")
