# Logging Format

Each workflow must generate structured logs.

---

# Standard Log Structure

{
  "agent": "",
  "workflow_stage": "",
  "decision": "",
  "reasoning": "",
  "action_taken": "",
  "severity": "",
  "timestamp": ""
}

---

# Severity Levels

- info
- warning
- critical

---

# Example

{
  "agent": "Ranking Agent",
  "workflow_stage": "Provider Ranking",
  "decision": "Selected Provider A",
  "reasoning": "Higher reliability score and lower cancellation rate",
  "action_taken": "Provider recommended to user",
  "severity": "info",
  "timestamp": "2026-05-17T12:30:00Z"
}

---

# Logging Requirements

All workflows must log:
- reasoning
- decisions
- actions
- failures
- fallback handling

---

# Important Rules

- Logs must be human readable
- Logs must support demo presentation
- Logs must support debugging
- Avoid incomplete log entries