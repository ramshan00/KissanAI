import uuid
import re
import os
import json
from typing import Dict, Any, List
from dotenv import load_dotenv
import google.generativeai as genai
from backend.database import get_connection

# Load environment variables from .env
load_dotenv()

def safe_json_loads(text: str) -> Dict[str, Any]:
    text = text.strip()
    try:
        return json.loads(text)
    except Exception:
        import re
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except Exception:
                pass
        text = text.replace('```json', '').replace('```', '').strip()
        return json.loads(text)


class AntigravityOrchestrator:
    """Central orchestrator that coordinates AI agents and builds reasoning traces."""

    def __init__(self):
        self.traces: Dict[str, List[Dict[str, Any]]] = {}
        self.api_key = os.getenv("GEMINI_API_KEY")

        if not self.api_key or "your_gemini_api" in self.api_key.lower() or len(self.api_key.strip()) < 10:
            raise Exception("GEMINI_API_KEY is missing or invalid! Production mode requires real API integrations.")
        
        genai.configure(api_key=self.api_key)
        print("Google Antigravity Engine: Real Gemini API integration activated successfully!")

    def start_trace(self, request_id: str = None) -> str:
        request_id = request_id or str(uuid.uuid4())
        self.traces[request_id] = []
        return request_id

    def add_step(self, request_id: str, step_name: str, details: Dict[str, Any]):
        if request_id not in self.traces:
            raise ValueError(f"Trace for {request_id} not found")
        self.traces[request_id].append({"step": step_name, "details": details})

    def get_trace(self, request_id: str) -> List[Dict[str, Any]]:
        return self.traces.get(request_id, [])

    async def orchestrate_booking(self, raw_input: str, user_id: int) -> Dict[str, Any]:
        request_id = self.start_trace()

        # ---- Step 1: Language understanding (ZabaanAI NLP) ----
        model = genai.GenerativeModel("gemini-3.1-flash-lite")
        prompt_zabaan = f"""
        You are ZabaanAI, the advanced Urdu/English Natural Language Processor for KissanAI.
        Analyze the following agricultural booking request from a Pakistani farmer:
        "{raw_input}"

        Extract the following details as a valid JSON object with the exact keys:
        - "service_type": Must be one of: "tractor", "harvester", "thresher", "seeder". Default to "tractor" if not specified.
        - "location": The Pakistani city or district mentioned. Default to "Lahore".
        - "urgency": Either "high" (if user says urgent, jaldi, emergency) or "normal".
        - "scheduled_time": Estimate the scheduled slot as an ISO-8601 string (YYYY-MM-DDTHH:MM:SS) based on dates mentioned.
        - "confidence": A float between 0.85 and 0.99 indicating your understanding level.
        - "transcript_parsed": A clean, grammatically correct English translation/transcript of the query.

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_zabaan = model.generate_content(
            prompt_zabaan,
            generation_config={"response_mime_type": "application/json"}
        )
        intent = safe_json_loads(response_zabaan.text)
        service_type = intent.get("service_type", "tractor")
        location = intent.get("location", "Lahore")
        urgency = intent.get("urgency", "normal")
        scheduled_time = intent.get("scheduled_time", "2026-05-20T08:00:00")
        
        self.add_step(request_id, "ZabaanAI NLP: Intent Parsed", intent)

        # ---- Step 2: Complexity classification (AgriComplex) ----
        prompt_agri = f"""
        You are AgriComplex AI, the risk and complexity classifier for KissanAI.
        Analyze this parsed booking intent:
        Service Type: {service_type}
        Location: {location}
        Urgency: {urgency}
        Scheduled Time: {scheduled_time}
        User Input: "{raw_input}"

        Determine the complexity of this transaction and output a JSON object with these keys:
        - "level": One of "Standard", "High-Urgency", "Heavy-Machinery", "High-Risk-Complex".
        - "risk_score": A float between 0.05 and 0.95.
        - "requires_escrow": Boolean (true if complexity is not Standard, false otherwise).
        - "confidence": A float between 0.90 and 0.99.

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_agri = model.generate_content(
            prompt_agri,
            generation_config={"response_mime_type": "application/json"}
        )
        complexity_details = safe_json_loads(response_agri.text)
        self.add_step(request_id, "AgriComplex: Complexity Classified", complexity_details)

        # ---- Step 3: Provider ranking (SmartMatch) ----
        conn = get_connection()
        cur = conn.cursor()

        cur.execute(
            "SELECT * FROM providers WHERE service_type = ? ORDER BY availability DESC, rating DESC",
            (service_type,)
        )
        rows = cur.fetchall()

        if not rows:
            cur.execute("SELECT * FROM providers ORDER BY rating DESC")
            rows = cur.fetchall()

        matched_providers = []
        for row in rows:
            p = dict(row)
            matched_providers.append(p)
            
        if not matched_providers:
            raise Exception("No providers found in the database. Cannot match booking.")

        providers_data = []
        for p in matched_providers[:5]:
            providers_data.append({
                "id": p["id"],
                "name": p["name"],
                "service_type": p["service_type"],
                "rating": p["rating"],
                "completed_jobs": p["completed_jobs"],
                "availability": p["availability"]
            })

        prompt_smart = f"""
        You are SmartMatch AI, the provider matcher for KissanAI.
        Your job is to match the best provider for the farmer's request:
        Request Service: {service_type} in {location} with {urgency} urgency.

        Here are the candidate providers from our database:
        {json.dumps(providers_data)}

        Rank them based on compatibility, rating, completed jobs, and availability. Availability = 1 is strongly preferred.
        Return a JSON object with these exact keys:
        - "candidates": List of top 3 candidates, each with "id" (int), "name" (string), "score" (float), "available" (int)
        - "selected_provider_id": Integer ID of the chosen provider
        - "selected_provider_name": Name of the chosen provider
        - "reasoning": A brief explanation in Urdu/English of why they were chosen.

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_smart = model.generate_content(
            prompt_smart,
            generation_config={"response_mime_type": "application/json"}
        )
        smartmatch_details = safe_json_loads(response_smart.text)
        
        selected_provider_id = smartmatch_details.get("selected_provider_id")
        selected_provider_name = smartmatch_details.get("selected_provider_name")
        
        selected_provider = next((p for p in matched_providers if p["id"] == selected_provider_id), matched_providers[0])
        
        self.add_step(request_id, "SmartMatch: Providers Ranked", smartmatch_details)

        # ---- Step 4: Pricing (FairPrice AI) ----
        prompt_price = f"""
        You are FairPrice AI, the dynamic pricing engine for KissanAI.
        Calculate the fair rental price in PKR for:
        Service: {service_type}
        Location: {location}
        Urgency: {urgency}
        Provider Rating: {selected_provider.get('rating', 4.8)}
        Provider Completed Jobs: {selected_provider.get('completed_jobs', 30)}

        Return a JSON object with these keys:
        - "base_rate": Float
        - "urgency_fee": Float
        - "provider_experience_premium": Float
        - "applied_discount": Float (negative or zero)
        - "currency": "PKR"
        - "total_price": Float
        - "justification": Brief dynamic explanation of why this pricing is fair.

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_price = model.generate_content(
            prompt_price,
            generation_config={"response_mime_type": "application/json"}
        )
        price_info = safe_json_loads(response_price.text)
        total_price = price_info.get("total_price", 3500.0)
        self.add_step(request_id, "FairPrice AI: Pricing Calculated", price_info)

        # ---- Step 5: Scheduling (ScheduleMind) ----
        prompt_schedule = f"""
        You are ScheduleMind AI, the scheduling coordinator for KissanAI.
        Analyze the scheduling slot:
        Scheduled Time: {scheduled_time}
        Provider Availability: {selected_provider.get('availability', 1)}
        Service Type: {service_type}

        Return a JSON object with these keys:
        - "scheduled_time": ISO string
        - "conflict_detected": Boolean
        - "buffer_minutes": Integer
        - "duration_hours": Estimated duration
        - "recommendation": Brief Roman Urdu advice on matching

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_schedule = model.generate_content(
            prompt_schedule,
            generation_config={"response_mime_type": "application/json"}
        )
        slot = safe_json_loads(response_schedule.text)
        scheduled_time = slot.get("scheduled_time", scheduled_time)
        self.add_step(request_id, "ScheduleMind: Slot Confirmed", slot)

        # ---- Step 6: Notification (NotifyHub) ----
        prompt_notify = f"""
        You are NotifyHub AI, the notification generator for KissanAI.
        Generate localized, polite SMS alerts in Roman Urdu for the farmer and the provider.

        Booking details:
        Farmer Name: Bashir Ahmad
        Provider Name: {selected_provider_name}
        Service: {service_type}
        Location: {location}
        Price: PKR {total_price}
        Scheduled Time: {scheduled_time}

        Output a JSON object with these keys:
        - "method": "SMS"
        - "farmer_phone": "+923001234567"
        - "provider_phone": "+923119876543"
        - "farmer_message": Roman Urdu SMS alert for the farmer.
        - "provider_message": Roman Urdu SMS alert for the provider.

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response_notify = model.generate_content(
            prompt_notify,
            generation_config={"response_mime_type": "application/json"}
        )
        notification_details = safe_json_loads(response_notify.text)
        self.add_step(request_id, "NotifyHub: Notification Dispatched", notification_details)

        # Save to database
        cur.execute('''
            INSERT INTO bookings (user_id, provider_id, service_type, location, urgency, scheduled_time, status, price)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            user_id,
            selected_provider_id,
            service_type,
            location,
            urgency,
            scheduled_time,
            "confirmed",
            total_price
        ))
        conn.commit()

        booking_id = cur.lastrowid
        cur.execute("SELECT * FROM bookings WHERE id = ?", (booking_id,))
        booking_row = dict(cur.fetchone())
        conn.close()

        return {
            "booking": booking_row,
            "trace": self.get_trace(request_id)
        }

    async def resolve_dispute(self, booking_id: int, reason: str) -> Dict[str, Any]:
        request_id = self.start_trace()
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM bookings WHERE id = ?", (booking_id,))
        booking_row = cur.fetchone()

        if not booking_row:
            raise ValueError(f"Booking {booking_id} not found")

        booking = dict(booking_row)
        cur.execute("SELECT * FROM providers WHERE id = ?", (booking["provider_id"],))
        provider = dict(cur.fetchone())

        model = genai.GenerativeModel("gemini-3.1-flash-lite")
        prompt = f"""
        You are ResolveAI, the dynamic dispute mediator for KissanAI.
        You are mediating a dispute between:
        Farmer (complaining: "{reason}")
        Provider: {provider['name']} (Rating: {provider['rating']}, Completed Jobs: {provider['completed_jobs']})
        Booking Details:
        Service: {booking['service_type']} in {booking['location']}
        Original Price: PKR {booking['price']}
        Scheduled Time: {booking['scheduled_time']}

        Generate realistic JSON outputs with these keys:
        - "dispute_received": Dict containing "booking_id", "reason", "farmer_claim", "provider_name"
        - "context_analyzed": Dict containing "provider_rating", "provider_completed_jobs", "booking_original_price", "fault_probability"
        - "settlement_formulated": Dict containing "original_price", "discount_amount", "resolved_price", "farmer_satisfaction_score", "provider_acceptance" (true)
        - "status_updated": Dict containing "new_status" ("resolved"), "message" (resolution message explaining the discount)

        Only output valid JSON. Do not include markdown formatting like ```json or anything else.
        """
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        res_json = safe_json_loads(response.text)

        self.add_step(request_id, "ResolveAI: Dispute Received", res_json.get("dispute_received", {}))
        self.add_step(request_id, "ResolveAI: Context Analyzed", res_json.get("context_analyzed", {}))
        self.add_step(request_id, "ResolveAI: Settlement Formulated", res_json.get("settlement_formulated", {}))
        
        status_up = res_json.get("status_updated", {})
        resolution_message = status_up.get("message", "Resolved")
        new_price = res_json.get("settlement_formulated", {}).get("resolved_price", booking['price'])

        cur.execute(
            "UPDATE bookings SET status = 'resolved', price = ? WHERE id = ?",
            (new_price, booking_id)
        )
        conn.commit()

        self.add_step(request_id, "ResolveAI: Status Updated", {
            "new_status": "resolved",
            "message": resolution_message
        })

        cur.execute("SELECT * FROM bookings WHERE id = ?", (booking_id,))
        updated_booking = dict(cur.fetchone())
        conn.close()

        return {
            "booking": updated_booking,
            "trace": self.get_trace(request_id)
        }

antigravity = AntigravityOrchestrator()
