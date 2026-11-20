import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/templates/template_catalog_panel.dart';
import 'package:workshop_admin_app/src/features/templates/template_details_step.dart';
import 'package:workshop_admin_app/src/features/templates/template_publish_step.dart';
import 'package:workshop_admin_app/src/features/templates/template_route_chrome.dart';
import 'package:workshop_admin_app/src/features/templates/template_selected_item.dart';
import 'package:workshop_admin_app/src/features/templates/template_sequence_step.dart';
import 'package:workshop_admin_app/src/features/templates/template_version_page.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Template builder as a three-step route: Details → Sequence → Publish.
///
/// Every call is the one the previous builder made: `saveTemplateDraft`,
/// `publishTemplate`, `retireTemplate`, `createTemplateDraft`, the same
/// providers and the same item payload (master version id + sort order).
class TemplateBuilderPage extends ConsumerStatefulWidget {
  const TemplateBuilderPage({
    required this.templateId,
    this.autoDraft = false,
    super.key,
  });

  final String templateId;

  /// When true (we just created this template), a missing draft is created
  /// automatically so the user lands in an editable builder instead of a
  /// locked "create draft" panel.
  final bool autoDraft;

  @override
  ConsumerState<TemplateBuilderPage> createState() =>
      _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends ConsumerState<TemplateBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _serviceType = TextEditingController();
  final _vehicleType = TextEditingController();
  final _search = TextEditingController();
  String _categoryId = '';
  int _step = 0;
  final List<TemplateSelectedItem> _selected = [];
  bool _initialized = false;
  bool _busy = false;
  bool _autoDraftTried = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _serviceType.dispose();
    _vehicleType.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _itemKey => '${_search.text}\u0001$_categoryId';

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    final categories = ref.watch(workshopCategoriesProvider);
    final items = ref.watch(publishedItemsProvider(_itemKey));
    final template = detail.value;
    final readOnly = template != null && template.draft == null;

    if (detail.isLoading || categories.isLoading || items.isLoading) {
      return Scaffold(
        backgroundColor: ws.canvas,
        body: SafeArea(
          child: Column(
            children: [
              TemplateRouteTopBar(
                title: t(WorkshopAdminKeys.templateBuilder),
                template: null,
                readOnly: true,
                busy: false,
                onSaveDraft: () {},
              ),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32),
                  child: WorkshopSkeleton(lines: 8, card: true),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (detail.hasError || categories.hasError || items.hasError) {
      return Scaffold(
        backgroundColor: ws.canvas,
        body: SafeArea(
          child: Column(
            children: [
              TemplateRouteTopBar(
                title: t(WorkshopAdminKeys.templateBuilder),
                template: null,
                readOnly: true,
                busy: false,
                onSaveDraft: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: ws.pagePadding(width),
                  child: WorkshopErrorState(
                    title: t(WorkshopAdminKeys.error),
                    body: t(WorkshopAdminKeys.genericError),
                    retryLabel: t(WorkshopAdminKeys.retryAction),
                    onRetry: () {
                      ref.invalidate(templateDetailProvider(widget.templateId));
                      ref.invalidate(workshopCategoriesProvider);
                      ref.invalidate(publishedItemsProvider(_itemKey));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = template!;
    _initialize(loaded);
    if (widget.autoDraft && loaded.draft == null && !_autoDraftTried) {
      _autoDraftTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _createDraft();
        }
      });
    }

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TemplateRouteTopBar(
              title: loaded.name,
              template: loaded,
              readOnly: readOnly,
              busy: _busy,
              onSaveDraft: _saveDraftWithFeedback,
            ),
            TemplateRouteStepper(step: _step, onSelect: _goTo),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        if (readOnly && _step < 2)
                          TemplateRouteLockedPanel(
                            busy: _busy,
                            onCreateDraft: _createDraft,
                          )
                        else
                          switch (_step) {
                            0 => TemplateDetailsStep(
                              formKey: _formKey,
                              name: _name,
                              description: _description,
                              serviceType: _serviceType,
                              vehicleType: _vehicleType,
                              enabled: !readOnly,
                            ),
                            1 => _sequenceStep(
                              loaded,
                              categories.value ?? const [],
                              items.value ?? const [],
                            ),
                            _ => TemplatePublishStep(
                              name: loaded.name,
                              status: loaded.status,
                              itemCount: _selected.isEmpty
                                  ? loaded.draft?.items.length ?? 0
                                  : _selected.length,
                              versions: loaded.versions,
                              busy: _busy,
                              hasDraft: loaded.draft != null,
                              onPublish: _publish,
                              onPreview: _preview,
                              onRetire: _retire,
                              onOpenVersion: _openVersion,
                            ),
                          },
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_step < 2 && !readOnly)
              TemplateRouteFooter(
                step: _step,
                busy: _busy,
                onBack: () => _goTo(_step - 1),
                onNext: () => _goTo(_step + 1),
                onSaveDraft: _saveDraftWithFeedback,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sequenceStep(
    TemplateDetail template,
    List<Category> categories,
    List<PublishedItem> catalog,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final sequence = TemplateSequenceStep(
      items: _selected,
      enabled: template.draft != null,
      onMoveUp: (index) => _itemAction(index, 'up'),
      onMoveDown: (index) => _itemAction(index, 'down'),
      onRemove: (index) => _itemAction(index, 'remove'),
    );
    final panel = TemplateCatalogPanel(
      items: catalog,
      categories: categories,
      search: _search,
      categoryId: _categoryId,
      selectedIds: _selected.map((item) => item.masterItemVersionId).toSet(),
      onSearchChanged: (_) => setState(() {}),
      onCategoryChanged: (value) => setState(() => _categoryId = value),
      onAdd: _add,
    );
    if (width < 1100) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [sequence, const SizedBox(height: 16), panel],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: sequence),
        const SizedBox(width: 18),
        SizedBox(width: 320, child: panel),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Logic (same calls as the previous builder)
  // -------------------------------------------------------------------------

  void _initialize(TemplateDetail template) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _name.text = template.name;
    _description.text = template.description ?? '';
    _serviceType.text = template.serviceType;
    _vehicleType.text = template.vehicleType ?? '';
    _selected
      ..clear()
      ..addAll(
        (template.draft?.items ?? <TemplateItemView>[]).map(
          TemplateSelectedItem.fromView,
        ),
      );
  }

  bool _contains(String versionId) =>
      _selected.any((item) => item.masterItemVersionId == versionId);

  void _add(PublishedItem item) {
    if (_contains(item.versionId)) {
      return;
    }
    setState(() => _selected.add(TemplateSelectedItem.fromPublished(item)));
  }

  void _itemAction(int index, String action) {
    setState(() {
      if (action == 'remove') {
        _selected.removeAt(index);
      } else if (action == 'up' && index > 0) {
        final item = _selected.removeAt(index);
        _selected.insert(index - 1, item);
      } else if (action == 'down' && index < _selected.length - 1) {
        final item = _selected.removeAt(index);
        _selected.insert(index + 1, item);
      }
    });
  }

  void _goTo(int step) {
    // Validate only when leaving the details step: the Form is unmounted on
    // the other steps, so its state is null there.
    if (_step == 0 && step > 0) {
      final valid = _formKey.currentState?.validate() ?? true;
      if (!valid) {
        return;
      }
    }
    setState(() => _step = step.clamp(0, 2));
  }

  Future<void> _saveDraftWithFeedback() async {
    final t = UiStrings.of(context);
    setState(() => _busy = true);
    try {
      await _saveDraft();
      if (mounted) {
        _notify(t(WorkshopAdminKeys.contentSaved));
      }
    } on Object {
      if (mounted) {
        _notify(t(WorkshopAdminKeys.actionFailed));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    await ref
        .read(adminApiProvider)
        .saveTemplateDraft(
          id: widget.templateId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          serviceType: _serviceType.text.trim(),
          vehicleType: _vehicleType.text.trim(),
          items: _selected
              .asMap()
              .entries
              .map(
                (entry) => TemplateItemDraft(
                  masterItemVersionId: entry.value.masterItemVersionId,
                  sortOrder: entry.key,
                ),
              )
              .toList(),
        );
    ref.invalidate(templateDetailProvider(widget.templateId));
    ref.invalidate(templatesProvider);
    _initialized = false;
  }

  Future<void> _publish() async {
    final t = UiStrings.of(context);
    if (!(_formKey.currentState?.validate() ?? true)) {
      setState(() => _step = 0);
      return;
    }
    setState(() => _busy = true);
    try {
      await _saveDraft();
      await ref.read(adminApiProvider).publishTemplate(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      ref.invalidate(templatesProvider);
      _initialized = false;
      if (mounted) {
        _notify(t(WorkshopAdminKeys.templatePublished));
      }
    } on Object {
      if (mounted) {
        _notify(t(WorkshopAdminKeys.actionFailed));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createDraft() async {
    final t = UiStrings.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).createTemplateDraft(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
    } on Object {
      if (mounted) {
        _notify(t(WorkshopAdminKeys.actionFailed));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _retire() async {
    final t = UiStrings.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: t(WorkshopAdminKeys.retire),
      message: t(WorkshopAdminKeys.confirm),
      confirmLabel: t(WorkshopAdminKeys.retire),
      cancelLabel: t(WorkshopAdminKeys.cancel),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).retireTemplate(widget.templateId);
      ref.invalidate(templatesProvider);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        _notify(t(WorkshopAdminKeys.actionFailed));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _preview() async {
    final t = UiStrings.of(context);
    final ws = context.ws;
    await showAppBottomSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t(WorkshopAdminKeys.preview),
            style: ws.cardTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 12),
          if (_selected.isEmpty)
            Text(
              t(WorkshopAdminKeys.noItems),
              style: ws.body.copyWith(color: ws.muted),
            )
          else
            for (var i = 0; i < _selected.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: ws.meta.copyWith(
                        color: ws.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selected[i].labelEn,
                            style: ws.bodyStrong.copyWith(
                              fontSize: 13.5,
                              color: ws.ink,
                            ),
                          ),
                          Text(
                            _selected[i].instructionEn,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openVersion(String versionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateVersionPage(
          templateId: widget.templateId,
          versionId: versionId,
        ),
      ),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
