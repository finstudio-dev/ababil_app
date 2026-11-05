class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // 'member' | 'admin'
  final String status; // 'pending' | 'active' | 'suspended' | 'rejected'
  final DateTime createdAt;
  final String? address;
  final String? nidNumber;
  final String? photoUrl;
  final String? nidPhotoUrl;
  final String? avatarUrl;
  final DateTime? verificationSubmittedAt;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime? verificationRequestedAt;
  final String? verificationRequestedNote;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.address,
    this.nidNumber,
    this.photoUrl,
    this.nidPhotoUrl,
    this.avatarUrl,
    this.verificationSubmittedAt,
    this.reviewedAt,
    this.reviewNote,
    this.verificationRequestedAt,
    this.verificationRequestedNote,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      address: map['address'] as String?,
      nidNumber: map['nid_number'] as String?,
      photoUrl: map['photo_url'] as String?,
      nidPhotoUrl: map['nid_photo_url'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      verificationSubmittedAt: map['verification_submitted_at'] == null
          ? null
          : DateTime.parse(map['verification_submitted_at'] as String),
      reviewedAt: map['reviewed_at'] == null
          ? null
          : DateTime.parse(map['reviewed_at'] as String),
      reviewNote: map['review_note'] as String?,
      verificationRequestedAt: map['verification_requested_at'] == null
          ? null
          : DateTime.parse(map['verification_requested_at'] as String),
      verificationRequestedNote: map['verification_requested_note'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isSuspended => status == 'suspended';
  bool get isRejected => status == 'rejected';

  /// Whether this member has ever submitted their identity verification
  /// info (address, NID, photos). A 'pending' member with this false hasn't
  /// filled out the verification form yet; a 'pending' member with this
  /// true is waiting on an admin's review.
  bool get hasSubmittedVerification => verificationSubmittedAt != null;

  /// True when an admin has asked this member to update/resubmit their
  /// verification documents, even though their account is still active.
  bool get hasPendingReverificationRequest => verificationRequestedAt != null;
}
