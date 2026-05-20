# BolDo Booking Agent: Contracts & Firestore Models Reference

This document serves as the permanent reference for the Booking Agent’s Input and Output JSON contracts, Firestore collections, and validation guardrails.

---

## 1. JSON Schema Contracts

### A. Input Contract (From Pricing Agent)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BookingAgentInputContract",
  "type": "object",
  "properties": {
    "request_id": {
      "type": "string",
      "description": "Unique tracking ID for the specific orchestrator request"
    },
    "session_id": {
      "type": "string",
      "description": "Unique identifier of the orchestration session thread"
    },
    "orchestration_status": {
      "type": "string",
      "enum": ["success", "degraded", "failed"],
      "description": "Orchestration status from the preceding Pricing stage"
    },
    "selected_provider": {
      "type": "object",
      "properties": {
        "provider_id": {
          "type": "string",
          "description": "Unique provider record ID in Firestore"
        },
        "name": {
          "type": "string",
          "description": "Human-readable name of the selected provider"
        },
        "service_type": {
          "type": "string",
          "description": "Technician category type (e.g. ac_technician)"
        }
      },
      "required": ["provider_id", "service_type"]
    },
    "pricing_data": {
      "type": "object",
      "properties": {
        "total_price_pkr": {
          "type": "number",
          "minimum": 0,
          "description": "Total subtotal amount calculated by Pricing Agent"
        },
        "confidence_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Precision confidence from pricing multipliers"
        },
        "breakdown": {
          "type": "object",
          "description": "Pricing subcomponents"
        }
      },
      "required": ["total_price_pkr"]
    },
    "user_request": {
      "type": "object",
      "properties": {
        "service_type": { "type": "string" },
        "urgency": { "type": "string" },
        "requested_time": {
          "type": "string",
          "format": "date-time"
        }
      },
      "required": ["service_type", "requested_time"]
    },
    "booking_metadata": {
      "type": "object",
      "properties": {
        "payment_method": { "type": "string" }
      }
    }
  },
  "required": [
    "request_id",
    "session_id",
    "orchestration_status",
    "selected_provider",
    "pricing_data",
    "user_request"
  ]
}
```

### B. Output Contract (To Notification Agent)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BookingAgentOutputContract",
  "type": "object",
  "properties": {
    "booking_id": {
      "type": "string",
      "description": "Unique booking reference ID (format: book_[session_id])"
    },
    "booking_status": {
      "type": "string",
      "enum": ["pending", "confirmed", "provider_assigned", "failed"],
      "description": "Official scheduling state of the provider slot"
    },
    "provider": {
      "type": "object",
      "properties": {
        "provider_id": { "type": "string" },
        "name": { "type": "string" },
        "service_type": { "type": "string" }
      },
      "required": ["provider_id", "service_type"]
    },
    "scheduled_time": {
      "type": "string",
      "format": "date-time",
      "description": "ISO-8601 timestamp representing the confirmed slot time"
    },
    "customer_summary": {
      "type": "object",
      "properties": {
        "customer_id": {
          "type": "string",
          "description": "Unique user reference ID of the consumer"
        },
        "name": {
          "type": "string",
          "description": "Name of the customer receiving the technician"
        },
        "contact_number": {
          "type": "string",
          "description": "Verified telephone or SMS contact for staging alert notifications"
        }
      },
      "required": ["customer_id"]
    },
    "notification_required": {
      "type": "boolean",
      "description": "Flags true to trigger alert dispatching inside the Notification Agent"
    },
    "orchestration_metadata": {
      "type": "object",
      "properties": {
        "session_id": { "type": "string" },
        "request_id": { "type": "string" },
        "trace_id": { "type": "string" },
        "orchestration_status": {
          "type": "string",
          "enum": ["success", "degraded", "failed"]
        },
        "current_agent": {
          "type": "string",
          "const": "BookingAgent"
        },
        "next_agent": {
          "type": "string",
          "const": "NotificationAgent"
        }
      },
      "required": [
        "session_id",
        "request_id",
        "trace_id",
        "orchestration_status",
        "current_agent",
        "next_agent"
      ]
    },
    "alternative_recommendation": {
      "type": ["object", "null"],
      "properties": {
        "provider_id": { "type": "string" },
        "name": { "type": "string" },
        "rating": { "type": "number" },
        "service_type": { "type": "string" },
        "reason": { "type": "string" }
      },
      "required": ["provider_id", "name", "rating", "service_type"]
    }
  },
  "required": [
    "booking_id",
    "booking_status",
    "provider",
    "scheduled_time",
    "customer_summary",
    "notification_required",
    "orchestration_metadata"
  ]
}
```

---

## 2. Firestore Collection structures

### A. `bookings` Collection
* **Path:** `/bookings/{booking_id}` (where `booking_id` matches `book_{session_id}`)
```json
{
  "booking_id": "book_sess_xyz789",
  "provider_id": "prov_456",
  "customer_id": "user_customer_999",
  "service_type": "ac_technician",
  "booking_status": "confirmed",
  "scheduled_time": "2026-05-19T23:00:00Z",
  "final_price": 1450.0,
  "session_id": "sess_xyz789",
  "request_id": "req_abc123",
  "created_at": "2026-05-19T01:54:00Z",
  "updated_at": "2026-05-19T01:54:05Z"
}
```

### B. `agent_traces` Collection
* **Path:** `/agent_traces/{trace_id}`
```json
{
  "trace_id": "trace_book_1715800000_332",
  "session_id": "sess_xyz789",
  "request_id": "req_abc123",
  "current_agent": "BookingAgent",
  "next_agent": "NotificationAgent",
  "orchestration_status": "success",
  "decision": "Booking confirmed with Ali AC Repair.",
  "reasoning": "Provider AC Repair is active, availability check cleared, slot overlap check yielded zero conflicts, and Gemini simulated outreach received confirmation.",
  "confidence": 0.98,
  "timestamp": "2026-05-19T01:54:05Z"
}
```

### C. `orchestration_sessions` Collection
* **Path:** `/orchestration_sessions/{session_id}`
```json
{
  "session_id": "sess_xyz789",
  "completed_agents": {
    "IntentAgent": true,
    "DiscoveryAgent": true,
    "RankingAgent": true,
    "PricingAgent": true,
    "BookingAgent": true
  },
  "last_updated": "2026-05-19T01:54:05Z",
  "pipeline_status": "success",
  "active_booking_id": "book_sess_xyz789"
}
```

---

## 3. Core Validation & Business Rules

1. **Schema Check:** All key properties (`session_id`, `request_id`, `provider_id`, `service_type`, `requested_time`, `total_price_pkr`) must be non-empty and formatted correctly.
2. **Pricing Clamping Fallback:** If `total_price_pkr` is null or $\le 0$:
   - Clamp calculated final subtotal to **500.0 PKR** (baseline minimal service fee).
   - Log a trace warning of price reconstruction.
   - Transition pipeline status to **`degraded`** but proceed to allocate the technician.
3. **Double Booking Overlap check:**
   - Execute a query on `bookings` for the targeted `provider_id` where `booking_status` is in `['confirmed', 'provider_assigned', 'in_progress']`.
   - Check if any record's `requested_time` falls within a **+/- 2-hour buffer window** of the requested `requested_time`.
   - If an overlap exists, reject scheduling immediately, write a conflict trace to `/agent_traces`, and generate a ranked alternative.
