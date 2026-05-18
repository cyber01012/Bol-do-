# user-request-flow.md

# User Request Workflow

Purpose:
Defines the complete execution lifecycle from user input to booking completion.

---

# Workflow Sequence

User Input
→ Voice/Text Processing
→ Intent Extraction
→ Provider Discovery
→ Provider Ranking
→ Dynamic Pricing
→ Booking Simulation
→ Notification Generation
→ Follow-up Automation
→ Dispute Handling (if triggered)

---

# Step 1 — User Input

Supported Inputs:
- Urdu
- Roman Urdu
- English
- Mixed language
- Voice input

Examples:
- "Kal subah plumber chahiye"
- "Need AC technician tomorrow"
- "Mujhe electrician DHA mein chahiye"

---

# Step 2 — Voice/Text Processing

Responsible Agent:
Voice Agent

Tasks:
- speech-to-text conversion
- noise reduction
- text normalization
- language detection

Output:
Clean normalized text

---

# Step 3 — Intent Extraction

Responsible Agent:
Intent Agent

Tasks:
- extract service type
- extract location
- extract time
- detect urgency
- calculate confidence score

Output Example:

{
  "service_type": "AC Technician",
  "location": "DHA",
  "time": "Tomorrow Morning",
  "urgency": "Medium",
  "confidence": 0.91
}

---

# Step 4 — Provider Discovery

Responsible Agent:
Discovery Agent

Tasks:
- search providers
- filter by category
- filter by location
- validate availability

Output:
List of providers

---

# Step 5 — Ranking

Responsible Agent:
Ranking Agent

Ranking Factors:
- distance
- availability
- reliability
- review recency
- cancellation rate
- specialization
- pricing compatibility

Output:
Top ranked providers

---

# Step 6 — Pricing

Responsible Agent:
Pricing Agent

Tasks:
- calculate base price
- apply urgency multiplier
- calculate travel surcharge
- apply discounts

Output:
Detailed pricing breakdown

---

# Step 7 — Booking

Responsible Agent:
Booking Agent

Tasks:
- validate time slot
- prevent double booking
- create booking record
- generate booking ID

Output:
Booking confirmation

---

# Step 8 — Notifications

Responsible Agent:
Notification Agent

Tasks:
- confirmation message
- reminder scheduling
- booking updates

---

# Step 9 — Follow-up

Responsible Agent:
Follow-up Agent

Tasks:
- collect feedback
- update ratings
- track completion

---

# Step 10 — Dispute Handling

Responsible Agent:
Dispute Agent

Triggered When:
- cancellation
- no-show
- price complaint
- service quality complaint

---

# Failure Handling

Low Confidence:
→ clarification request

No Provider Found:
→ alternate timings

Booking Conflict:
→ slot reassignment

---

# Logging Requirements

Every stage must generate:
- input logs
- reasoning logs
- output logs
- timestamps