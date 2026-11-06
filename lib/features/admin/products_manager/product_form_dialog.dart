import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/icon_mapper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/locale_provider.dart';

/// Fòm kreye/modifye pwodwi — ekri dirèkteman nan Supabase.
class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _models;

  String? _categoryId;
  late List<String> _images;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p == null ? '' : p.price.toStringAsFixed(0),
    );
    _stock = TextEditingController(text: '${p?.stock ?? 0}');
    _models = TextEditingController(
      text: p?.compatibleModels.join(', ') ?? '',
    );
    _categoryId = p?.categoryId;
    _images = [...p?.images ?? const []];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _models.dispose();
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
      final ext = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpeg';
      final url = await ref
          .read(productServiceProvider)
          .uploadProductImage(bytes, ext);
      if (mounted) setState(() => _images.add(url));
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

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'is_demo': false,
      'category_id': _categoryId,
      'compatible_models': _models.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'images': _images,
    };

    try {
      final service = ref.read(productServiceProvider);
      if (widget.product == null) {
        await service.createProduct(payload);
      } else {
        await service.updateProduct(widget.product!.id, payload);
      }
      ref.invalidate(adminProductsProvider);
      ref.invalidate(filteredProductsProvider);
      ref.invalidate(popularProductsProvider);
      ref.invalidate(newProductsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).t('save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final isEdit = widget.product != null;
    final s = ref.watch(stringsProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.t(isEdit ? 'edit_product' : 'add_product'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? s.t('name_required')
                          : null,
                  decoration: InputDecoration(hintText: s.t('product_name')),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: s.t('description')),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (double.tryParse(v ?? '') == null)
                            ? s.t('invalid_price')
                            : null,
                        decoration: InputDecoration(hintText: s.t('price_htg')),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: s.t('stock')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                categories.maybeWhen(
                  data: (cats) => DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    hint: Text(s.t('category')),
                    items: [
                      for (final Category c in cats)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(lucideIcon(c.icon), size: 16),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  orElse: () => const ShimmerBox(height: 52),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _models,
                  decoration: InputDecoration(hintText: s.t('models_hint')),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.t('images'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickImage,
                      icon: const Icon(LucideIcons.imagePlus, size: 18),
                      label: Text(
                        s.t(_uploading ? 'uploading' : 'add_image'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_images.isNotEmpty)
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _images[i],
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 84,
                                height: 84,
                                color: AppColors.surfaceLight,
                                child: const Icon(
                                  LucideIcons.wrench,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _images.removeAt(i)),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 12,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      s.t('no_images'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: s.t(isEdit ? 'save' : 'create_product'),
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
