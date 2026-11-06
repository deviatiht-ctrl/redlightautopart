import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/app_order.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/orders_provider.dart';

/// Dyalòg admin pou jere swivi yon kòmand:
/// pozisyon (tèks + kat OSM), ETA (dat/lè), anprevu, istorik,
/// ak bèl bouton kote souvan itilize an Ayiti.
class TrackingEditorDialog extends ConsumerStatefulWidget {
  const TrackingEditorDialog({super.key, required this.order});

  final AppOrder order;

  /// Sant defo kat la: Pòtoprens, Ayiti.
  static const _defaultCenter = LatLng(18.5392, -72.3350);

  static Future<void> open(BuildContext context, AppOrder order) {
    return showDialog(
      context: context,
      builder: (_) => TrackingEditorDialog(order: order),
    );
  }

  @override
  ConsumerState<TrackingEditorDialog> createState() =>
      _TrackingEditorDialogState();
}

class _TrackingEditorDialogState extends ConsumerState<TrackingEditorDialog> {
  final _locationCtrl = TextEditingController();
  final _delayCtrl = TextEditingController();
  LatLng? _position;
  DateTime? _eta;
  bool _logCheckpoint = true;
  bool _saving = false;
  bool _initialized = false;
  String? _initialDelay;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _delayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEta() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eta ?? now.add(const Duration(hours: 4)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eta ?? now),
    );
    setState(() {
      _eta = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  void _applyPreset(String text, LatLng? pos) {
    setState(() {
      _locationCtrl.text = text;
      if (pos != null) {
        _position = pos;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = ref.read(stringsProvider);
    try {
      final svc = ref.read(orderServiceProvider);
      final delay = _delayCtrl.text.trim();
      final location = _locationCtrl.text.trim();

      // Mete ajou swivi
      await svc.upsertTracking(
        widget.order.id,
        location: location,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        etaAt: _eta,
        delayNote: delay,
      );

      // Mete ajou estati si li chanje
      if (_currentStatus != widget.order.status) {
        await svc.updateStatus(widget.order.id, _currentStatus);
      }

      if (_logCheckpoint && (location.isNotEmpty || _position != null)) {
        await svc.addTrackingEvent(
          widget.order.id,
          location: location,
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        );
      }

      if (delay.isNotEmpty && delay != _initialDelay) {
        await svc.addTrackingEvent(
          widget.order.id,
          kind: 'delay',
          note: delay,
        );
      }

      ref.invalidate(orderTrackingProvider(widget.order.id));
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('tracking_saved'))),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('tracking_save_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final info = ref.watch(orderTrackingProvider(widget.order.id));

    info.whenData((data) {
      if (_initialized) return;
      _initialized = true;
      final t = data.tracking;
      if (t != null) {
        _locationCtrl.text = t.location ?? '';
        _delayCtrl.text = t.delayNote ?? '';
        _initialDelay = t.delayNote;
        if (t.hasPosition) _position = LatLng(t.latitude!, t.longitude!);
        _eta = t.etaAt;
      }
    });

    final presets = [
      (s.t('preset_pap'), const LatLng(18.5392, -72.3350)),
      (s.t('preset_delmas'), const LatLng(18.5480, -72.3020)),
      (s.t('preset_petionville'), const LatLng(18.5125, -72.2853)),
      (s.t('preset_cap'), const LatLng(19.7595, -72.2042)),
      (s.t('preset_saint_marc'), const LatLng(19.1082, -72.6938)),
      (s.t('preset_gonaives'), const LatLng(19.4500, -72.6833)),
      (s.t('preset_out_delivery'), null),
      (s.t('preset_delivered'), null),
    ];

    // Tranzisyon estati valab pou admin
    final nextPossibleStatuses = switch (widget.order.status) {
      'confirmed' when widget.order.paymentStatus == 'paid' => [
          widget.order.status,
          'shipped'
        ],
      'shipped' when widget.order.paymentStatus == 'paid' => [
          widget.order.status,
          'delivered'
        ],
      _ => [widget.order.status],
    };

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.truck, size: 22, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.t('tracking_dialog_title', {
                        'id': widget.order.id.substring(0, 8).toUpperCase(),
                      }),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chanje estati kòmand la dirèkteman
                      if (nextPossibleStatuses.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                s.t('change_status_now'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: _currentStatus,
                                isDense: true,
                                items: [
                                  for (final st in nextPossibleStatuses)
                                    DropdownMenuItem(
                                      value: st,
                                      child: Text(
                                        orderStatusLabel(s, st),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.orderStatusColor(st),
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _currentStatus = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Presets kote rapid an Ayiti
                      Text(
                        s.t('quick_presets'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in presets)
                            ActionChip(
                              label: Text(p.$1,
                                  style: const TextStyle(fontSize: 11)),
                              avatar: const Icon(LucideIcons.mapPin, size: 12),
                              onPressed: () => _applyPreset(p.$1, p.$2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _locationCtrl,
                        decoration: InputDecoration(
                          labelText: s.t('tracking_location_field'),
                          hintText: s.t('tracking_location_hint'),
                          prefixIcon: const Icon(LucideIcons.mapPin),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _position ??
                                  TrackingEditorDialog._defaultCenter,
                              initialZoom: _position == null ? 9 : 13,
                              onTap: (_, point) =>
                                  setState(() => _position = point),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.cvisual.redlight_autoparts',
                              ),
                              if (_position != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _position!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        LucideIcons.package,
                                        color: AppColors.red,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _position == null
                                  ? s.t('tap_map_hint')
                                  : '${_position!.latitude.toStringAsFixed(4)}, '
                                      '${_position!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMutedLight,
                              ),
                            ),
                          ),
                          if (_position != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _position = null),
                              child: Text(s.t('clear_position')),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _eta == null
                                  ? s.t('tracking_no_eta')
                                  : '${s.t('tracking_eta')}: ${formatDate(_eta)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickEta,
                            icon: const Icon(LucideIcons.calendar, size: 15),
                            label: Text(s.t('tracking_pick_eta')),
                          ),
                          if (_eta != null)
                            IconButton(
                              tooltip: s.t('clear'),
                              icon: const Icon(LucideIcons.x, size: 15),
                              onPressed: () => setState(() => _eta = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _delayCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: s.t('tracking_delay_field'),
                          hintText: s.t('tracking_delay_hint'),
                          prefixIcon: const Icon(LucideIcons.alertTriangle),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      CheckboxListTile(
                        value: _logCheckpoint,
                        onChanged: (v) =>
                            setState(() => _logCheckpoint = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          s.t('tracking_log_checkpoint'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(s.t('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.save, size: 16),
                    label: Text(s.t('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
