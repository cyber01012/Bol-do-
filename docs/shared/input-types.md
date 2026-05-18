# Shared Input Types

This file defines reusable input structures used across the application.

Used By:
- frontend
- backend
- AI workflows
- Firebase services

---

# User Query Input

Type:
String

Purpose:
Represents natural language service requests from users.

Supported Languages:
- Urdu
- Roman Urdu
- English
- Mixed language input

Examples:
- "Kal subah electrician chahiye"
- "Need AC technician today"
- "Mujhe plumber chahiye DHA mein"

---

# Voice Input

Type:
Audio → Speech-to-Text → String

Purpose:
Represents spoken user requests converted into text.

Supported Modes:
- microphone input
- recorded voice

Examples:
- "Mujhe kal plumber chahiye"
- "Need AC technician tomorrow"

---

# Booking Request Input

Type:
Object

Purpose:
Represents booking requests after provider selection.

Structure:

{
  "user_id": "",
  "provider_id": "",
  "time_slot": "",
  "service_type": ""
}

Example:

{
  "user_id": "U102",
  "provider_id": "P201",
  "time_slot": "2026-05-18T10:00:00Z",
  "service_type": "AC Technician"
}

---

# Pricing Request Input

Type:
Object

Purpose:
Represents pricing calculation requests.

Structure:

{
  "service_type": "",
  "distance_km": 0,
  "urgency": "",
  "job_complexity": ""
}

Example:

{
  "service_type": "Plumber",
  "distance_km": 3.2,
  "urgency": "high",
  "job_complexity": "intermediate"
}

---

# Authentication Input

Type:
Object

Purpose:
Represents login and user authentication requests.

Structure:

{
  "email": "",
  "password": ""
}

---

# Provider Search Input

Type:
Object

Purpose:
Represents provider discovery requests.

Structure:

{
  "service_type": "",
  "location": "",
  "preferred_time": "",
  "budget_preference": ""
}

---

# Dispute Input

Type:
Object

Purpose:
Represents complaints and dispute requests.

Structure:

{
  "booking_id": "",
  "issue_type": "",
  "description": ""
}

---

# Important Rules

- All systems must follow these input structures consistently.
- Avoid duplicate input definitions across files.
- Input validation must be handled before processing.
- Voice input must always be converted into text before AI processing.