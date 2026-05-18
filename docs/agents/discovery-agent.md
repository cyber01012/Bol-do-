# Discovery Agent

## Purpose

The Discovery Agent finds relevant providers based on extracted intent data.

---

# Responsibilities

- Search provider dataset
- Filter by service category
- Filter by location
- Check provider availability

---

# Input

{
  "service_type": "",
  "location": ""
}

---

# Output

[
  {
    "provider_id": "",
    "name": "",
    "distance_km": 0
  }
]

---

# Core Tasks

- Provider filtering
- Location matching
- Category matching
- Availability filtering

---

# Connected Agents

- Intent Agent
- Ranking Agent

---

# Tools Used

- Firebase Firestore
- Mock datasets

---

# Logs Generated

{
  "agent": "Discovery Agent",
  "decision": "Found matching providers"
}

---

# Failure Handling

- no providers found
- missing provider data
- invalid location