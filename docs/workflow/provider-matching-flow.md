# provider-matching-flow.md

# Provider Matching Workflow

Purpose:
Defines the intelligent provider matching lifecycle.

---

# Workflow Sequence

Intent Data
→ Provider Search
→ Filtering
→ Ranking
→ Recommendation

---

# Step 1 — Intent Input

Input:
- service type
- location
- urgency
- budget

Responsible Agent:
Intent Agent

---

# Step 2 — Provider Search

Responsible Agent:
Discovery Agent

Tasks:
- search provider database
- filter by category
- filter by location

---

# Step 3 — Filtering

Filtering Conditions:
- active provider
- available provider
- matching specialization

---

# Step 4 — Ranking

Responsible Agent:
Ranking Agent

Ranking Factors:
- distance
- availability
- rating
- reliability
- cancellation rate
- review recency
- specialization

---

# Step 5 — Recommendation

Output:
Top provider recommendations

Includes:
- ranking score
- reasoning
- pricing estimate

---

# Failure Handling

No Match:
→ relaxed filtering

Low Confidence:
→ clarification request

---

# Logging Requirements

Must Log:
- filters applied
- ranking scores
- rejection reasons
- final recommendation