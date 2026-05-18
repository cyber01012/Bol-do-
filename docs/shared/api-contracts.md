# API Contracts

## POST /extract-intent

Request:
{
  "query": ""
}

Response:
{
  "service_type": "",
  "location": "",
  "time": "",
  "urgency": "",
  "confidence": 0
}

---

## GET /providers

Response:
[
  {
    "provider_id": "",
    "name": "",
    "rating": 0,
    "distance_km": 0
  }
]

---

## POST /book-service

Request:
{
  "provider_id": "",
  "time_slot": ""
}

Response:
{
  "booking_id": "",
  "status": "confirmed"
}