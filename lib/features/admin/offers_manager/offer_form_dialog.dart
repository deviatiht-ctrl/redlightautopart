import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/product.dart';
import '../../../models/today_offer.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/offers_provider.dart';

class OfferFormDialog extends ConsumerStatefulWidget {
  const OfferFormDialog({super.key, this.offer});

  final TodayOffer? offer;

  @override
  ConsumerState<OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends ConsumerState<OfferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _imageUrl;
  late final TextEditingController _buttonText;

  String? _productId;
  double _alignX = -0.72;
  double _alignY = 0.65;
  String _buttonColor = '#FF5000';
  bool _isActive = true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _title = TextEditingController(text: o?.title ?? '');
    _subtitle = TextEditingController(text: o?.subtitle ?? '');
    _imageUrl = TextEditingController(
      text: o?.imageUrl ?? 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1200&q=80',
    );
    _buttonText = TextEditingController(text: o?.buttonText ?? 'SHOP NOW');
    _productId = o?.productId;
    _alignX = o?.buttonAlignmentX ?? -0.72;
    _alignY = o?.buttonAlignmentY ?? 0.65;
    _buttonColor = o?.buttonColor ?? '#FF5000';
    _isActive = o?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _buttonText.dispose();
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
      final url = await ref.read(offersServiceProvider).uploadBannerImage(bytes, ext);
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

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFFF5000);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final offer = TodayOffer(
        id: widget.offer?.id ?? 'offer-${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        productId: _productId,
        buttonText: _buttonText.text.trim().isEmpty ? 'SHOP NOW' : _buttonText.text.trim(),
        buttonAlignmentX: _alignX,
        buttonAlignmentY: _alignY,
        buttonColor: _buttonColor,
        buttonTextColor: '#FFFFFF',
        isActive: _isActive,
      );

      await ref.read(offersServiceProvider).saveOffer(offer);
      ref.invalidate(adminOffersProvider);
      ref.invalidate(todayOffersProvider);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erè pandan anrejistreman an: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final products = ref.watch(adminProductsProvider).asData?.value ?? const <Product>[];
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: 16,
      ),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.offer == null ? s.t('add_offer') : s.t('edit_offer'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Interactive Flyer Preview
                        const Text(
                          'Aperçu en direct (Bouton repositionnable) :',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2024),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_imageUrl.text.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: _imageUrl.text,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      color: const Color(0xFF2C2D30),
                                      child: const Center(
                                        child: Icon(LucideIcons.image, color: Colors.white54, size: 40),
                                      ),
                                    ),
                                  ),
                                // Dark subtle gradient overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // Text on banner if any
                                Positioned(
                                  left: 18,
                                  top: 20,
                                  right: 120,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_subtitle.text.isNotEmpty)
                                        Text(
                                          _subtitle.text,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (_title.text.isNotEmpty)
                                        Text(
                                          _title.text,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Repositionable Shop Now Button
                                Align(
                                  alignment: Alignment(_alignX, _alignY),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _parseHex(_buttonColor),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _buttonText.text.isEmpty ? 'SHOP NOW' : _buttonText.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Position Controls
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.move, size: 16, color: AppColors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.t('button_position'),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Quick Presets
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    label: Text(s.t('pos_bottom_left')),
                                    selected: (_alignX - -0.72).abs() < 0.1 && (_alignY - 0.65).abs() < 0.1,
                                    onSelected: (_) => setState(() {
                                      _alignX = -0.72;
                                      _alignY = 0.65;
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: Text(s.t('pos_bottom_right')),
                                    selected: (_alignX - 0.72).abs() < 0.1 && (_alignY - 0.65).abs() < 0.1,
                                    onSelected: (_) => setState(() {
                                      _alignX = 0.72;
                                      _alignY = 0.65;
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: Text(s.t('pos_center')),
                                    selected: _alignX.abs() < 0.1 && _alignY.abs() < 0.1,
                                    onSelected: (_) => setState(() {
                                      _alignX = 0.0;
                                      _alignY = 0.0;
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Centre Gauche'),
                                    selected: (_alignX - -0.72).abs() < 0.1 && _alignY.abs() < 0.1,
                                    onSelected: (_) => setState(() {
                                      _alignX = -0.72;
                                      _alignY = 0.0;
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Slider X
                              if (isMobile) ...[
                                Text(
                                  '${s.t('position_x')} (${_alignX.toStringAsFixed(2)}) :',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Slider(
                                  value: _alignX,
                                  min: -0.9,
                                  max: 0.9,
                                  divisions: 36,
                                  activeColor: AppColors.red,
                                  onChanged: (v) => setState(() => _alignX = v),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        '${s.t('position_x')} (${_alignX.toStringAsFixed(2)}) :',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _alignX,
                                        min: -0.9,
                                        max: 0.9,
                                        divisions: 36,
                                        activeColor: AppColors.red,
                                        onChanged: (v) => setState(() => _alignX = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Slider Y
                              if (isMobile) ...[
                                Text(
                                  '${s.t('position_y')} (${_alignY.toStringAsFixed(2)}) :',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Slider(
                                  value: _alignY,
                                  min: -0.9,
                                  max: 0.9,
                                  divisions: 36,
                                  activeColor: AppColors.red,
                                  onChanged: (v) => setState(() => _alignY = v),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        '${s.t('position_y')} (${_alignY.toStringAsFixed(2)}) :',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _alignY,
                                        min: -0.9,
                                        max: 0.9,
                                        divisions: 36,
                                        activeColor: AppColors.red,
                                        onChanged: (v) => setState(() => _alignY = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Flyer Image URL + Upload
                        TextFormField(
                          controller: _imageUrl,
                          decoration: InputDecoration(
                            labelText: s.t('flyer_image'),
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
                              tooltip: 'Téléverser une image',
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'URL obligatwa' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Title & Subtitle (Optionnels sur le design)
                        if (isMobile) ...[
                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(
                              labelText: 'Titre de l\'offre',
                              hintText: 'ex: Get your tyres winter-ready',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _subtitle,
                            decoration: const InputDecoration(
                              labelText: 'Sous-titre / accroche',
                              hintText: 'ex: Freeze warning ahead',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _title,
                                  decoration: const InputDecoration(
                                    labelText: 'Titre de l\'offre',
                                    hintText: 'ex: Get your tyres winter-ready',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _subtitle,
                                  decoration: const InputDecoration(
                                    labelText: 'Sous-titre / accroche',
                                    hintText: 'ex: Freeze warning ahead',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Button Label & Color
                        if (isMobile) ...[
                          TextFormField(
                            controller: _buttonText,
                            decoration: InputDecoration(
                              labelText: s.t('button_text'),
                              hintText: 'SHOP NOW',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _buttonColor,
                            decoration: const InputDecoration(labelText: 'Couleur bouton'),
                            items: const [
                              DropdownMenuItem(value: '#FF5000', child: Text('Orange Autodoc')),
                              DropdownMenuItem(value: '#E10600', child: Text('Rouge Redlight')),
                              DropdownMenuItem(value: '#2563EB', child: Text('Bleu')),
                              DropdownMenuItem(value: '#10B981', child: Text('Vert')),
                              DropdownMenuItem(value: '#111827', child: Text('Noir')),
                            ],
                            onChanged: (v) => setState(() => _buttonColor = v ?? '#FF5000'),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _buttonText,
                                  decoration: InputDecoration(
                                    labelText: s.t('button_text'),
                                    hintText: 'SHOP NOW',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _buttonColor,
                                  decoration: const InputDecoration(labelText: 'Couleur bouton'),
                                  items: const [
                                    DropdownMenuItem(value: '#FF5000', child: Text('Orange Autodoc')),
                                    DropdownMenuItem(value: '#E10600', child: Text('Rouge Redlight')),
                                    DropdownMenuItem(value: '#2563EB', child: Text('Bleu')),
                                    DropdownMenuItem(value: '#10B981', child: Text('Vert')),
                                    DropdownMenuItem(value: '#111827', child: Text('Noir')),
                                  ],
                                  onChanged: (v) => setState(() => _buttonColor = v ?? '#FF5000'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Product Redirect Selector
                        DropdownButtonFormField<String>(
                          initialValue: _productId,
                          decoration: InputDecoration(
                            labelText: s.t('target_product'),
                            hintText: 'Choisir le produit vers lequel rediriger',
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Aucun produit (Lien général)')),
                            ...products.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.name} (${p.price.toStringAsFixed(0)} HTG)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _productId = v),
                        ),
                        const SizedBox(height: 12),

                        // Active switch
                        SwitchListTile(
                          title: Text(s.t('active')),
                          subtitle: Text(_isActive ? 'L\'offre sera visible sur la page d\'accueil' : 'Offre masquée'),
                          value: _isActive,
                          activeThumbColor: AppColors.red,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(s.t('cancel')),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      label: s.t('save'),
                      loading: _saving,
                      expanded: false,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
