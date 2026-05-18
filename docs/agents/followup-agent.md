# Follow-up Agent

## Purpose

The Follow-up Agent handles post-service workflows.

---

# Responsibilities

- service completion updates
- customer feedback
- rating updates
- reputation updates

---

# Input

Completed booking information.

---

# Output

{
  "status": "completed",
  "feedback": ""
}

---

# Connected Agents

- Notification Agent
- Dispute Agent

---

# Tools Used

- Firebase
- Feedback workflows

---

# Logs Generated

{
  "agent": "Follow-up Agent",
  "decision": "Feedback collected"
}

---

# Failure Handling

- missing feedback
- incomplete booking