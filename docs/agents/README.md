# docs/agents/README.md

# Agents Documentation

Purpose:
This folder contains all AI agent specifications used in the BolDo platform.

Each agent contains:
- responsibilities
- workflows
- inputs
- outputs
- failure handling
- connected agents
- logging requirements

---

# Available Agents

- Intent Agent
- Discovery Agent
- Ranking Agent
- Pricing Agent
- Booking Agent
- Notification Agent
- Follow-up Agent
- Voice Agent
- Dispute Agent

---

# Agent Architecture

All agents follow:
Input
→ Processing
→ Reasoning
→ Decision
→ Action
→ Logging

---

# Common Standards

All agents must:
- generate logs
- validate inputs
- validate outputs
- follow constraints
- support multilingual workflows
- handle failures gracefully

---

# Dependencies

Shared Dependencies:
- docs/shared/
- docs/workflows/
- docs/architecture/

---

# Main Workflow

Voice/Text Input
→ Intent Agent
→ Discovery Agent
→ Ranking Agent
→ Pricing Agent
→ Booking Agent
→ Notification Agent
→ Follow-up Agent
→ Dispute Agent