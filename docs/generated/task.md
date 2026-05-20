# Pricing Agent Logic & Contract Implementation Tasks

## 1. Input/Output Models
- [x] Create `PricingRequest` data class reflecting the exact Input JSON contract (`user_request`, `selected_provider`, `ranking_metadata`, etc.).
- [x] Create `PricingResponse` data class reflecting the Output JSON contract (`pricing_data`, `agent_trace_id`, `orchestration_status`, `ready_for_booking`).
- [x] Implement `fromJson` / `toJson` serialization for all data classes to handle Orchestrator communication.

## 2. Validation & Fallback Handlers
- [x] Implement Validation Layer: Verify `service_type`, `distance_km`, and `requested_time` existence.
- [x] Implement Graceful Fallback Logic: Default to 0 km distance, 'basic' complexity, and 'normal' time if fields are missing. Set `orchestration_status = "degraded"`.
- [x] Implement Price Cap Rule: Clamp final price between 500 PKR and 15,000 PKR.
- [x] Implement Distance Fee Cap: Ensure distance fee never exceeds 50% of the Base + Complexity subtotal.

## 3. Core Pricing Algorithm
- [x] Create `PricingParameters` mapped from the `PricingRequest`.
- [x] Implement `calculateBasePrice(ServiceComplexity complexity)` method (Basic=500, Intermediate=1000, Complex=2000).
- [x] Implement `calculateDistanceCost(double distanceKm)` method (Rate=25).
- [x] Implement multipliers: Urgency, Time, and Loyalty.
- [x] Implement `roundToNearest50(double amount)` utility method.
- [x] Assemble the full calculation engine generating the `breakdown` object.

## 4. Edge Case Hardening & Testing
- [x] Edge Case 1: Write test handling missing/null `distance_km`.
- [x] Edge Case 2: Write test ensuring corrupted ranking data does not crash execution.
- [x] Edge Case 3: Write test verifying extreme multipliers hit the 15,000 PKR cap.
- [x] Edge Case 4: Write test verifying first-time user discounts execute smoothly with 0% reduction.
