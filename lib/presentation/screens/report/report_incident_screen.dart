import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/incident_category.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/report_form/report_form_cubit.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/photo_picker_field.dart';
import '../../widgets/primary_button.dart';

class ReportIncidentScreen extends StatelessWidget {
  const ReportIncidentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportFormCubit(context.read<IncidentRepository>()),
      child: const ReportIncidentView(),
    );
  }
}

/// The form itself. Expects a [ReportFormCubit] and an [AuthCubit] above it.
/// When the cubit is editing a report, the form starts from that report and
/// saves changes instead of submitting a new one.
class ReportIncidentView extends StatefulWidget {
  const ReportIncidentView({super.key});

  @override
  State<ReportIncidentView> createState() => _ReportIncidentViewState();
}

class _ReportIncidentViewState extends State<ReportIncidentView> {
  final _formKey = GlobalKey<FormState>();
  late final _editing = context.read<ReportFormCubit>().editing;
  late final _titleController = TextEditingController(text: _editing?.title);
  late final _descriptionController = TextEditingController(
    text: _editing?.description,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<ReportFormCubit>().submit(
      title: _titleController.text,
      description: _descriptionController.text,
      reporter: context.read<AuthCubit>().state.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportFormCubit, ReportFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == ReportFormStatus.success) {
          if (_editing != null) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Your changes were saved.')),
            );
            // Back to the report's details, which update live.
            context.pop();
            return;
          }
          messenger.showSnackBar(
            const SnackBar(content: Text('Report submitted. Thank you!')),
          );
          // Replace the form so "back" returns to where the student was.
          context.pushReplacement(AppRoutes.incidentDetails(state.incidentId!));
        } else if (state.status == ReportFormStatus.failure) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;
        return PopScope(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _editing == null ? 'Report an Incident' : 'Edit Report',
              ),
            ),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    8,
                    AppDimens.screenPadding,
                    32,
                  ),
                  children: [
                    const Text('Category', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    _CategoryField(
                      selected: state.category,
                      enabled: !busy,
                      onSelected: context
                          .read<ReportFormCubit>()
                          .selectCategory,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Title',
                      hint: 'e.g. Broken light in corridor',
                      controller: _titleController,
                      maxLength: AppConstants.titleMaxLength,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !busy,
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Description',
                      hint: 'Describe the issue in a few words',
                      controller: _descriptionController,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !busy,
                      validator: Validators.description,
                    ),
                    const SizedBox(height: 20),
                    const Text('Location', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.location,
                      isExpanded: true,
                      hint: const Text('Select a location'),
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: [
                        for (final location in AppConstants.campusLocations)
                          DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ),
                      ],
                      validator: Validators.location,
                      onChanged: busy
                          ? null
                          : (value) {
                              if (value != null) {
                                context.read<ReportFormCubit>().selectLocation(
                                  value,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Text('Photo', style: AppTextStyles.label),
                        SizedBox(width: 6),
                        Text('(optional)', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PhotoPickerField(
                      image: state.image,
                      imageUrl: state.existingImageUrl,
                      enabled: !busy,
                      onPicked: context.read<ReportFormCubit>().setImage,
                      onRemoved: context.read<ReportFormCubit>().removeImage,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _editing == null
                          ? 'Submit Report'
                          : 'Save Changes',
                      icon: _editing == null
                          ? Icons.send_rounded
                          : Icons.check_rounded,
                      isLoading: busy,
                      onPressed: _submit,
                    ),
                    if (busy && state.image != null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Uploading photo…',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The category grid wrapped in a [FormField] so it takes part in form
/// validation and shows an error when nothing is selected.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormField<IncidentCategory>(
      initialValue: selected,
      validator: Validators.category,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                for (final category in IncidentCategory.values)
                  CategoryTile(
                    category: category,
                    selected: field.value == category,
                    onTap: enabled
                        ? () {
                            field.didChange(category);
                            // Clear a shown "Please select a category" error.
                            if (field.hasError) field.validate();
                            onSelected(category);
                          }
                        : null,
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
