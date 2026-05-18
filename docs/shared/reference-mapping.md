# Reference Mapping

Project:
BolDo — AI Service Orchestrator

Purpose:
This document defines all major dependencies, relationships, orchestration flows, reading priorities, and execution references across the entire documentation system.

---

# Root-Level Dependencies

## README.md

Purpose:
Project overview and entry point.

Depends On:
- docs/README.md

Used By:
- all developers
- Antigravity
- onboarding workflow

---

# Documentation Layer Mapping

## docs/README.md

Purpose:
Central documentation index.

Depends On:
- docs/system/master-context.md

References:
- docs/shared/
- docs/architecture/
- docs/workflows/
- docs/agents/
- docs/prompts/

---

# Shared Documentation Mapping

## docs/shared/styleguide.md

Defines:
- coding standards
- naming conventions
- UI consistency
- Flutter architecture rules

Used By:
- all prompts
- all agents
- UI workflows
- code review workflows

---

## docs/shared/constraints.md

Defines:
- validation rules
- business logic constraints
- score ranges
- retry limits
- timeout limits

Used By:
- all agents
- all workflows
- testing prompts

---

## docs/shared/algorithms.md

Defines:
- provider scoring formulas
- pricing logic
- ranking calculations
- confidence scoring

Used By:
- Intent Agent
- Ranking Agent
- Pricing Agent

---

## docs/shared/input-types.md

Defines:
- user request schema
- booking request schema
- pricing request schema
- voice input schema

Used By:
- Intent Agent
- Booking Agent
- Voice Agent
- workflows

---

## docs/shared/output-types.md

Defines:
- intent output
- ranked providers output
- booking output
- voice response output

Used By:
- all agents
- API workflows
- UI rendering

---

## docs/shared/datatypes.md

Defines:
- shared object structures
- reusable entity types
- booking types
- provider types

Used By:
- Firestore schema
- all agents
- workflows

---

## docs/shared/error-codes.md

Defines:
- API error codes
- validation failures
- booking failures
- retry conditions

Used By:
- Booking Agent
- Discovery Agent
- Dispute Agent
- failure recovery workflow

---

## docs/shared/environment-vars.md

Defines:
- Firebase keys
- Gemini keys
- Maps API keys
- notification configuration

Used By:
- backend initialization
- deployment
- CI/CD

---

## docs/shared/versioning.md

Defines:
- Flutter version
- Firebase SDK versions
- dependency compatibility

Used By:
- setup workflow
- deployment workflow

---

## docs/shared/acceptance-criteria.md

Defines:
- QA requirements
- feature completion requirements
- validation targets
- workflow validation

Used By:
- testing prompts
- code review prompts
- SQA workflows
- all agents

---

## docs/shared/reference-mapping.md

Defines:
- centralized dependency map
- orchestration references
- document relationships

Used By:
- Antigravity
- onboarding
- integration workflow

---

# Architecture Mapping

## docs/architecture/system-architecture.md

Defines:
- overall platform design
- frontend/backend interaction
- Firebase integration
- orchestration layers

Depends On:
- docs/shared/

Used By:
- all workflows
- all prompts

---

## docs/architecture/agent-pipeline.md

Defines:
- complete multi-agent orchestration
- synchronous flow
- asynchronous flow
- fallback orchestration

Connected Agents:
- Intent Agent
- Discovery Agent
- Ranking Agent
- Pricing Agent
- Booking Agent
- Notification Agent
- Follow-up Agent
- Voice Agent
- Dispute Agent

Used By:
- workflows
- prompts
- integration testing

---

## docs/architecture/database-schema.md

Defines:
- Firestore collections
- provider schema
- booking schema
- dispute schema
- notification schema

Used By:
- Booking Agent
- Follow-up Agent
- Dispute Agent
- backend workflows

---

## docs/architecture/api-flow.md

Defines:
- request lifecycle
- API sequencing
- request/response handling
- backend orchestration

Used By:
- integration prompts
- testing workflows

---

# Workflow Mapping

## docs/workflows/user-request-flow.md

Connected Agents:
- Voice Agent
- Intent Agent
- Discovery Agent
- Ranking Agent
- Pricing Agent
- Booking Agent
- Notification Agent
- Follow-up Agent
- Dispute Agent

Depends On:
- input-types.md
- output-types.md
- constraints.md

---

## docs/workflows/provider-matching-flow.md

Connected Agents:
- Discovery Agent
- Ranking Agent

Depends On:
- algorithms.md
- constraints.md
- database-schema.md

---

## docs/workflows/booking-flow.md

Connected Agents:
- Booking Agent
- Notification Agent
- Follow-up Agent

Depends On:
- database-schema.md
- error-codes.md

---

## docs/workflows/notification-flow.md

Connected Agents:
- Notification Agent
- Follow-up Agent

Depends On:
- output-types.md
- constraints.md

---

## docs/workflows/followup-flow.md

Connected Agents:
- Follow-up Agent
- Notification Agent
- Dispute Agent

Depends On:
- booking-flow.md
- notification-flow.md

---

## docs/workflows/dispute-flow.md

Connected Agents:
- Dispute Agent
- Booking Agent
- Ranking Agent
- Follow-up Agent

Depends On:
- error-codes.md
- database-schema.md
- acceptance-criteria.md

---

## docs/workflows/failure-recovery-flow.md

Connected Agents:
- all agents

Depends On:
- constraints.md
- error-codes.md
- workflows

---

## docs/workflows/voice-processing-flow.md

Connected Agents:
- Voice Agent
- Intent Agent

Depends On:
- input-types.md
- output-types.md
- constraints.md