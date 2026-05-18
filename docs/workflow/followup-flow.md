# followup-flow.md

# Follow-up Workflow

Purpose:
Defines post-booking engagement and automation lifecycle.

---

# Workflow Sequence

Booking Confirmed
→ Reminder Scheduling
→ Service Tracking
→ Completion Detection
→ Feedback Collection
→ Rating Update

---

# Step 1 — Reminder Scheduling

Responsible Agent:
Follow-up Agent

Tasks:
- schedule reminders
- generate reminder times
- prevent duplicate reminders

---

# Step 2 — Service Tracking

Tasks:
- track provider progress
- simulate en-route updates
- track completion status

---

# Step 3 — Completion Detection

Triggers:
- provider marks completed
- simulated service completion

---

# Step 4 — Feedback Collection

Tasks:
- collect ratings
- collect written feedback
- detect negative sentiment

---

# Step 5 — Rating Update

Tasks:
- update provider score
- update reliability score
- update future ranking influence

---

# Failure Handling

No Feedback:
→ retry feedback request

Negative Feedback:
→ trigger dispute suggestion

---

# Logging Requirements

Must Log:
- reminder timestamps
- feedback received
- rating updates
- follow-up completion