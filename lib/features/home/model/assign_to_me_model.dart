// lib/features/home/model/assign_to_me_model.dart
// FULLY UPDATED – WITH annexes support

import 'package:flutter/material.dart';

class AssignToMeModel {
  final int id;
  final String title;
  final String description;
  final String tors;
  final String timeFrame;
  final String priority;        // "1" = Low, "2" = Medium, "3" = High
  final String status;         // "0" = Submitted, etc.
  final String inquiryType;
  final String department;
  final String initiator;
  final String recommender;
  final String assignedTo;
  final List<String> teamMembers;
  final String userRole;         // e.g., "Chairperson", "Member"
  final DateTime createdAt;

  final List<dynamic> recommendations;
  final List<dynamic> visits;
  final List<dynamic> annexes;  // ADDED
  final List<dynamic> requiredDocuments;
  final dynamic finalizedFindings; // Map of {id, findings, user_id, user} or null

  const AssignToMeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tors,
    required this.timeFrame,
    required this.priority,
    required this.status,
    required this.inquiryType,
    required this.department,
    required this.initiator,
    required this.recommender,
    required this.assignedTo,
    required this.teamMembers,
    required this.userRole,
    required this.createdAt,
    this.recommendations = const [],
    this.visits = const [],
    this.annexes = const [],  // ADDED
    this.requiredDocuments = const [],
    this.finalizedFindings,
  });

  factory AssignToMeModel.fromJson(Map<String, dynamic> json) {
    return AssignToMeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: _stripHtml((json['title'] ?? '').toString().trim()),
      description: _stripHtml((json['description'] ?? '').toString()),
      tors: _stripHtml((json['tors'] ?? json['tor'] ?? '').toString()),
      timeFrame: (json['time_frame'] ?? json['timeFrame'] ?? '').toString().trim(),
      priority: (json['priority'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      inquiryType: _safeString(json['inquiry_type'] ?? json['inquiryType']),
      department: _safeString(json['department'] ?? json['department_name']),
      initiator: _safeString(json['initiator']),
      recommender: _safeString(json['recommender']),
      assignedTo: _safeString(json['assigned_to'] ?? json['assignedTo']),
      teamMembers: _parseTeamMembers(json['team_members']),
      userRole: (json['user_role'] ?? json['role'] ?? 'Member').toString().trim(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      recommendations: json['recommendations'] ?? [],
      visits: _parseVisits(json['visits'] ?? []),
      annexes: _parseAnnexes(json['annexes'] ?? []),  // ADDED
      requiredDocuments: json['required_documents'] ?? [],
      finalizedFindings: json['finalizedFindings'] ?? json['finalized_findings'],
    );
  }

  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) return (value['name'] ?? value['title'] ?? '').toString().trim();
    return value.toString().trim();
  }

  // Strip HTML tags from strings
  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    // Remove HTML tags
    String stripped = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities
    stripped = stripped
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Clean up multiple spaces and trim
    stripped = stripped.replaceAll(RegExp(r'\s+'), ' ').trim();

    return stripped;
  }

  static List<String> _parseTeamMembers(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map<String>((item) {
      if (item is String) return item.trim();
      if (item is Map) {
        return (item['name'] ??
            item['user']?['name'] ??
            item['full_name'] ??
            '')
            .toString()
            .trim();
      }
      return '';
    }).where((name) => name.isNotEmpty).toList();
  }

  // ROBUST VISITS PARSING - Handles list of findings OR legacy string format
  static List<dynamic> _parseVisits(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((visit) {
      if (visit is! Map<String, dynamic>) return visit;

      final Map<String, dynamic> processedVisit = Map.from(visit);

      final dynamic findingsData = visit['findings'];

      List<Map<String, dynamic>> processedFindings = [];

      if (findingsData is List) {
        // Standard format: list of finding maps
        processedFindings = findingsData.map((finding) {
          if (finding is! Map<String, dynamic>) {
            // Safety fallback
            return <String, dynamic>{
              'user': visit['officer'] ?? 'Unknown',
              'findings': _stripHtml(finding.toString()),
            };
          }

          final Map<String, dynamic> f = Map.from(finding);
          if (f['findings'] != null) {
            f['findings'] = _stripHtml(f['findings'].toString());
          }
          if (f['user'] == null) {
            f['user'] = visit['officer'] ?? 'Unknown Officer';
          }
          return f;
        }).cast<Map<String, dynamic>>().toList();
      } else if (findingsData is String && findingsData.trim().isNotEmpty) {
        // Legacy format: findings is a raw HTML string
        processedFindings = [
          {
            'id': 0,
            'visit_id': visit['id']?.toString() ?? '',
            'user': visit['officer'] ?? 'Unknown Officer',
            'findings': _stripHtml(findingsData),
          }
        ];
      } else {
        // Empty or null
        processedFindings = [];
      }

      processedVisit['findings'] = processedFindings;
      return processedVisit;
    }).toList();
  }

  // PARSE ANNEXES FROM API
  static List<dynamic> _parseAnnexes(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((annex) {
      if (annex is! Map<String, dynamic>) return annex;

      final Map<String, dynamic> processedAnnex = Map.from(annex);

      // Normalize the ID field
      if (processedAnnex.containsKey('annex_id') && !processedAnnex.containsKey('id')) {
        processedAnnex['id'] = processedAnnex['annex_id'];
      }

      // Parse annex files if present
      final dynamic filesData = annex['annex_files'];
      if (filesData is List) {
        processedAnnex['annex_files'] = filesData.map((file) {
          if (file is Map<String, dynamic>) {
            return Map<String, dynamic>.from(file);
          }
          return file;
        }).toList();
      } else {
        processedAnnex['annex_files'] = [];
      }

      return processedAnnex;
    }).toList();
  }

  // Convert model back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tors': tors,
      'time_frame': timeFrame,
      'priority': priority,
      'status': status,
      'inquiry_type': inquiryType,
      'department': department,
      'initiator': initiator,
      'recommender': recommender,
      'assigned_to': assignedTo,
      'team_members': teamMembers,
      'user_role': userRole,
      'created_at': createdAt.toIso8601String(),
      'recommendations': recommendations,
      'visits': visits,
      'annexes': annexes,  // ADDED
      'required_documents': requiredDocuments,
      'finalizedFindings': finalizedFindings,
    };
  }

  // Copy with method for immutability
  AssignToMeModel copyWith({
    int? id,
    String? title,
    String? description,
    String? tors,
    String? timeFrame,
    String? priority,
    String? status,
    String? inquiryType,
    String? department,
    String? initiator,
    String? recommender,
    String? assignedTo,
    List<String>? teamMembers,
    String? userRole,
    DateTime? createdAt,
    List<dynamic>? recommendations,
    List<dynamic>? visits,
    List<dynamic>? annexes,  // ADDED
    List<dynamic>? requiredDocuments,
    dynamic finalizedFindings,
  }) {
    return AssignToMeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tors: tors ?? this.tors,
      timeFrame: timeFrame ?? this.timeFrame,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      inquiryType: inquiryType ?? this.inquiryType,
      department: department ?? this.department,
      initiator: initiator ?? this.initiator,
      recommender: recommender ?? this.recommender,
      assignedTo: assignedTo ?? this.assignedTo,
      teamMembers: teamMembers ?? this.teamMembers,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
      recommendations: recommendations ?? this.recommendations,
      visits: visits ?? this.visits,
      annexes: annexes ?? this.annexes,  // ADDED
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      finalizedFindings: finalizedFindings ?? this.finalizedFindings,
    );
  }
}

// EXTENSION WITH ALL GOODIES
extension AssignToMeModelX on AssignToMeModel {
  bool get isChairperson => userRole.toLowerCase().contains('chair');

  bool get isFindingsFinalized {
    if (finalizedFindings == null) return false;
    if (finalizedFindings is Map) {
      return (finalizedFindings as Map).isNotEmpty;
    }
    return true;
  }

  String get statusText => switch (status) {
    '0' => 'Submitted',
    '1' => 'Recommended',
    '2' => 'Assigned',
    '3' => 'Under Review',
    '4' => 'Completed',
    '5' => 'Rejected',
    _ => 'Unknown',
  };

  String get priorityText => switch (priority) {
    '1' => 'Low',
    '2' => 'Medium',
    '3' => 'High',
    _ => 'Normal',
  };

  Color get statusColor => Colors.grey.shade700; // All statuses use professional Grey as requested

  Color get priorityColor => Colors.grey.shade700; // All priorities use professional Grey as requested

  String get formattedDate =>
      '${createdAt.day.toString().padLeft(2, '0')}/'
          '${createdAt.month.toString().padLeft(2, '0')}/'
          '${createdAt.year}';

  List<Map<String, String>> get parsedRecommendations {
    return recommendations.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'recommendation':
          (item['recommendation'] ?? item['text'] ?? item['description'] ?? '')
              .toString()
              .trim(),
          'penalty_imposed':
          (item['penalty_imposed'] ?? item['penalty'] ?? 'None')
              .toString()
              .trim(),
        };
      }
      return {
        'recommendation': item.toString().trim(),
        'penalty_imposed': 'None',
      };
    }).toList();
  }

  List<VisitInfo> get parsedVisits {
    return visits.map((visit) {
      if (visit is Map<String, dynamic>) {
        return VisitInfo.fromJson(visit);
      }
      return VisitInfo.empty();
    }).toList();
  }

  List<AnnexInfo> get parsedAnnexes {
    return annexes.map((annex) {
      if (annex is Map<String, dynamic>) {
        return AnnexInfo.fromJson(annex);
      }
      return AnnexInfo.empty();
    }).toList();
  }

  List<FindingInfo> get allFindings {
    return parsedVisits.expand((visit) => visit.findings).toList();
  }

  bool get hasVisits => visits.isNotEmpty;
  bool get hasFindings => allFindings.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;
  bool get hasAnnexes => annexes.isNotEmpty;  // ADDED
}

// Helper class for Visit information
class VisitInfo {
  final int id;
  final String vehicle;
  final String officer;
  final String driver;
  final DateTime visitDate;
  final String visitTime;
  final List<FindingInfo> findings;

  const VisitInfo({
    required this.id,
    required this.vehicle,
    required this.officer,
    required this.driver,
    required this.visitDate,
    required this.visitTime,
    required this.findings,
  });

  factory VisitInfo.fromJson(Map<String, dynamic> json) {
    return VisitInfo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vehicle: (json['vehicle'] ?? '').toString().trim(),
      officer: (json['officer'] ?? '').toString().trim(),
      driver: (json['driver'] ?? '').toString().trim(),
      visitDate: DateTime.tryParse(json['visit_date']?.toString() ?? '') ?? DateTime.now(),
      visitTime: (json['visit_time'] ?? '').toString().trim(),
      findings: _parseFindings(json['findings'] ?? []),
    );
  }

  factory VisitInfo.empty() {
    return VisitInfo(
      id: 0,
      vehicle: '',
      officer: '',
      driver: '',
      visitDate: DateTime.now(),
      visitTime: '',
      findings: [],
    );
  }

  static List<FindingInfo> _parseFindings(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((finding) {
      if (finding is Map<String, dynamic>) {
        return FindingInfo.fromJson(finding);
      }
      return FindingInfo.empty();
    }).toList();
  }

  String get formattedDate =>
      '${visitDate.day.toString().padLeft(2, '0')}/'
          '${visitDate.month.toString().padLeft(2, '0')}/'
          '${visitDate.year}';
}

// Helper class for Finding information
class FindingInfo {
  final int id;
  final String visitId;
  final String user;
  final String findings;

  const FindingInfo({
    required this.id,
    required this.visitId,
    required this.user,
    required this.findings,
  });

  factory FindingInfo.fromJson(Map<String, dynamic> json) {
    return FindingInfo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      visitId: (json['visit_id'] ?? '').toString(),
      user: (json['user'] ?? '').toString().trim(),
      findings: (json['findings'] ?? '').toString().trim(),
    );
  }

  factory FindingInfo.empty() {
    return const FindingInfo(
      id: 0,
      visitId: '',
      user: '',
      findings: '',
    );
  }
}

// Helper class for Annex information
class AnnexInfo {
  final int id;
  final String title;
  final String sortOrder;
  final List<AnnexFile> files;

  const AnnexInfo({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.files,
  });

  factory AnnexInfo.fromJson(Map<String, dynamic> json) {
    return AnnexInfo(
      id: int.tryParse((json['id'] ?? json['annex_id']).toString()) ?? 0,
      title: (json['title'] ?? 'Untitled Annex').toString().trim(),
      sortOrder: (json['sort_order'] ?? '0').toString(),
      files: _parseFiles(json['annex_files'] ?? []),
    );
  }

  factory AnnexInfo.empty() {
    return const AnnexInfo(
      id: 0,
      title: '',
      sortOrder: '0',
      files: [],
    );
  }

  static List<AnnexFile> _parseFiles(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((file) {
      if (file is Map<String, dynamic>) {
        return AnnexFile.fromJson(file);
      }
      return AnnexFile.empty();
    }).toList();
  }

  bool get hasFiles => files.isNotEmpty;
}

// Helper class for Annex File information
class AnnexFile {
  final int id;
  final String fileType;
  final String link;

  const AnnexFile({
    required this.id,
    required this.fileType,
    required this.link,
  });

  factory AnnexFile.fromJson(Map<String, dynamic> json) {
    return AnnexFile(
      id: int.tryParse((json['annex_file_id'] ?? json['id']).toString()) ?? 0,
      fileType: (json['file_type'] ?? '').toString().trim(),
      link: (json['link'] ?? '').toString().trim(),
    );
  }

  factory AnnexFile.empty() {
    return const AnnexFile(
      id: 0,
      fileType: '',
      link: '',
    );
  }

  bool get isImage => fileType.toLowerCase().contains('image') ||
      link.toLowerCase().endsWith('.jpg') ||
      link.toLowerCase().endsWith('.jpeg') ||
      link.toLowerCase().endsWith('.png');

  bool get isPdf => fileType.toLowerCase().contains('pdf') ||
      link.toLowerCase().endsWith('.pdf');
}