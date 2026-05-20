# BolDo Pricing Agent: I/O Contract & Validation

This document defines the strict Input/Output JSON contract, validation thresholds, and edge case handling strategies for the BolDo Pricing Agent.

## User Review Required

> [!IMPORTANT]
> Please review this data contract, validation logic, and fallback strategy. This dictates exactly how the Pricing Agent communicates with the Orchestrator and what safeguards are in place.

## 1. Input Contract

The Pricing Agent expects the following structured payload from the Orchestrator (populated by Intent and Ranking agents):

```json
{
  "request_id": "req_abc123",
  "session_id": "sess_xyz789",
  "user_request": {
    "service_type": "plumber",
    "urgency": "same_day",
    "requested_time": "2026-05-19T23:00:00Z",
    "is_repeat_customer": false
  },
  "selected_provider": {
    "provider_id": "prov_456",
    "distance_km": 12.5,
    "complexity": "intermediate"
  },
  "ranking_metadata": {
    "rank_score": 0.88,
    "ranking_reason": "closest distance"
  }
}
```

## 2. Output Contract

The Pricing Agent must return this payload to the Orchestrator, which is then routed to the Booking Agent:

```json
{
  "request_id": "req_abc123",
  "agent_trace_id": "trace_price_999",
  "orchestration_status": "success",
  "ready_for_booking": true,
  "selected_provider": "prov_456",
  "pricing_data": {
    "total_price_pkr": 1450,
    "confidence_score": 0.95,
    "breakdown": {
      "base_price": 1000,
      "distance_cost": 312.5,
      "urgency_multiplier": 1.3,
      "time_multiplier": 1.2,
      "loyalty_discount_value": 0
    }
  }
}
```

## 3. Validation Rules & Graceful Fallbacks

> [!WARNING]
> If a validation fails but a calculation is still possible via fallbacks, the agent returns a safe baseline price, sets `orchestration_status = "degraded"`, and keeps `ready_for_booking = true`.

*   **Missing Distance:** If `distance_km` is null or missing, default to `0 km` for the distance cost calculation.
*   **Invalid Service Type:** If the service type cannot be mapped to a complexity tier, default to the `basic` complexity tier (500 PKR).
*   **Missing Time:** If `requested_time` is missing, default to the `normal` time multiplier (1.0x).
*   **Price Range Cap:** The final `total_price_pkr` must be strictly clamped between **500 PKR (min)** and **15,000 PKR (max)**.
*   **Distance Fee Cap:** The `distance_cost` must not exceed **50% of the total price**. If it does, it is capped precisely at the 50% mark of the base + complexity calculation.

## 4. Edge Case Handling Strategy

1.  **No Provider Distance:**
    *   **Strategy:** Apply the 'Missing Distance' fallback. Calculate base + complexity + multipliers as normal, treating distance cost as `0 PKR`.
2.  **Corrupted Ranking Data:**
    *   **Strategy:** Ignore `ranking_metadata`. As long as `selected_provider.provider_id` exists, proceed with the standard pricing calculation without penalty.
3.  **High Urgency + Night Pricing Conflict:**
    *   **Strategy:** Both multipliers (e.g., `1.3x` for urgency and `1.2x` for night time) are stacked and applied sequentially. The massive resulting price is kept in check by the **15,000 PKR upper limit** validation rule.
4.  **First-Time User (No Loyalty Discount):**
    *   **Strategy:** Set the loyalty discount percentage to `0`. The discount calculation phase subtracts `0 PKR`, ensuring math operations do not fail on null values.
