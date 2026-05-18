# acceptance-criteria.md

# Acceptance Criteria

Project:
BolDo — AI Service Orchestrator

Purpose:
Defines validation and completion requirements for all agents, workflows, UI, and backend systems.

---

# Intent Agent

## Acceptance Criteria

- Extract service type correctly
- Extract location correctly
- Extract preferred time correctly
- Extract urgency correctly
- Generate confidence score
- Support Urdu/Roman Urdu/English
- Handle misspelled inputs
- Ask clarification for low confidence
- Generate structured logs

---

# Discovery Agent

## Acceptance Criteria

- Search providers by service type
- Filter providers by location
- Validate provider availability
- Return minimum 3 providers if available
- Handle no-provider scenarios
- Generate structured logs

---

# Ranking Agent

## Acceptance Criteria

- Rank providers using 6+ factors
- Generate ranking score from 0–100
- Explain ranking reasoning
- Prioritize reliability when needed
- Handle provider tie cases
- Generate ranking logs

---

# Pricing Agent

## Acceptance Criteria

- Generate transparent pricing breakdown
- Apply urgency multiplier correctly
- Apply travel surcharge correctly
- Apply discounts correctly
- Prevent negative pricing
- Return structured pricing object

---

# Booking Agent

## Acceptance Criteria

- Prevent double booking
- Validate provider availability
- Generate booking ID
- Save booking in Firestore
- Generate booking confirmation
- Trigger notifications
- Generate logs

---

# Notification Agent

## Acceptance Criteria

- Generate booking confirmation messages
- Generate reminders
- Retry failed notifications
- Support WhatsApp/SMS simulation
- Generate notification logs

---

# Follow-up Agent

## Acceptance Criteria

- Schedule reminders
- Track completion status
- Collect feedback
- Update provider ratings
- Generate follow-up logs

---

# Voice Agent

## Acceptance Criteria

- Capture voice input successfully
- Convert speech to text accurately
- Support Urdu/Roman Urdu/English voice
- Detect mixed-language speech
- Generate voice responses
- Handle noisy audio input
- Retry failed voice processing
- Generate voice processing logs

---

# Dispute Agent

## Acceptance Criteria

- Handle provider cancellation
- Handle no-show cases
- Handle quality complaints
- Handle price disputes
- Trigger reassignment workflow
- Simulate escalation process
- Generate dispute logs

---

# Workflow Acceptance Criteria

## User Request Workflow

- Complete full booking lifecycle
- Handle multilingual requests
- Maintain workflow sequencing
- Generate end-to-end logs

---

## Booking Workflow

- Prevent overlapping bookings
- Trigger notifications successfully
- Update Firestore correctly

---

## Dispute Workflow

- Validate disputes correctly
- Trigger resolution workflow
- Generate escalation simulation

---

## Voice Processing Workflow

- Convert speech accurately
- Generate voice response successfully
- Detect language correctly
- Handle retry logic

---

# UI Acceptance Criteria

- Responsive mobile UI
- Smooth navigation
- Dark/light theme support
- Agent trace visibility
- Booking lifecycle visibility

---

# Backend Acceptance Criteria

- Firebase integration working
- Firestore CRUD operations working
- Structured logging enabled
- Error handling enabled
- Environment variables secured

---

# Performance Acceptance Criteria

- Intent extraction < 5 sec
- Ranking < 2 sec
- Booking confirmation < 5 sec
- Voice processing < 5 sec
- Notification generation < 10 sec

---

# Security Acceptance Criteria

- No hardcoded API keys
- Environment variables secured
- Input validation enabled
- Firestore access controlled