# Shared Data Types

This file defines reusable data structures used across the entire system.

Used By:
- frontend
- backend
- Firebase
- AI workflows
- logging system

---

# Primitive Types

## String

Represents text values.

Examples:
- "plumber"
- "DHA Phase 5"
- "tomorrow morning"

---

## Number

Represents numeric values.

Examples:
- 4.8
- 1200
- 2.5

---

## Boolean

Represents true or false values.

Examples:
- true
- false

---

## Timestamp

Represents date and time values.

Example:
2026-05-17T12:30:00Z

---

# Shared Object Types

## User Object

{
  "user_id": "",
  "name": "",
  "email": "",
  "phone_number": ""
}

Purpose:
Represents application users.

---

## Provider Object

{
  "provider_id": "",
  "name": "",
  "service_type": "",
  "rating": 0,
  "review_count": 0,
  "distance_km": 0,
  "availability": true,
  "reliability_score": 0,
  "cancellation_rate": 0,
  "price_range": "",
  "experience_years": 0
}

Purpose:
Represents service providers.

---

## Booking Object

{
  "booking_id": "",
  "user_id": "",
  "provider_id": "",
  "service_type": "",
  "scheduled_time": "",
  "booking_status": "",
  "estimated_price": 0
}

Purpose:
Represents booking records.

---

## Pricing Object

{
  "base_price": 0,
  "distance_fee": 0,
  "urgency_multiplier": 0,
  "complexity_adjustment": 0,
  "discount": 0,
  "final_price": 0
}

Purpose:
Represents pricing breakdown.

---

## Intent Object

{
  "service_type": "",
  "location": "",
  "preferred_time": "",
  "urgency": "",
  "budget_preference": "",
  "confidence_score": 0
}

Purpose:
Represents extracted user intent.

---

## Notification Object

{
  "notification_id": "",
  "type": "",
  "message": "",
  "timestamp": "",
  "status": ""
}

Purpose:
Represents system notifications.

---

## Dispute Object

{
  "dispute_id": "",
  "booking_id": "",
  "issue_type": "",
  "severity": "",
  "resolution_status": ""
}

Purpose:
Represents complaint and dispute workflows.

---

## Voice Input Object

{
  "audio_id": "",
  "language_detected": "",
  "transcribed_text": "",
  "confidence_score": 0
}

Purpose:
Represents processed voice input.

---

## Voice Output Object

{
  "message_text": "",
  "audio_generated": true,
  "language": ""
}

Purpose:
Represents AI-generated voice responses.

---

## Log Object

{
  "agent": "",
  "workflow_stage": "",
  "decision": "",
  "reasoning": "",
  "action_taken": "",
  "severity": "",
  "timestamp": ""
}

Purpose:
Represents structured system logs.

---

# Collection Types

## Provider List

Type:
Array<Provider Object>

---

## Booking List

Type:
Array<Booking Object>

---

## Notification List

Type:
Array<Notification Object>

---

# Shared Enums

## Booking Status

Possible Values:
- pending
- confirmed
- completed
- cancelled
- disputed

---

## Urgency Levels

Possible Values:
- low
- medium
- high

---

## Job Complexity Levels

Possible Values:
- basic
- intermediate
- complex

---

## Log Severity Levels

Possible Values:
- info
- warning
- critical

---

# Important Rules

- Keep all shared object structures consistent.
- Avoid duplicate object definitions in other files.
- Update this file before modifying API structures.
- Frontend and backend must follow these types strictly.