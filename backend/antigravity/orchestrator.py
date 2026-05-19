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

class AntigravityOrchestrator:
    """Central orchestrator that coordinates AI agents and builds reasoning traces."""

    def __init__(self):
        self.traces: Dict[str, List[Dict[str, Any]]] = {}
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.use_mock = False

        if not self.api_key or "your_gemini_api" in self.api_key.lower() or len(self.api_key.strip()) < 10:
            print("WARNING: GEMINI_API_KEY is missing or invalid! Operating in Offline/Mock reasoning tracer mode.")
            self.use_mock = True
        else:
            try:
                genai.configure(api_key=self.api_key)
                print("Google Antigravity Engine: Real Gemini API integration activated successfully!")
            except Exception as e:
                print(f"WARNING: Error configuring Gemini API: {e}. Falling back to Offline/Mock mode.")
                self.use_mock = True

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

        if self.use_mock:
            # Simple keyword matching for demo/fallback purposes
            service_type = "tractor"
            for s in ["harvester", "thresher", "seeder"]:
                if s in raw_input.lower():
                    service_type = s
                    break
            
            location = "Lahore"
            for loc in ["multan", "faisalabad", "sargodha", "karachi", "peshawar", "quetta", "sialkot"]:
                if loc in raw_input.lower():
                    location = loc.capitalize()
                    break
            
            urgency = "normal"
            if any(k in raw_input.lower() for k in ["jaldi", "urgent", "emergency", "fauri"]):
                urgency = "high"
                
            intent = {
                "service_type": service_type,
                "location": location,
                "urgency": urgency,
                "scheduled_time": "2026-05-20T08:00:00",
                "confidence": 0.98,
                "transcript_parsed": f"Requesting a {service_type} in {location} with {urgency} urgency."
            }
            self.add_step(request_id, "ZabaanAI NLP: Intent Parsed", intent)

            complexity_level = "High-Urgency" if urgency == "high" else "Standard"
            requires_escrow = urgency == "high" or service_type in ["harvester", "thresher"]
            complexity_details = {
                "level": complexity_level,
                "risk_score": 0.85 if urgency == "high" else 0.15,
                "requires_escrow": requires_escrow,
                "confidence": 0.95
            }
            self.add_step(request_id, "AgriComplex: Complexity Classified", complexity_details)

            # SmartMatch
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT * FROM providers WHERE service_type = ? ORDER BY availability DESC, rating DESC", (service_type,))
            rows = cur.fetchall()
            if not rows:
                cur.execute("SELECT * FROM providers ORDER BY rating DESC")
                rows = cur.fetchall()
            matched_providers = [dict(row) for row in rows]
            conn.close()

            selected_provider = matched_providers[0]
            selected_provider_id = selected_provider["id"]
            selected_provider_name = selected_provider["name"]

            smartmatch_details = {
                "candidates": [
                    {"id": p["id"], "name": p["name"], "score": p["rating"]/5.0, "available": p["availability"]}
                    for p in matched_providers[:3]
                ],
                "selected_provider_id": selected_provider_id,
                "selected_provider_name": selected_provider_name,
                "reasoning": f"Behtareen operator {selected_provider_name} ko chun liya gaya hai kyun ke in ki rating {selected_provider['rating']} hai."
            }
            self.add_step(request_id, "SmartMatch: Providers Ranked", smartmatch_details)

            # FairPrice
            base_rate = 3000.0 if service_type == "tractor" else (5000.0 if service_type == "harvester" else 4000.0)
            urgency_fee = 500.0 if urgency == "high" else 0.0
            total_price = base_rate + urgency_fee
            price_info = {
                "base_rate": base_rate,
                "urgency_fee": urgency_fee,
                "provider_experience_premium": 200.0,
                "applied_discount": 0.0,
                "currency": "PKR",
                "total_price": total_price,
                "justification": f"Base rate {base_rate} PKR standard rate hai."
            }
            self.add_step(request_id, "FairPrice AI: Pricing Calculated", price_info)

            # ScheduleMind
            slot = {
                "scheduled_time": "2026-05-20T08:00:00",
                "conflict_detected": False,
                "buffer_minutes": 30,
                "duration_hours": 4,
                "recommendation": "Aap ka time slot confirm kar diya gaya hai. Shukriya!"
            }
            self.add_step(request_id, "ScheduleMind: Slot Confirmed", slot)

            # NotifyHub
            notification_details = {
                "method": "SMS",
                "farmer_phone": "+923001234567",
                "provider_phone": "+923119876543",
                "farmer_message": f"KissanAI Alert: Aap ki booking baraye {service_type} operator {selected_provider_name} ke sath confirm ho gayi hai. Price: PKR {total_price}.",
                "provider_message": f"KissanAI Alert: Nayi booking mili hai. {service_type} ki zaroorat hai. Price: PKR {total_price}."
            }
            self.add_step(request_id, "NotifyHub: Notification Dispatched", notification_details)

            # Save to DB
            conn = get_connection()
            cur = conn.cursor()
            cur.execute('''
                INSERT INTO bookings (user_id, provider_id, service_type, location, urgency, scheduled_time, status, price)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                user_id,
                selected_provider_id,
                service_type,
                location,
                urgency,
                "2026-05-20T08:00:00",
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
        intent = json.loads(response_zabaan.text)
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
        complexity_details = json.loads(response_agri.text)
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
        smartmatch_details = json.loads(response_smart.text)
        
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
        price_info = json.loads(response_price.text)
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
        slot = json.loads(response_schedule.text)
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
        notification_details = json.loads(response_notify.text)
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

        if self.use_mock:
            dispute_received = {
                "booking_id": booking_id,
                "reason": reason,
                "farmer_claim": reason,
                "provider_name": provider['name']
            }
            self.add_step(request_id, "ResolveAI: Dispute Received", dispute_received)

            context_analyzed = {
                "provider_rating": provider['rating'],
                "provider_completed_jobs": provider['completed_jobs'],
                "booking_original_price": booking['price'],
                "fault_probability": 0.65
            }
            self.add_step(request_id, "ResolveAI: Context Analyzed", context_analyzed)

            original_price = booking['price']
            discount_amount = original_price * 0.15
            resolved_price = original_price - discount_amount

            settlement_formulated = {
                "original_price": original_price,
                "discount_amount": discount_amount,
                "resolved_price": resolved_price,
                "farmer_satisfaction_score": 0.85,
                "provider_acceptance": True
            }
            self.add_step(request_id, "ResolveAI: Settlement Formulated", settlement_formulated)

            resolution_message = f"ResolveAI ne faisla kiya hai ke farmer ko 15% discount (PKR {discount_amount}) diya jaye. Nayi qeemat PKR {resolved_price} hai."
            
            cur.execute(
                "UPDATE bookings SET status = 'resolved', price = ? WHERE id = ?",
                (resolved_price, booking_id)
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
        res_json = json.loads(response.text)

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
