# Project Architecture

## Project Name
BolDo – AI Service Orchestrator for Home Services

## Objective
Build an AI-powered mobile application that automates the end-to-end lifecycle of home service booking using agentic workflows.

The system understands multilingual user requests (Urdu, Roman Urdu, English), discovers providers, ranks them intelligently, simulates bookings, handles follow-ups, and manages disputes.

---

# Core Features

- Natural language understanding
- Provider discovery
- Intelligent provider ranking
- Dynamic pricing
- Booking simulation
- Follow-up automation
- Dispute handling
- Agent trace logging

---

# Architecture Layers

## 1. Presentation Layer
Flutter mobile application UI.

## 2. Application Layer
FastAPI backend handling APIs and workflow orchestration.

## 3. Intelligence Layer
AI-powered reasoning:
- Intent extraction
- Ranking
- Pricing
- Fallback handling

## 4. Data Layer
Firebase Firestore database.

---

# Agentic Workflow

User Input
→ Intent Extraction
→ Provider Discovery
→ Provider Ranking
→ Pricing
→ Booking Simulation
→ Notifications
→ Follow-up
→ Dispute Handling

---

# Tech Stack

Frontend:
- Flutter

Backend:
- FastAPI

Database:
- Firebase Firestore

AI:
- Gemini API

Hosting:
- Google Cloud Run

---

# Important Constraints

- No real payments
- No real SMS integration
- No provider-side application
- No admin dashboard

---

# Primary Goal

Demonstrate autonomous AI reasoning and workflow execution rather than UI complexity.