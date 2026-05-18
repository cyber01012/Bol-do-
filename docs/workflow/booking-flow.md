# booking-flow.md

# Booking Workflow

Purpose:
Defines the booking lifecycle from provider selection to booking confirmation.

---

# Workflow Sequence

Provider Selected
→ Slot Validation
→ Availability Check
→ Conflict Detection
→ Booking Creation
→ Firestore Update
→ Confirmation Generation
→ Notification Trigger

---

# Step 1 — Provider Selection

Input:
- ranked providers
- selected provider

Responsible Agent:
Ranking Agent

---

# Step 2 — Slot Validation

Responsible Agent:
Booking Agent

Tasks:
- validate requested time
- validate provider availability
- check travel buffer

---

# Step 3 — Conflict Detection

Tasks:
- detect overlapping bookings
- prevent duplicate reservations
- lock selected slot

Failure:
If conflict detected:
- suggest alternate slot

---

# Step 4 — Booking Creation

Tasks:
- generate booking ID
- create booking object
- assign provider

Example Output:

{
  "booking_id": "BK1021",
  "provider_id": "PR209",
  "status": "confirmed"
}

---

# Step 5 — Database Update

Database:
Firebase Firestore

Collections Updated:
- bookings
- provider_schedule
- user_bookings

---

# Step 6 — Confirmation Generation

Tasks:
- generate booking receipt
- generate booking summary
- generate estimated arrival

---

# Step 7 — Notification Trigger

Responsible Agent:
Notification Agent

Tasks:
- send booking confirmation
- schedule reminders

---

# Failure Handling

Provider Busy:
→ alternate provider suggestion

Double Booking:
→ retry alternate slot

Database Failure:
→ retry transaction

---

# Logging Requirements

Must Log:
- booking ID
- provider assignment
- slot reservation
- conflict handling
- retry attempts