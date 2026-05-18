# Application Flow

## Main Workflow

1. User submits service request using text or voice input.
2. Speech-to-text processing converts voice input into text if required.
3. Intent Extraction Agent processes the request.
4. Provider Discovery Agent finds matching providers.
5. Ranking Agent scores providers using multiple ranking factors.
6. Pricing Agent generates dynamic pricing breakdown.
7. Booking Agent simulates provider booking.
8. Notification System generates confirmations and reminders.
9. Follow-up Workflow tracks service completion.
10. Dispute System handles complaints, cancellations, and fallback scenarios if required.
11. System may generate AI voice responses for confirmations, reminders, and updates.

---

# Simplified Flow Diagram

User Input
→ Text or Voice Processing
→ Intent Extraction
→ Provider Discovery
→ Provider Ranking
→ Dynamic Pricing
→ Booking Simulation
→ Notifications
→ Follow-up Workflow
→ Dispute Handling
→ Voice Response Output

---

# Supported Interaction Modes

- text input
- voice input
- AI voice output

---

# Important Notes

- All workflows must generate logs.
- All workflows must support fallback handling.
- Voice input must be converted into text before AI processing.
- AI voice responses are optional enhancements and not core dependencies.