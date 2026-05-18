# Ranking Agent

## Purpose

The Ranking Agent intelligently ranks providers using multi-factor scoring.

---

# Responsibilities

- Score providers
- Compare reliability
- Generate reasoning
- Recommend best provider

---

# Ranking Factors

- distance
- availability
- rating
- reliability
- cancellation rate
- specialization
- budget compatibility

---

# Input

Provider dataset from Discovery Agent.

---

# Output

[
  {
    "provider_id": "",
    "score": 0,
    "reasoning": ""
  }
]

---

# Core Tasks

- weighted scoring
- provider comparison
- ranking generation
- reasoning explanation

---

# Connected Agents

- Discovery Agent
- Pricing Agent

---

# Tools Used

- Firebase
- Scoring algorithms
- Gemini API

---

# Logs Generated

{
  "agent": "Ranking Agent",
  "decision": "Selected Provider A",
  "reasoning": "Higher reliability score"
}

---

# Failure Handling

- equal provider scores
- missing ratings
- incomplete provider profiles