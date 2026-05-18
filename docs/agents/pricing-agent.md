# Pricing Agent

## Purpose

The Pricing Agent generates transparent dynamic pricing.

---

# Responsibilities

- calculate service pricing
- apply urgency multipliers
- apply distance charges
- generate breakdowns

---

# Pricing Formula

Base Fee
+ Distance Cost
+ Urgency Multiplier
+ Complexity Cost
- Discounts

---

# Input

{
  "service_type": "",
  "distance_km": 0,
  "urgency": ""
}

---

# Output

{
  "total_price": 0,
  "breakdown": {}
}

---

# Connected Agents

- Ranking Agent
- Booking Agent

---

# Tools Used

- Pricing rules
- Firebase

---

# Logs Generated

{
  "agent": "Pricing Agent",
  "decision": "Generated price"
}

---

# Failure Handling

- invalid distance
- missing urgency
- pricing conflicts