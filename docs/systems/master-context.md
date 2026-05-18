# Master Context File

Project:
BolDo — AI Service Orchestrator

Purpose:
This file acts as the CENTRAL CONTEXT ROUTER for all Antigravity tasks.

Instead of loading the entire repository every time, this file dynamically tells Antigravity:

- which folders to read
- which files are relevant
- which role to load
- which workflows matter
- which validations are required

based on the CURRENT TASK TYPE.

This prevents:
- token waste
- unnecessary context loading
- hallucinated architecture
- unrelated workflow generation

---

# Mandatory Execution Rule

Before executing ANY task:

1. Identify task type
2. Load ONLY relevant context sections
3. Load ONLY required files
4. Ignore unrelated folders

DO NOT load the entire repository unless explicitly requested.

---

# Global Minimal Context (ALWAYS LOAD)

Read FIRST:

- README.md
- docs/shared/reference-mapping.md

Purpose:
- understand repo structure
- understand dependency graph
- understand orchestration relationships

---

# Task-Based Context Routing

# 1. FRONTEND DEVELOPMENT CONTEXT

Use When:
- building screens
- Flutter UI
- widgets
- state management
- navigation
- responsive layouts

Load Role:
- roles/frontend-engineer.md

Read ONLY:

## Shared
- docs/shared/styleguide.md
- docs/shared/output-types.md
- docs/shared/datatypes.md
- docs/shared/constraints.md

## Architecture
- docs/architecture/system-architecture.md

## Workflows
- relevant workflow file only

## Agents
- relevant agent files only

## Prompts
- docs/prompts/ui-prompt.md

DO NOT READ:
- environment-vars.md
- deployment files
- unrelated agents
- backend-only workflows

After Execution Validate:
- responsive UI
- accessibility
- clean architecture
- workflow visibility

---

# 2. BACKEND DEVELOPMENT CONTEXT

Use When:
- implementing logic
- Firebase integration
- APIs
- orchestration
- Firestore
- workflows

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- constraints.md
- algorithms.md
- datatypes.md
- input-types.md
- output-types.md
- error-codes.md

## Architecture
- system-architecture.md
- database-schema.md
- api-flow.md
- agent-pipeline.md

## Workflows
- relevant workflow file

## Agents
- relevant agent file

## Prompts
- feature-dev.md

DO NOT READ:
- UI prompts
- frontend screens
- unrelated agents

After Execution Validate:
- Firestore compatibility
- retry handling
- logging generation
- scalable architecture

---

# 3. INTENT AGENT CONTEXT

Use When:
- building intent extraction
- multilingual NLP
- parsing user queries

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- input-types.md
- output-types.md
- algorithms.md
- constraints.md
- datatypes.md

## Architecture
- agent-pipeline.md

## Workflows
- user-request-flow.md

## Agents
- intent-agent.md

Optional:
- voice-agent.md

DO NOT READ:
- booking workflows
- dispute workflows
- frontend screens

After Execution Validate:
- multilingual support
- confidence scoring
- clarification logic
- structured outputs

---

# 4. DISCOVERY AGENT CONTEXT

Use When:
- provider searching
- provider filtering
- maps integration

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- datatypes.md
- constraints.md
- error-codes.md

## Architecture
- database-schema.md
- agent-pipeline.md

## Workflows
- provider-matching-flow.md

## Agents
- discovery-agent.md

After Execution Validate:
- provider filtering
- location matching
- availability checks

---

# 5. RANKING AGENT CONTEXT

Use When:
- provider scoring
- recommendation logic
- ranking systems

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- algorithms.md
- constraints.md
- datatypes.md

## Architecture
- agent-pipeline.md

## Workflows
- provider-matching-flow.md

## Agents
- ranking-agent.md

After Execution Validate:
- score normalization
- ranking consistency
- reasoning generation
- fairness validation

---

# 6. PRICING AGENT CONTEXT

Use When:
- dynamic pricing
- price calculations
- quote generation

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- algorithms.md
- constraints.md
- output-types.md

## Workflows
- booking-flow.md

## Agents
- pricing-agent.md

After Execution Validate:
- price breakdown
- urgency multiplier
- discount validation

---

# 7. BOOKING AGENT CONTEXT

Use When:
- booking simulation
- Firestore updates
- scheduling

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- datatypes.md
- error-codes.md
- constraints.md

## Architecture
- database-schema.md

## Workflows
- booking-flow.md

## Agents
- booking-agent.md

After Execution Validate:
- double-booking prevention
- booking persistence
- workflow triggering

---

# 8. NOTIFICATION AGENT CONTEXT

Use When:
- reminders
- confirmations
- messaging workflows

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- output-types.md
- constraints.md

## Workflows
- notification-flow.md

## Agents
- notification-agent.md

After Execution Validate:
- retry logic
- message generation
- scheduling validation

---

# 9. FOLLOW-UP AGENT CONTEXT

Use When:
- feedback workflows
- completion tracking
- reminders

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- datatypes.md
- constraints.md

## Workflows
- followup-flow.md

## Agents
- follow-up-agent.md

After Execution Validate:
- reminder scheduling
- feedback collection
- completion workflow

---

# 10. VOICE AGENT CONTEXT

Use When:
- speech-to-text
- text-to-speech
- multilingual voice processing

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Shared
- input-types.md
- output-types.md
- constraints.md

## Workflows
- voice-processing-flow.md

## Agents
- voice-agent.md

After Execution Validate:
- transcription quality
- multilingual detection
- TTS generation
- retry handling

---

# 11. DISPUTE AGENT CONTEXT

Use When:
- cancellations
- complaints
- escalation workflows

Load Role:
- roles/backend-engineer.md
- roles/qa-engineer.md

Read ONLY:

## Shared
- error-codes.md
- constraints.md
- acceptance-criteria.md

## Architecture
- database-schema.md

## Workflows
- dispute-flow.md
- failure-recovery-flow.md

## Agents
- dispute-agent.md

After Execution Validate:
- escalation handling
- reassignment logic
- refund simulation
- logging generation

---

# 12. TESTING CONTEXT

Use When:
- QA testing
- workflow validation
- edge-case testing

Load Role:
- roles/qa-engineer.md

Read ONLY:

## Shared
- acceptance-criteria.md
- constraints.md
- error-codes.md

## Workflows
- relevant workflow

## Agents
- relevant agent

## Logs
- logs/

## Prompts
- testing.md

After Execution Validate:
- edge cases
- multilingual robustness
- failure recovery
- workflow completion

---

# 13. BUG FIX CONTEXT

Use When:
- fixing crashes
- debugging workflows
- fixing integration issues

Load Role:
- roles/backend-engineer.md

Read ONLY:

## Logs
- logs/errors.md
- logs/workflow-logs.md

## Shared
- constraints.md
- error-codes.md

## Workflows
- relevant workflow

## Agents
- affected agents only

## Prompts
- bug-fix.md

After Execution Validate:
- no regressions
- retry handling
- workflow stability

---

# 14. CODE REVIEW CONTEXT

Use When:
- reviewing generated code
- architecture validation
- scalability review

Load Role:
- roles/code-reviewer.md

Read ONLY:

## Shared
- styleguide.md
- acceptance-criteria.md
- constraints.md

## Architecture
- relevant architecture files

## Workflows
- relevant workflows

## Prompts
- code-review.md

After Execution Validate:
- naming consistency
- modularity
- architecture compliance
- logging standards

---

# 15. DEPLOYMENT CONTEXT

Use When:
- Firebase deployment
- environment setup
- release configuration

Load Role:
- roles/devops-engineer.md

Read ONLY:

## Shared
- environment-vars.md
- versioning.md

## Architecture
- system-architecture.md

## Workflows
- deployment-related workflows

After Execution Validate:
- secure configs
- API connectivity
- dependency compatibility

---

# Global Engineering Rules

ALL generated code must:

- follow clean architecture
- follow Flutter best practices
- use modular structure
- include validation
- include retry handling
- support scalability
- support multilingual workflows
- include structured logging

---

# Global Logging Rules

Every workflow must generate:

- input logs
- output logs
- reasoning logs
- timestamps
- retry logs
- failure logs

Log Files:
- logs/agent-logs.md
- logs/workflow-logs.md
- logs/errors.md

---

# Global Security Rules

NEVER:
- hardcode secrets
- bypass validation
- ignore workflows
- expose Firebase keys

ALWAYS:
- validate inputs
- validate outputs
- use environment variables
- follow Firestore security rules

---

# Final Validation Sequence

Before marking ANY task complete:

1. Validate acceptance criteria
2. Validate workflow integration
3. Validate architecture consistency
4. Validate logging generation
5. Validate retry handling
6. Validate multilingual support
7. Validate scalability
8. Validate Firestore compatibility