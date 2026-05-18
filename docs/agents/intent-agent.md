# Intent Extraction Agent

## Purpose

The Intent Extraction Agent is responsible for understanding multilingual user requests and extracting structured booking information.

---

# Responsibilities

- Understand Urdu
- Understand Roman Urdu
- Understand English
- Handle mixed-language input
- Handle spelling mistakes and slang
- Extract service request details

---

# Input

User text or voice input.

Examples:
- "Kal subah plumber chahiye DHA mein"
- "Need AC technician tomorrow morning"
- "Mujhe electrician urgently chahiye"

---

# Output

{
  "service_type": "",
  "location": "",
  "time": "",
  "urgency": "",
  "confidence": 0
}

---

# Core Tasks

- Intent classification
- Location extraction
- Time extraction
- Urgency detection
- Confidence scoring

---

# Confidence Handling

If confidence is low:
- ask clarification questions
- avoid making assumptions

Example:
"Did you mean plumber or painter?"

---

# Connected Agents

- Discovery Agent
- Voice Agent

---

# Tools Used

- Gemini API
- Speech-to-text
- Firebase

---

# Logs Generated

{
  "agent": "Intent Agent",
  "decision": "Extracted service request",
  "confidence": 0.92
}

---

# Failure Handling

- unclear input
- unsupported language
- missing location
- ambiguous service type