# Agent Pipeline Architecture

Project:
BolDo — AI Service Orchestrator

Purpose:
This document defines the complete agent orchestration workflow, execution order, communication flow, fallback logic, and synchronization behavior between all AI agents in the system.

---

# Core Workflow Overview

User Input
→ Voice/Text Processing
→ Intent Agent
→ Discovery Agent
→ Ranking Agent
→ Pricing Agent
→ Booking Agent
→ Notification Agent
→ Follow-up Agent
→ Dispute Agent (if triggered)

---

# High-Level Agent Flow

┌────────────────────┐
│ User Request       │
│ (Text or Voice)    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Voice Agent        │
│ Speech Processing  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Intent Agent       │
│ NLP Understanding  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Discovery Agent    │
│ Provider Search    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Ranking Agent      │
│ Multi-Factor Score │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Pricing Agent      │
│ Cost Estimation    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Booking Agent      │
│ Slot Reservation   │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Notification Agent │
│ Confirmation/Alert │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Follow-up Agent    │
│ Reminders/Feedback │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Dispute Agent      │
│ Failure Resolution │
└────────────────────┘

---

# Detailed Agent Execution Flow

## 1. Voice Agent

Purpose:
Handles speech input and speech output.

Input:
- Audio input from user

Output:
- Converted text
- Voice confirmations

Workflow:
- Speech-to-text conversion
- Noise filtering
- Language normalization

Failure Handling:
- Ask user to repeat voice input

Execution Type:
Synchronous

---

## 2. Intent Agent

Purpose:
Understands user request.

Input:
- User text query

Output:
{
  "service_type": "",
  "location": "",
  "time": "",
  "urgency": "",
  "confidence": 0.0
}

Workflow:
1. Detect language
2. Normalize text
3. Extract entities
4. Calculate confidence

Failure Handling:
If confidence < 0.65:
- Ask clarification question

Execution Type:
Synchronous

Connected Agents:
- Discovery Agent
- Pricing Agent

---

## 3. Discovery Agent

Purpose:
Finds relevant providers.

Input:
- Service type
- Location

Output:
- Nearby providers list

Workflow:
1. Query Firestore
2. Filter by service
3. Filter by distance
4. Check availability

Failure Handling:
- Suggest alternate providers
- Suggest alternate timings

Execution Type:
Synchronous

Connected Agents:
- Ranking Agent

---

## 4. Ranking Agent

Purpose:
Ranks providers intelligently.

Input:
- Provider candidates

Output:
- Ranked providers
- Ranking reasons

Ranking Factors:
- Distance
- Availability
- Ratings
- Reliability
- Cancellation rate
- Skill specialization
- Budget compatibility

Execution Type:
Synchronous

Connected Agents:
- Pricing Agent
- Booking Agent

Failure Handling:
- Re-run ranking with relaxed filters

---

## 5. Pricing Agent

Purpose:
Generates dynamic pricing.

Input:
- Selected provider
- Service details
- Distance
- Urgency

Output:
{
  "base_fee": 0,
  "distance_fee": 0,
  "urgency_multiplier": 0,
  "discount": 0,
  "total_price": 0
}

Workflow:
- Calculate service cost
- Apply urgency multiplier
- Apply discounts

Execution Type:
Synchronous

Connected Agents:
- Booking Agent

Failure Handling:
- Use fallback pricing

---

## 6. Booking Agent

Purpose:
Simulates booking confirmation.

Input:
- Selected provider
- Time slot

Output:
{
  "booking_id": "",
  "status": "confirmed"
}

Workflow:
1. Check provider availability
2. Prevent overlap
3. Reserve slot
4. Save booking
5. Generate receipt

Execution Type:
Synchronous

Connected Agents:
- Notification Agent
- Follow-up Agent
- Dispute Agent

Failure Handling:
- Retry alternate provider

---

## 7. Notification Agent

Purpose:
Handles updates and reminders.

Input:
- Booking events

Output:
- Confirmation messages
- Reminder notifications

Workflow:
- Generate notifications
- Simulate WhatsApp/SMS
- Send reminders

Execution Type:
Asynchronous

Connected Agents:
- Follow-up Agent

Failure Handling:
- Retry notification delivery

---

## 8. Follow-up Agent

Purpose:
Tracks booking lifecycle.

Input:
- Booking status

Output:
- Completion updates
- Feedback collection

Workflow:
1. Reminder scheduling
2. Completion tracking
3. Feedback requests
4. Rating updates

Execution Type:
Asynchronous

Connected Agents:
- Dispute Agent

Failure Handling:
- Escalate unresolved cases

---

## 9. Dispute Agent

Purpose:
Handles booking failures and complaints.

Input:
- Complaints
- Cancellations
- Failed bookings

Output:
- Refund simulation
- Escalation workflow
- Reassignment suggestions

Supported Cases:
- Provider cancellation
- No-show
- Quality complaint
- Price dispute
- Double booking conflict

Execution Type:
Hybrid (Sync + Async)

Connected Agents:
- Booking Agent
- Notification Agent
- Follow-up Agent
- Ranking Agent

Failure Handling:
- Human escalation simulation

---

# Workflow Categories

## Synchronous Workflows

These must complete immediately:
- Intent extraction
- Discovery
- Ranking
- Pricing
- Booking validation

---

## Asynchronous Workflows

These run in background:
- Notifications
- Reminders
- Feedback collection
- Follow-ups

---

# Timeout Configuration

| Agent | Timeout |
|---|---|
| Voice Agent | 5 sec |
| Intent Agent | 5 sec |
| Discovery Agent | 3 sec |
| Ranking Agent | 2 sec |
| Pricing Agent | 2 sec |
| Booking Agent | 5 sec |
| Notification Agent | 10 sec |
| Follow-up Agent | 15 sec |

---

# Retry Logic

Retry Attempts:
3

Retry Strategy:
Exponential backoff

Fallback:
Trigger alternate workflow

---

# Logging Requirements

Each agent must generate logs containing:

{
  "agent": "",
  "input": {},
  "decision": "",
  "reasoning": "",
  "output": {},
  "timestamp": ""
}

---

# Edge Case Handling

## No Provider Available
- Suggest alternate timing
- Relax ranking constraints

---

## Low Confidence Input
- Ask clarification question

---

## Provider Cancellation
- Trigger re-ranking workflow

---

## Double Booking
- Lock provider slot
- Prevent duplicate reservation

---

# Future Scalability

Future improvements:
- Real-time provider tracking
- AI demand forecasting
- Smart provider load balancing
- Real payment integration
- Live WhatsApp API integration