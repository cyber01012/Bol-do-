# docs/workflows/README.md

# Workflow Documentation

Purpose:
This folder contains lifecycle execution flows for the BolDo platform.

---

# Included Workflows

- user-request-flow.md
- booking-flow.md
- dispute-flow.md
- followup-flow.md
- notification-flow.md
- provider-matching-flow.md
- failure-recovery-flow.md

---

# Responsibilities

This folder defines:
- execution sequencing
- workflow orchestration
- recovery handling
- lifecycle automation
- async processing

---

# Workflow Categories

Synchronous:
- intent extraction
- ranking
- booking validation

Asynchronous:
- notifications
- reminders
- feedback collection

---

# Main Workflow

User Input
→ Intent
→ Discovery
→ Ranking
→ Pricing
→ Booking
→ Notifications
→ Follow-up
→ Dispute Handling

---

# Dependencies

Depends On:
- docs/agents/
- docs/shared/
- docs/architecture/