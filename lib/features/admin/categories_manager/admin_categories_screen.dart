import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_mapper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/category.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/locale_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final s = ref.watch(stringsProvider);

    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  s.t('categories'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const _CategoryFormDialog(),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(s.t('add_category')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: categories.when(
                loading: () => const ListShimmer(itemCount: 5),
                error: (_, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: s.t('categories_load_error'),
                  actionLabel: s.t('retry'),
                  onAction: () => ref.invalidate(categoriesProvider),
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.tag,
                        title: s.t('no_categories'),
                      )
                    : Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final cat = list[i];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.red.withValues(alpha: 0.08),
                                  child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: cat.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => Icon(
                                            lucideIcon(cat.icon),
                                            size: 22,
                                            color: AppColors.red,
                                          ),
                                        )
                                      : Icon(
                                          lucideIcon(cat.icon),
                                          size: 22,
                                          color: AppColors.red,
                                        ),
                                ),
                              ),
                              title: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('${s.t('icon')}: ${cat.icon ?? '—'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.pencil,
                                      size: 18,
                                    ),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) =>
                                          _CategoryFormDialog(category: cat),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 18,
                                      color: AppColors.red,
                                    ),
                                    onPressed: () =>
                                        _delete(context, ref, cat),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('delete_category_q')),
        content: Text(s.t('delete_category_warn', {'name': cat.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.t('yes_delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(productServiceProvider).deleteCategory(cat.id);
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('delete_category_failed'))),
        );
      }
    }
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _imageUrl;
  String? _icon;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _imageUrl = TextEditingController(text: widget.category?.imageUrl ?? '');
    _icon = widget.category?.icon;
  }

  @override
  void dispose() {
    _name.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpeg';
      final url = await ref.read(productServiceProvider).uploadCategoryImage(bytes, ext);
      if (mounted) {
        setState(() {
          _imageUrl.text = url;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).t('upload_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(productServiceProvider);
      final img = _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim();
      if (widget.category == null) {
        await service.createCategory(_name.text.trim(), _icon, imageUrl: img);
      } else {
        await service.updateCategory(
          Category(
            id: widget.category!.id,
            name: _name.text.trim(),
            icon: _icon,
            imageUrl: img,
          ),
        );
      }
      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).t('save_failed_short')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final s = ref.watch(stringsProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.t(isEdit ? 'edit_category' : 'add_category'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                // Live preview of category card
                Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: double.infinity,
                        child: _imageUrl.text.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl.text,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Icon(
                                  lucideIcon(_icon),
                                  color: AppColors.red,
                                ),
                              )
                            : Container(
                                color: AppColors.red.withValues(alpha: 0.08),
                                child: Icon(
                                  lucideIcon(_icon),
                                  color: AppColors.red,
                                  size: 24,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _name.text.isEmpty ? 'Nom de la catégorie' : _name.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? s.t('name_required')
                      : null,
                  decoration: InputDecoration(hintText: s.t('category_name')),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  decoration: InputDecoration(
                    labelText: 'Foto Kategori (Image URL)',
                    hintText: 'https://...',
                    suffixIcon: IconButton(
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.uploadCloud, size: 20),
                      onPressed: _uploading ? null : _pickImage,
                      tooltip: 'Chwazi foto nan galeri',
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _icon,
                  hint: Text(s.t('icon')),
                  items: [
                    for (final name in categoryIconOptions)
                      DropdownMenuItem(
                        value: name,
                        child: Row(
                          children: [
                            Icon(lucideIcon(name), size: 16),
                            const SizedBox(width: 8),
                            Text(name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _icon = v),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: s.t(isEdit ? 'save' : 'create'),
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
