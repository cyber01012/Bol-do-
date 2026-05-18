# voice-processing-flow.md

# Voice Processing Workflow

Purpose:
Defines the lifecycle for handling multilingual voice input and AI-generated voice responses.

---

# Workflow Sequence

Voice Input
→ Audio Capture
→ Noise Reduction
→ Speech-to-Text Conversion
→ Language Detection
→ Text Normalization
→ Intent Pipeline
→ AI Response Generation
→ Text-to-Speech Conversion
→ Voice Output

---

# Supported Languages

- Urdu
- Roman Urdu
- English
- Mixed language input

Examples:
- "Mujhe kal plumber chahiye"
- "Need electrician tomorrow"
- "Kal morning AC technician chahiye DHA"

---

# Step 1 — Audio Capture

Responsible Agent:
Voice Agent

Tasks:
- capture microphone input
- validate audio quality
- detect silence/noise

Input Type:
Audio stream

---

# Step 2 — Noise Reduction

Tasks:
- remove background noise
- improve speech clarity
- normalize audio levels

---

# Step 3 — Speech-to-Text Conversion

Tasks:
- convert speech into text
- preserve multilingual phrases
- preserve mixed-language context

Output:
Normalized text string

Example:

Input Audio:
"Mujhe kal plumber chahiye DHA"

Output Text:
"Mujhe kal plumber chahiye DHA"

---

# Step 4 — Language Detection

Tasks:
- detect Urdu
- detect Roman Urdu
- detect English
- detect mixed language

Output:
{
  "language": "Roman Urdu",
  "confidence": 0.93
}

---

# Step 5 — Text Normalization

Tasks:
- spelling correction
- slang normalization
- abbreviation expansion

Examples:
- "plmbr" → "plumber"
- "tmrw" → "tomorrow"

---

# Step 6 — Intent Pipeline Trigger

Connected Agent:
Intent Agent

Tasks:
- pass normalized text
- begin intent extraction workflow

---

# Step 7 — AI Response Generation

Tasks:
- generate response text
- generate clarification questions
- generate booking confirmations

Example:
"Your booking has been confirmed for tomorrow at 10 AM."

---

# Step 8 — Text-to-Speech Conversion

Tasks:
- convert AI response into speech
- generate multilingual voice output

Output Type:
Audio response

---

# Step 9 — Voice Output

Tasks:
- play generated audio
- confirm delivery success

---

# Failure Handling

No Speech Detected:
→ ask user to repeat

Low Audio Quality:
→ request clearer voice input

Low Language Confidence:
→ clarification request

Speech Conversion Failure:
→ retry conversion

---

# Timeout Rules

Speech-to-Text:
5 seconds

Text-to-Speech:
5 seconds

Retry Attempts:
3

---

# Logging Requirements

Must Log:
- detected language
- confidence score
- transcription output
- retry attempts
- processing time