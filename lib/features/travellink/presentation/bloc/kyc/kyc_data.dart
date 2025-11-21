import 'package:equatable/equatable.dart';

/// Data class to hold KYC-specific properties
class KycData extends Equatable {
  final String status; // not_submitted, pending, approved, rejected
  final Map<String, String> uploadedDocuments; // documentType -> downloadUrl
  final Map<String, double> uploadProgress; // documentType -> progress (0.0 to 1.0)
  final String? currentDocument; // Currently uploading document
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  const KycData({
    this.status = 'not_submitted',
    this.uploadedDocuments = const {},
    this.uploadProgress = const {},
    this.currentDocument,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  KycData copyWith({
    String? status,
    Map<String, String>? uploadedDocuments,
    Map<String, double>? uploadProgress,
    String? currentDocument,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) {
    return KycData(
      status: status ?? this.status,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentDocument: currentDocument ?? this.currentDocument,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isSubmitted => status == 'pending' || status == 'approved' || status == 'rejected';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isUploading => currentDocument != null;

  /// Check if a specific document is uploaded
  bool hasDocument(String documentType) => uploadedDocuments.containsKey(documentType);

  /// Get upload progress for a specific document
  double getProgress(String documentType) => uploadProgress[documentType] ?? 0.0;

  /// Check if all required documents are uploaded
  bool get hasAllDocuments {
    return hasDocument('government_id') &&
        hasDocument('selfie_with_id') &&
        hasDocument('proof_of_address');
  }

  @override
  List<Object?> get props => [
        status,
        uploadedDocuments,
        uploadProgress,
        currentDocument,
        submittedAt,
        approvedAt,
        rejectedAt,
        rejectionReason,
      ];
}
