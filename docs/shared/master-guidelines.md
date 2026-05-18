# Master Guidelines

## Project Name

BolDo — AI Service Orchestrator for Home Services

---

# Project Objective

Build an agentic AI-powered mobile application that automates the complete lifecycle of home service booking using autonomous workflows and intelligent decision-making.

The system should:
- understand multilingual user requests
- discover relevant providers
- rank providers intelligently
- generate dynamic pricing
- simulate booking workflows
- automate follow-ups
- handle disputes and failures
- generate reasoning logs

---

# Project Scope

Focused Domain:
Home Services

Supported Services:
- plumbers
- electricians
- AC technicians
- carpenters
- painters
- appliance repair
- home cleaning

---

# Core Principles

This is NOT:
- a static listing app
- a simple CRUD application
- a fixed-rule booking app

This IS:
- an AI workflow orchestration system
- an agentic reasoning platform
- an autonomous decision-making system

---

# Mandatory Features

The system must support:

- multilingual input
- Roman Urdu support
- voice input
- AI voice output
- provider discovery
- multi-factor provider ranking
- dynamic pricing
- booking simulation
- follow-up workflows
- dispute handling
- structured logs
- fallback handling

---

# Required AI Workflow

User Input
→ Intent Extraction Agent
→ Provider Discovery Agent
→ Ranking Agent
→ Pricing Agent
→ Booking Agent
→ Notification Agent
→ Follow-up Agent
→ Dispute Agent

---

# Agentic System Requirements

The system must demonstrate:

- reasoning
- planning
- autonomous decisions
- action execution
- fallback handling
- workflow continuation
- structured logging

The AI must:
- observe
- reason
- decide
- act
- evaluate
- adapt

---

# Multilingual Support

Supported Languages:
- Urdu
- Roman Urdu
- English
- mixed-language input

The system should:
- handle spelling mistakes
- support slang
- support code-switching
- ask clarifying questions when confidence is low

Example:
"Mujhe plmbr chye kal subh DHA"

---

# Provider Ranking Rules

Provider ranking must use multiple factors.

Required Factors:
- distance
- travel time
- availability
- rating
- review recency
- reliability score
- cancellation rate
- specialization
- budget compatibility
- capacity

The system must NOT:
- rank providers using distance only

---

# Dynamic Pricing Rules

Pricing must include:
- base fee
- distance fee
- urgency multiplier
- job complexity
- surge conditions
- discounts

Pricing must always show:
- complete breakdown
- transparency
- fairness explanation

---

# Booking Simulation Rules

The system must simulate:
- provider assignment
- slot reservation
- booking confirmation
- reminder scheduling
- receipt generation
- database updates

Simulation may use:
- Firebase
- mock databases
- JSON datasets

---

# Follow-up Workflow Rules

The system should simulate:
- reminders
- status updates
- completion confirmations
- customer feedback
- reputation updates

---

# Dispute Handling Rules

The system must support:
- provider cancellation
- no-show handling
- quality complaints
- price disputes
- refund simulation
- provider reassignment

Fallback workflows are mandatory.

---

# Required Failure Scenarios

At least one edge case must be demonstrated.

Recommended Scenarios:
- provider cancels after booking
- no provider available
- low-confidence intent extraction
- overlapping bookings
- ambiguous user input

The system must recover gracefully.

---

# Voice Interaction Rules

The system should support:
- speech-to-text input
- AI-generated voice responses

Voice features should:
- support Urdu and English
- remain conversational
- improve accessibility

---

# Logging Rules

All workflows must generate logs.

Logs must include:
- reasoning
- decisions
- actions
- failures
- fallback handling
- timestamps

Logs must:
- be human-readable
- support debugging
- support demo presentation

---

# Baseline Comparison Rules

The project must include a comparison between:

1. Simple Non-Agentic System
2. AI Agentic System

The comparison should demonstrate:
- improved ranking quality
- autonomous decisions
- better fallback handling
- dynamic workflows
- reasoning visibility

---

# Mobile App Requirements

Mandatory:
- Flutter mobile app
- Android APK

Optional:
- web dashboard
- admin portal

---

# Technical Stack

Frontend:
- Flutter

Backend:
- Firebase
- Cloud Functions (optional)

Database:
- Firebase Firestore

Authentication:
- Firebase Authentication

AI:
- Gemini API or external LLM APIs

Voice:
- speech_to_text
- flutter_tts

Maps:
- Google Maps API (optional)

---

# Mock Data Rules

Use:
- synthetic providers
- synthetic bookings
- synthetic ratings

Do NOT:
- use real personal data
- expose sensitive information

---

# UI/UX Rules

Focus on:
- workflow clarity
- conversational interaction
- clean provider ranking display
- visible AI reasoning
- readable logs

Do NOT:
- over-focus on animations
- waste time on unnecessary complexity

---

# Demo Requirements

Demo must clearly show:
- multilingual input
- AI reasoning
- provider ranking
- dynamic pricing
- booking simulation
- logs
- follow-up workflows
- fallback handling

Recommended Demo Length:
3–5 minutes

---

# Architecture Rules

The project must maintain:
- modular structure
- reusable components
- reusable data types
- centralized schemas
- clean documentation

Avoid:
- duplicate logic
- duplicate schemas
- inconsistent structures

---

# Team Collaboration Rules

- Use GitHub for collaboration.
- Use separate feature branches.
- Merge reviewed features into main branch.
- Keep `.md` files updated.
- Maintain consistent naming conventions.

---

# Important Success Criteria

The judges should clearly see:

- autonomy
- reasoning
- orchestration
- workflow intelligence
- fallback handling
- structured decision-making

The final project should feel like:
"An intelligent AI assistant for home services."

NOT:
"A simple booking app."