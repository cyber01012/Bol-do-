class LogEntry {
  final String agent;
  final String workflowStage;
  final String decision;
  final String reasoning;
  final String actionTaken;
  final String severity;
  final DateTime timestamp;
  
  // Newly requested fields
  final List<String>? toolCalls;
  final String? errorRecovery;
  final String? finalOutcomes;

  LogEntry({
    required this.agent,
    required this.workflowStage,
    required this.decision,
    required this.reasoning,
    required this.actionTaken,
    required this.severity,
    required this.timestamp,
    this.toolCalls,
    this.errorRecovery,
    this.finalOutcomes,
  });

  Map<String, dynamic> toJson() {
    return {
      'agent': agent,
      'workflow_stage': workflowStage,
      'decision': decision,
      'reasoning': reasoning,
      'action_taken': actionTaken,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      if (toolCalls != null) 'tool_calls': toolCalls,
      if (errorRecovery != null) 'error_recovery': errorRecovery,
      if (finalOutcomes != null) 'final_outcomes': finalOutcomes,
    };
  }
}
