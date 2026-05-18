# Workflow Sequencing

## Main Workflow

User Input
→ Intent Agent
→ Discovery Agent
→ Ranking Agent
→ Pricing Agent
→ Booking Agent
→ Notification Agent
→ Follow-up Agent

---

# Synchronous Workflows

These execute immediately:
- Intent extraction
- Ranking
- Pricing
- Booking validation

---

# Asynchronous Workflows

These run in background:
- Notifications
- Reminders
- Follow-up updates
- Feedback collection

---

# Timeout Rules

Intent Agent:
5 seconds

Discovery Agent:
3 seconds

Ranking Agent:
2 seconds

Booking Agent:
5 seconds

---

# Retry Logic

Retry Count:
3 attempts

Backoff:
Exponential retry