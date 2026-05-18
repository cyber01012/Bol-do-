# Discovery System

## Purpose

Handle intent understanding and provider discovery.

The system extracts:
- service type
- location
- preferred time
- urgency
- budget sensitivity

Then discovers and ranks suitable providers.

---

# Responsibilities

- multilingual input handling
- intent extraction
- provider discovery
- provider ranking
- confidence scoring

---

# Inputs

- user query
- location
- requested time

# Supported Input Modes

- text input
- voice input

Voice input should:
- convert speech to text
- support Urdu, Roman Urdu, and English
- handle noisy speech where possible

---

# Outputs

- extracted intent
- ranked providers
- confidence score

---

# Workflow

User Input
→ Language Processing
→ Intent Extraction
→ Provider Discovery
→ Provider Ranking
→ Recommendation Generation

---

# AI Reasoning

The system should:
- understand noisy multilingual input
- detect service intent
- identify urgency
- estimate user constraints
- rank providers intelligently

---

# Ranking Factors

- distance
- availability
- provider rating
- reliability score
- cancellation rate
- specialization
- pricing
- workload capacity

---

# Edge Cases

- ambiguous requests
- misspelled service names
- mixed language input
- incomplete location data

---

# Failure Handling

- ask clarification questions
- show fallback providers
- handle no-provider scenarios

---

# Logging Requirements

Generate logs for:
- extracted intent
- confidence score
- selected providers
- ranking decisions