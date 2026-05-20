class OrchestrationSession {
  final String sessionId;
  final Map<String, bool> completedAgents;
  final DateTime lastUpdated;
  final String pipelineStatus;
  final String? activeBookingId;

  OrchestrationSession({
    required this.sessionId,
    required this.completedAgents,
    required this.lastUpdated,
    required this.pipelineStatus,
    this.activeBookingId,
  });

  factory OrchestrationSession.fromJson(Map<String, dynamic> json) {
    return OrchestrationSession(
      sessionId: json['session_id'] as String,
      completedAgents: Map<String, bool>.from(json['completed_agents'] as Map? ?? {}),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      pipelineStatus: json['pipeline_status'] as String? ?? 'pending',
      activeBookingId: json['active_booking_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'completed_agents': completedAgents,
      'last_updated': lastUpdated.toIso8601String(),
      'pipeline_status': pipelineStatus,
      'active_booking_id': activeBookingId,
    };
  }
}
