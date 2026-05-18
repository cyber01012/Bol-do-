# Firebase Schema

## users

Fields:
- user_id
- name
- email

---

## providers

Fields:
- provider_id
- name
- service_type
- rating
- reliability_score
- cancellation_rate
- price_range

---

## bookings

Fields:
- booking_id
- user_id
- provider_id
- booking_status
- scheduled_time
- price

---

## logs

Fields:
- log_id
- agent_name
- reasoning
- decision
- timestamp