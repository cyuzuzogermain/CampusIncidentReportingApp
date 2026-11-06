part of 'report_form_cubit.dart';

enum ReportFormStatus { initial, submitting, success, failure }

class ReportFormState extends Equatable {
  const ReportFormState({
    this.category,
    this.location,
    this.image,
    this.existingImageUrl,
    this.status = ReportFormStatus.initial,
    this.incidentId,
    this.errorMessage,
  });

  final IncidentCategory? category;
  final String? location;

  /// The picked photo, if any.
  final PickedImage? image;

  /// When editing, the report's current photo, until it's removed. A newly
  /// picked [image] replaces it.
  final String? existingImageUrl;
  final ReportFormStatus status;

  /// The id of the created incident once [status] is success.
  final String? incidentId;
  final String? errorMessage;

  bool get isSubmitting => status == ReportFormStatus.submitting;

  ReportFormState copyWith({
    IncidentCategory? category,
    String? location,
    PickedImage? Function()? image,
    String? Function()? existingImageUrl,
    ReportFormStatus? status,
    String? Function()? incidentId,
    String? Function()? errorMessage,
  }) {
    return ReportFormState(
      category: category ?? this.category,
      location: location ?? this.location,
      image: image != null ? image() : this.image,
      existingImageUrl: existingImageUrl != null
          ? existingImageUrl()
          : this.existingImageUrl,
      status: status ?? this.status,
      incidentId: incidentId != null ? incidentId() : this.incidentId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    category,
    location,
    image,
    existingImageUrl,
    status,
    incidentId,
    errorMessage,
  ];
}
