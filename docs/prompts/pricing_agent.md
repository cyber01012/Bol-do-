Prompt 1:
TASK: Understand Pricing Agent Architecture for BolDo

PROJECT:
BolDo — AI Service Orchestrator (Google Antigravity Hackathon)

SYSTEM CONTEXT:

BolDo is NOT a normal booking app.

It is an AI multi-agent orchestration system that:
- takes user service requests (Urdu / Roman Urdu / English)
- processes them through multiple agents
- generates reasoning at every step
- logs all decisions
- simulates end-to-end booking lifecycle

SUPPORTED SERVICES:
- AC Technician
- Electrician
- Plumber
- Carpenter
- Appliance Repair
- Home Cleaning
- Painter

TECH STACK:
- Flutter
- Firebase Firestore
- Firebase Auth
- Gemini API
- Antigravity orchestration

MULTI-AGENT PIPELINE:
Intent → Discovery → Ranking → Pricing → Booking → Notification → Follow-up → Dispute

SUPERVISOR CONTEXT:
A Supervisor/Orchestrator manages the entire pipeline flow, session tracking, and agent coordination.

GOAL:
Understand Pricing Agent role in this system and prepare architecture design only.
Do NOT generate full code yet.


Prompt 2:
TASK: Define Pricing Logic for Pricing Agent (BolDo)

PRICING RULES:

Base Price:
- basic = 500 PKR
- intermediate = 1000 PKR
- complex = 2000 PKR

Distance:
- 25 PKR per km

Urgency:
- same_day = 1.3x
- next_day = 1.0x
- flexible = 0.95x

Time Multipliers:
- night (10pm–6am) = 1.2x
- peak (12pm–2pm) = 1.1x
- normal = 1.0x

Loyalty:
- repeat customer = 5%–10% discount

FORMULA:
(total base + distance + complexity)
× urgency × time
− loyalty discount

RULES:
- round to nearest 50 PKR
- always return breakdown
- never return only final price
- must include confidence score

OUTPUT:
Return structured pricing algorithm design + breakdown logic only.
No Firestore or orchestration yet.


Prompt 3:
TASK: Define Input/Output Contract for Pricing Agent

INPUT FORMAT:
- selected_provider
- user_request
- ranking_metadata
- session_id
- request_id

OUTPUT FORMAT:
Must return:
- selected_provider
- pricing_data
- agent_trace_id
- orchestration_status
- ready_for_booking

VALIDATION RULES:
- handle missing distance
- handle invalid service type
- handle missing time
- price must be 500–15000 PKR range
- distance fee ≤ 50% of total
- graceful fallback required on failure

EDGE CASES:
1. no provider distance
2. corrupted ranking data
3. high urgency + night pricing conflict
4. first-time user (no loyalty discount)

OUTPUT:
Return structured contract design + validation rules + edge cases handling strategy only.
No code yet.


Prompt 4:
TASK: Implement Pricing Agent for BolDo (Full System)

Now generate full implementation.

MUST INCLUDE:

1. pricing_agent_service.dart
2. pricing_model.dart
3. pricing_calculator.dart
4. trace_logger.dart
5. firestore_service.dart

ORCHESTRATION:

- session_id tracking
- request_id tracking
- pipeline status tracking
- completed_agents list
- next_agent = Booking Agent

FIRESTORE COLLECTIONS:
- agent_traces
- pricing_logs
- orchestration_sessions

TRACE LOGGING:
- reasoning steps
- decision
- confidence
- timestamp

OUTPUT:
Must match Booking Agent contract.

RULES:
- modular code only
- no monolithic file
- async Firestore writes
- fully testable with mock data

Also generate:
- 3 test scenarios
- 1 failure scenario
- 1 success scenario
- 1 edge case scenario
