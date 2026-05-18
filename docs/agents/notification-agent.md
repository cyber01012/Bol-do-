# Notification Agent

## Purpose

The Notification Agent generates reminders and booking updates.

---

# Responsibilities

- booking confirmations
- reminder generation
- follow-up notifications
- voice notifications

---

# Input

Booking information.

---

# Output

{
  "message": "",
  "type": "notification"
}

---

# Connected Agents

- Booking Agent
- Follow-up Agent
- Voice Agent

---

# Tools Used

- Firebase
- flutter_tts

---

# Logs Generated

{
  "agent": "Notification Agent",
  "decision": "Reminder scheduled"
}

---

# Failure Handling

- notification failure
- invalid user session