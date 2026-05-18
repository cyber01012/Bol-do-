# Code Review Prompt

Act as a Senior Software Engineer performing a professional code review.

Read:
- architecture.md
- system-rules.md
- relevant role file
- relevant system file
- api-contracts.md

Analyze the provided code for:

## Architecture
- modularity
- scalability
- separation of concerns
- consistency with architecture

## Code Quality
- readability
- maintainability
- unnecessary complexity
- duplicate logic
- naming consistency

## Performance
- unnecessary re-renders
- redundant API calls
- inefficient logic
- Firebase misuse

## Reliability
- edge cases
- error handling
- null safety
- validation issues

## Security
- exposed secrets
- unsafe Firebase usage
- missing validations

## Integration
- API contract mismatches
- schema inconsistencies
- broken workflows

Output:
- detected issues
- severity level
- recommended fixes
- improved code snippets if necessary

Requirements:
- do not rewrite entire architecture unnecessarily
- preserve existing functionality
- prioritize maintainability