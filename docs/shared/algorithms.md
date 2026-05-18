# Algorithms Specification

## Intent Agent Algorithm

Type:
Hybrid NLP + LLM Extraction

Approach:
- Rule-based preprocessing
- Language detection
- Gemini LLM extraction
- Confidence scoring

Steps:
1. Detect language
2. Normalize slang/misspellings
3. Extract entities
4. Validate extracted fields
5. Generate confidence score

Confidence Formula:
confidence =
(valid_fields / total_fields)
× extraction_quality

Range:
0.0 → 1.0

Fallback:
If confidence < 0.65:
- ask clarification question

---

## Ranking Agent Algorithm

Type:
Weighted Multi-Factor Scoring

Formula:

final_score =
(
distance_score × 0.15 +
availability_score × 0.20 +
rating_score × 0.15 +
reliability_score × 0.15 +
specialization_score × 0.15 +
budget_score × 0.10 +
cancellation_penalty × 0.10
)

Score Range:
0 → 100

Highest score wins.

---

## Pricing Agent Algorithm

Formula:

total_price =
base_fee +
distance_fee +
urgency_multiplier +
complexity_fee -
discount

Urgency Multipliers:
same_day = 1.3x
next_day = 1.0x

---

## Booking Agent Algorithm

Logic:
- Validate slot
- Check overlap
- Reserve provider
- Generate booking ID
- Save to Firestore