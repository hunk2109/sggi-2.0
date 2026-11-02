import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../memberships/models/promotion_model.dart';
import '../../memberships/services/promotion_service.dart';
import 'create_promotion_dialog.dart';

class CouponsPromotionsTab extends ConsumerStatefulWidget {
  const CouponsPromotionsTab({super.key});

  @override
  ConsumerState<CouponsPromotionsTab> createState() => _CouponsPromotionsTabState();
}

class _CouponsPromotionsTabState extends ConsumerState<CouponsPromotionsTab> {
  final TextEditingController _couponSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _couponSearchCtrl.dispose();
    super.dispose();
  }

  Widget _buildCouponStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCouponCard(PromotionModel promo) {
    final isExpired = promo.expiresAt != null && DateTime.now().isAfter(promo.expiresAt!);
    final isMaxReached = promo.maxUses != null && promo.usesCount >= promo.maxUses!;
    final isValid = promo.active && !isExpired && !isMaxReached;

    Color statusColor = Colors.greenAccent;
    String statusText = 'ACTIVO';
    if (!promo.active) {
      statusColor = Colors.redAccent;
      statusText = 'INACTIVO';
    } else if (isExpired) {
      statusColor = Colors.orangeAccent;
      statusText = 'EXPIRADO';
    } else if (isMaxReached) {
      statusColor = Colors.amberAccent;
      statusText = 'AGOTADO';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.amberAccent.withValues(alpha: 0.25) : AppTheme.darkBorder,
          width: isValid ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_number, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Text(
                          promo.code,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
                    tooltip: 'Copiar código',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: promo.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Código "${promo.code}" copiado al portapapeles.'), duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Text(
                '${promo.discountPercentage}% OFF',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'en membresías',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),

          Text(
            promo.description?.isNotEmpty == true ? promo.description! : 'Sin descripción adicional.',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Divider(height: 12, color: Colors.white12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usos: ${promo.usesCount} / ${promo.maxUses ?? '∞'}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                  Text(
                    promo.expiresAt != null
                        ? 'Vence: ${DateFormat('dd/MM/yyyy').format(promo.expiresAt!)}'
                        : 'Sin vencimiento',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: promo.active,
                      activeThumbColor: Colors.greenAccent,
                      onChanged: (val) {
                        ref.read(promotionsProvider.notifier).toggleActive(promo.id);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.amberAccent),
                    tooltip: 'Editar cupón',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CreatePromotionDialog(promotion: promo),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Eliminar cupón',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E232B),
                          title: const Text('Eliminar Cupón', style: TextStyle(color: Colors.white)),
                          content: Text('¿Está seguro de eliminar el cupón "${promo.code}"?', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(promotionsProvider.notifier).deletePromotion(promo.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(promotionsProvider);
    final allCoupons = promoState.promotions;
    final query = _couponSearchCtrl.text.trim().toLowerCase();

    final filteredCoupons = allCoupons.where((c) {
      if (query.isEmpty) return true;
      final matchCode = c.code.toLowerCase().contains(query);
      final matchDesc = c.description?.toLowerCase().contains(query) ?? false;
      return matchCode || matchDesc;
    }).toList();

    final totalCount = allCoupons.length;
    final activeCount = allCoupons.where((c) => c.isValid).length;
    final totalUses = allCoupons.fold<int>(0, (acc, c) => acc + c.usesCount);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Superior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.discount_outlined, color: Colors.amberAccent, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Gestión de Cupones y Promociones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea códigos de descuento aplicables exclusivamente en el pago y renovación de membresías, o selecciónalos al redactar campañas masivas.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildCouponStatBadge('Total Cupones', '$totalCount', Colors.blueAccent),
                          _buildCouponStatBadge('Vigentes y Activos', '$activeCount', Colors.greenAccent),
                          _buildCouponStatBadge('Canjes Realizados', '$totalUses', Colors.amberAccent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'Crear Nuevo Cupón',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreatePromotionDialog(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Barra de Búsqueda y Filtro
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por código de cupón o descripción...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _couponSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _couponSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.darkCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Refrescar cupones',
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: () => ref.read(promotionsProvider.notifier).loadPromotions(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estado de Carga o Lista de Cupones
          if (promoState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredCoupons.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_outlined, size: 54, color: Colors.white24),
                  const SizedBox(height: 14),
                  Text(
                    allCoupons.isEmpty
                        ? 'No hay cupones creados en el gimnasio'
                        : 'No se encontraron cupones con "$query"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    allCoupons.isEmpty
                        ? 'Crea tu primer cupón para promocionar planes y fidelizar socios.'
                        : 'Intenta con otro término de búsqueda.',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  if (allCoupons.isEmpty) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text('Crear Cupón Ahora', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CreatePromotionDialog(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 200,
                  ),
                  itemCount: filteredCoupons.length,
                  itemBuilder: (context, index) {
                    final promo = filteredCoupons[index];
                    return _buildCouponCard(promo);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

