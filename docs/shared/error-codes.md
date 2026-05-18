# Error Codes

## 400 — Bad Request

Description:
Invalid or missing user input.

Example:
{
  "error": "Missing location"
}

---

## 401 — Unauthorized

Description:
User authentication failed.

---

## 404 — Provider Not Found

Description:
No provider matched request.

---

## 409 — Booking Conflict

Description:
Provider already booked.

---

## 422 — Low Confidence Input

Description:
Intent confidence too low.

---

## 500 — Internal Server Error

Description:
Unexpected backend failure.

---

## Agent Failure Handling

Intent Agent:
→ ask clarification

Discovery Agent:
→ suggest alternate providers

Booking Agent:
→ reroute to Ranking Agent

Dispute Agent:
→ escalate workflow