import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../../memberships/services/promotion_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/campaigns_provider.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _campaignNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _couponController = TextEditingController();
  final _memberSearchController = TextEditingController();
  final _dateOnly = DateFormat('dd/MM/yyyy');

  bool _isMemberListExpanded = false;
  String _previewChannel = 'WHATSAPP'; // 'WHATSAPP' or 'EMAIL'
  MemberModel? _samplePreviewMember;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(campaignsProvider.notifier).init();
      ref.read(membersProvider.notifier).loadMembers();
      ref.read(whatsappProvider.notifier).checkStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _campaignNameController.dispose();
    _messageController.dispose();
    _couponController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  List<MemberModel> _getTargetMembers(String audience, List<MemberModel> allMembers, Set<String> customIds) {
    switch (audience) {
      case 'ALL':
        return allMembers;
      case 'ACTIVE':
        return allMembers.where((m) => m.hasMembership && !m.isExpired && !m.isSuspended).toList();
      case 'INACTIVE':
        return allMembers.where((m) => !m.hasMembership || m.isExpired).toList();
      case 'EXPIRING_SOON':
        return allMembers.where((m) {
          if (!m.hasMembership || m.isExpired || m.membershipEndDate == null) return false;
          final diff = m.membershipEndDate!.difference(DateTime.now()).inDays;
          return diff >= 0 && diff <= 7;
        }).toList();
      case 'PENDING_PAYMENT':
        return allMembers.where((m) => m.hasPendingPayment).toList();
      case 'CUSTOM':
        return allMembers.where((m) => customIds.contains(m.id)).toList();
      default:
        return allMembers;
    }
  }

  void _insertVariable(String variable) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, variable);
      _messageController.text = newText;
      _messageController.selection = TextSelection.collapsed(offset: selection.start + variable.length);
    } else {
      _messageController.text = text + variable;
      _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
    }
    ref.read(campaignsProvider.notifier).setMessageText(_messageController.text);
    setState(() {});
  }

  String _generatePreviewText(String template, MemberModel? member) {
    if (template.isEmpty) return 'Escribe tu mensaje para ver la vista previa...';
    const gymName = 'Gimnasio';
    final firstName = member?.firstName ?? 'Carlos';
    final lastName = member?.lastName ?? 'Gómez';
    final fullName = member?.fullName ?? '$firstName $lastName';
    final phone = member?.phone ?? '809-555-0199';
    final email = member?.email ?? 'carlos.gomez@gmail.com';
    final plan = member?.activePlanName ?? 'Plan Mensual VIP';
    final endDate = member?.membershipEndDate != null
        ? _dateOnly.format(member!.membershipEndDate!)
        : '28/10/2026';

    var res = template
        .replaceAll('{nombre}', firstName)
        .replaceAll('{apellido}', lastName)
        .replaceAll('{nombre_completo}', fullName)
        .replaceAll('{gimnasio}', gymName)
        .replaceAll('{plan}', plan)
        .replaceAll('{fecha_vencimiento}', endDate)
        .replaceAll('{telefono}', phone)
        .replaceAll('{email}', email);

    final coupon = _couponController.text.trim();
    if (coupon.isNotEmpty) {
      res = res.replaceAll('{cupon}', coupon);
      if (!template.contains('{cupon}')) {
        res += '\n\n🏷️ *Cupón promocional:* $coupon (Aplicable en renovación de membresía)';
      }
    } else {
      res = res.replaceAll('{cupon}', '[CUPÓN]');
    }

    return res;
  }

  Future<void> _handleStartCampaign(List<MemberModel> targetMembers) async {
    final state = ref.read(campaignsProvider);
    final campaignName = _campaignNameController.text.trim().isEmpty
        ? 'Campaña Difusión ${DateFormat('dd/MM HH:mm').format(DateTime.now())}'
        : _campaignNameController.text.trim();
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el contenido del mensaje antes de enviar.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (targetMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay ningún socio seleccionado para esta audiencia.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.amberAccent, size: 24),
            SizedBox(width: 10),
            Text('Confirmar Envío Masivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro de iniciar el envío de la campaña "$campaignName"?',
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Audiencia:', state.selectedAudience == 'CUSTOM' ? 'Selección Manual' : state.selectedAudience),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Canal:', state.selectedChannel),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Total Destinatarios:', '${targetMembers.length} socios'),
                    if (_couponController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildSummaryRow('Cupón Adjunto:', _couponController.text.trim().toUpperCase()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.white54),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El envío se procesará en segundo plano con intervalos seguros para no saturar las conexiones.',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text('Iniciar Envío', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iniciando campaña "$campaignName" para ${targetMembers.length} socios...'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      final customIds = state.selectedAudience == 'CUSTOM'
          ? targetMembers.map((m) => m.id).toList()
          : null;

      final res = await ref.read(campaignsProvider.notifier).sendCampaign(
        name: campaignName,
        audience: state.selectedAudience,
        channel: state.selectedChannel,
        messageTemplate: message,
        couponCode: _couponController.text.trim().isNotEmpty ? _couponController.text.trim() : null,
        customMemberIds: customIds,
      );

      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? (success ? 'Envío completado exitosamente' : 'Error en el envío')),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
        if (success) {
          _tabController.animateTo(1);
        }
      }
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wpState = ref.watch(whatsappProvider);
    final isWpConnected = wpState.status?.status == 'CONNECTED';

    return Scaffold(
      backgroundColor: const Color(0xFF12151B),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign_outlined, color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Envíos Masivos & Difusión',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Comunícate con tus socios vía WhatsApp y Correo con plantillas inteligentes y segmentación.',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),

                // WhatsApp Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isWpConnected ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isWpConnected ? Colors.green.withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isWpConnected ? Colors.greenAccent : Colors.amberAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isWpConnected ? 'WhatsApp Conectado' : 'WhatsApp Desconectado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isWpConnected ? Colors.greenAccent : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E232B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(icon: Icon(Icons.send_outlined, size: 16), text: 'Nueva Campaña'),
                      Tab(icon: Icon(Icons.history_outlined, size: 16), text: 'Historial de Envíos'),
                      Tab(icon: Icon(Icons.auto_stories_outlined, size: 16), text: 'Galería de Plantillas'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewCampaignTab(),
                _buildHistoryTab(),
                _buildTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: NUEVA CAMPAÑA
  // ==========================================
  Widget _buildNewCampaignTab() {
    final state = ref.watch(campaignsProvider);
    final membersState = ref.watch(membersProvider);
    final allMembers = state.recipients.isNotEmpty ? state.recipients : membersState.members;
    final targetMembers = _getTargetMembers(state.selectedAudience, allMembers, state.selectedMemberIds);

    if (_samplePreviewMember == null && targetMembers.isNotEmpty) {
      _samplePreviewMember = targetMembers.first;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANEL: CONFIGURACIÓN
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(Icons.groups_outlined, '1. Destinatarios y Audiencia'),
                    if (state.isLoadingRecipients)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.white60),
                        tooltip: 'Recargar socios',
                        onPressed: () => ref.read(campaignsProvider.notifier).loadRecipients(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Audience Choice Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAudienceChip('ALL', 'Todos (${allMembers.length})', Icons.public, state.selectedAudience),
                    _buildAudienceChip('ACTIVE', 'Socios Activos (${allMembers.where((m) => m.hasMembership && !m.isExpired).length})', Icons.check_circle_outline, state.selectedAudience),
                    _buildAudienceChip('INACTIVE', 'Inactivos / Vencidos (${allMembers.where((m) => !m.hasMembership || m.isExpired).length})', Icons.highlight_off, state.selectedAudience),
                    _buildAudienceChip('EXPIRING_SOON', 'Vencen en 7 Días', Icons.timelapse_outlined, state.selectedAudience),
                    _buildAudienceChip('PENDING_PAYMENT', 'Con Cuotas Pendientes', Icons.payment_outlined, state.selectedAudience),
                    _buildAudienceChip('CUSTOM', 'Selección Manual (${state.selectedMemberIds.length})', Icons.checklist_outlined, state.selectedAudience),
                  ],
                ),
                const SizedBox(height: 14),

                // Contador y Botón para desplegar lista de socios
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2028),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt, size: 18, color: Colors.amberAccent),
                      const SizedBox(width: 8),
                      Text(
                        '${targetMembers.length} socios seleccionados',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: Icon(_isMemberListExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
                        label: Text(_isMemberListExpanded ? 'Ocultar Lista' : 'Ver / Seleccionar Socios', style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _isMemberListExpanded = !_isMemberListExpanded),
                      ),
                    ],
                  ),
                ),

                if (_isMemberListExpanded) ...[
                  const SizedBox(height: 10),
                  _buildMemberListSelector(allMembers, state),
                ],

                const SizedBox(height: 24),

                // SECCIÓN 2: CANAL DE ENVÍO
                _buildSectionHeader(Icons.cell_tower, '2. Canal de Comunicación'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildChannelButton('WHATSAPP', 'WhatsApp', Icons.chat, Colors.greenAccent, state.selectedChannel),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildChannelButton('EMAIL', 'Correo Electrónico', Icons.email_outlined, Colors.blueAccent, state.selectedChannel),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildChannelButton('BOTH', 'Ambos Canales', Icons.all_inclusive, Colors.purpleAccent, state.selectedChannel),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECCIÓN 3: PLANTILLAS RÁPIDAS
                _buildSectionHeader(Icons.auto_stories_outlined, '3. Plantilla Predefinida'),
                const SizedBox(height: 10),
                if (state.templates.isNotEmpty) ...[
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.templates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final t = state.templates[index];
                        final isSelected = state.selectedTemplate?.id == t.id;
                        return ChoiceChip(
                          label: Text(t.name),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: const Color(0xFF1E232B),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          onSelected: (val) {
                            if (val) {
                              ref.read(campaignsProvider.notifier).applyTemplate(t);
                              _messageController.text = t.message;
                              _campaignNameController.text = t.name;
                              setState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // SECCIÓN 4: REDACCIÓN DEL MENSAJE
                _buildSectionHeader(Icons.edit_note, '4. Contenido del Mensaje'),
                const SizedBox(height: 10),

                TextField(
                  controller: _campaignNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Campaña / Asunto de Correo *',
                    hintText: 'Ej. Recordatorio de Cuota Vencida - Octubre',
                    prefixIcon: Icon(Icons.title, size: 18),
                  ),
                  onChanged: (val) => ref.read(campaignsProvider.notifier).setCampaignName(val),
                ),
                const SizedBox(height: 12),

                const Text(
                  'VARIABLES DINÁMICAS (Haz clic para insertar en el texto):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildVariablePill('{nombre}', 'Nombre'),
                    _buildVariablePill('{apellido}', 'Apellido'),
                    _buildVariablePill('{nombre_completo}', 'Nombre Completo'),
                    _buildVariablePill('{gimnasio}', 'Gimnasio'),
                    _buildVariablePill('{plan}', 'Plan/Membresía'),
                    _buildVariablePill('{fecha_vencimiento}', 'Fecha Vencimiento'),
                    _buildVariablePill('{telefono}', 'Teléfono'),
                    _buildVariablePill('{email}', 'Correo'),
                    _buildVariablePill('{cupon}', 'Cupón Promocional'),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _messageController,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: 'Escribe el mensaje aquí. Puedes usar emojis y formato de WhatsApp (*negrita*, _cursiva_)...',
                    filled: true,
                    fillColor: const Color(0xFF1E232B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (val) {
                    ref.read(campaignsProvider.notifier).setMessageText(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),

                // SECCIÓN CUPÓN O PROMOCIÓN VIGENTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.amberAccent),
                        SizedBox(width: 6),
                        Text(
                          'Cupón o Promoción Especial (Opcional):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                    if (_couponController.text.trim().isNotEmpty)
                      InkWell(
                        onTap: () {
                          _couponController.clear();
                          setState(() {});
                        },
                        child: const Text('Limpiar cupón', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Chips de promociones activas registradas en el backend
                ref.watch(activePromotionsProvider).when(
                  data: (promos) {
                    if (promos.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: promos.map((p) {
                          final isSelected = _couponController.text.trim().toUpperCase() == p.code;
                          return FilterChip(
                            selected: isSelected,
                            avatar: Icon(
                              Icons.discount_outlined,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.amberAccent,
                            ),
                            label: Text(
                              '${p.code} (-${p.discountPercentage}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.amberAccent,
                              ),
                            ),
                            selectedColor: AppTheme.primary,
                            backgroundColor: const Color(0xFF1E232B),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primary : Colors.amberAccent.withValues(alpha: 0.3),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _couponController.text = p.code;
                                } else {
                                  _couponController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código del Cupón Promocional',
                    hintText: 'Ej. PROMO10, VERANO20...',
                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                    suffixIcon: _couponController.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _couponController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (_couponController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cupón activo para envío: "${_couponController.text.trim().toUpperCase()}". '
                            'Los socios podrán canjearlo al pagar su membresía en recepción.',
                            style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                          ),
                        ),
                        if (!_messageController.text.contains('{cupon}')) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              backgroundColor: Colors.amber.withValues(alpha: 0.15),
                            ),
                            icon: const Icon(Icons.add, size: 12, color: Colors.amberAccent),
                            label: const Text('Insertar en texto', style: TextStyle(fontSize: 10, color: Colors.amberAccent)),
                            onPressed: () => _insertVariable(' {cupon} '),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // RIGHT PANEL: VISTA PREVIA
        Container(
          width: 440,
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        'Vista Previa en Vivo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat, size: 18, color: _previewChannel == 'WHATSAPP' ? Colors.greenAccent : Colors.white38),
                        tooltip: 'Vista WhatsApp',
                        onPressed: () => setState(() => _previewChannel = 'WHATSAPP'),
                      ),
                      IconButton(
                        icon: Icon(Icons.email, size: 18, color: _previewChannel == 'EMAIL' ? Colors.blueAccent : Colors.white38),
                        tooltip: 'Vista Correo',
                        onPressed: () => setState(() => _previewChannel = 'EMAIL'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (targetMembers.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final previewList = <MemberModel>[];
                    final seenIds = <String>{};
                    for (final m in targetMembers) {
                      if (m.id.isNotEmpty && seenIds.add(m.id)) {
                        previewList.add(m);
                        if (previewList.length >= 20) break;
                      }
                    }

                    final selectedId = (_samplePreviewMember != null && previewList.any((m) => m.id == _samplePreviewMember!.id))
                        ? _samplePreviewMember!.id
                        : (previewList.isNotEmpty ? previewList.first.id : null);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E232B),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          items: previewList.map((m) {
                            return DropdownMenuItem<String>(
                              value: m.id,
                              child: Text('Simular con: ${m.fullName}', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final found = previewList.firstWhere((m) => m.id == val, orElse: () => previewList.first);
                              setState(() => _samplePreviewMember = found);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              Expanded(
                child: _previewChannel == 'WHATSAPP'
                    ? _buildWhatsAppPreview(targetMembers)
                    : _buildEmailPreview(targetMembers),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.rocket_launch, size: 20, color: Colors.white),
                label: Text(
                  'Iniciar Envío (${targetMembers.length} Socios)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () => _handleStartCampaign(targetMembers),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildAudienceChip(String id, String label, IconData icon, String selected) {
    final isSelected = selected == id;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFF1E232B),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      onSelected: (_) => ref.read(campaignsProvider.notifier).setAudience(id),
    );
  }

  Widget _buildChannelButton(String id, String label, IconData icon, Color color, String selected) {
    final isSelected = selected == id;
    return InkWell(
      onTap: () => ref.read(campaignsProvider.notifier).setChannel(id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.white60),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariablePill(String varCode, String label) {
    return InkWell(
      onTap: () => _insertVariable(varCode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Colors.amberAccent),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberListSelector(List<MemberModel> allMembers, CampaignsState state) {
    final query = _memberSearchController.text.trim().toLowerCase();
    final filtered = allMembers.where((m) {
      if (query.isEmpty) return true;
      final matchName = m.fullName.toLowerCase().contains(query);
      final matchPhone = m.phone?.toLowerCase().contains(query) ?? false;
      final matchEmail = m.email?.toLowerCase().contains(query) ?? false;
      return matchName || matchPhone || matchEmail;
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF181C24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Filtrar por nombre, cédula o teléfono...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final allIds = filtered.map((m) => m.id).toList();
                    ref.read(campaignsProvider.notifier).selectAllMembers(allIds);
                  },
                  child: const Text('Todos', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => ref.read(campaignsProvider.notifier).clearMemberSelection(),
                  child: const Text('Ninguno', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final m = filtered[index];
                final isSelected = state.selectedMemberIds.contains(m.id);
                return CheckboxListTile(
                  value: isSelected,
                  dense: true,
                  activeColor: AppTheme.primary,
                  title: Text(m.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${m.phone ?? 'Sin teléfono'}  •  ${m.activePlanName ?? 'Sin Plan'}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  secondary: CircleAvatar(
                    radius: 14,
                    backgroundColor: m.hasMembership && !m.isExpired ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    child: Text(
                      m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: m.hasMembership && !m.isExpired ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ),
                  onChanged: (_) => ref.read(campaignsProvider.notifier).toggleMember(m.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppPreview(List<MemberModel> targetMembers) {
    final previewText = _generatePreviewText(_messageController.text, _samplePreviewMember);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B141A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF00A884),
                  child: Icon(Icons.fitness_center, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gimnasio (Mensaje Oficial)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Para: ${_samplePreviewMember?.fullName ?? 'Destinatario'}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, size: 16, color: Colors.white54),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF005C4B),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      previewText,
                      style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(DateTime.now()),
                          style: const TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 14, color: Color(0xFF53BDEB)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPreview(List<MemberModel> targetMembers) {
    final previewText = _generatePreviewText(_messageController.text, _samplePreviewMember);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _campaignNameController.text.trim().isEmpty ? 'Asunto de Correo...' : _campaignNameController.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'GIMNASIO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    previewText,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Este es un mensaje institucional automático.',
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: HISTORIAL DE ENVÍOS
  // ==========================================
  Widget _buildHistoryTab() {
    final state = ref.watch(campaignsProvider);
    final campaigns = state.campaigns;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 54, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            const Text(
              'Aún no hay campañas de mensajería registradas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            const Text(
              'Las campañas que envíes por WhatsApp o Correo aparecerán aquí.',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ListView.separated(
          itemCount: campaigns.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          itemBuilder: (context, index) {
            final c = campaigns[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: c.channel == 'WHATSAPP'
                    ? Colors.green.withValues(alpha: 0.15)
                    : (c.channel == 'EMAIL' ? Colors.blue.withValues(alpha: 0.15) : Colors.purple.withValues(alpha: 0.15)),
                child: Icon(
                  c.channel == 'WHATSAPP' ? Icons.chat : (c.channel == 'EMAIL' ? Icons.email : Icons.all_inclusive),
                  size: 18,
                  color: c.channel == 'WHATSAPP' ? Colors.greenAccent : (c.channel == 'EMAIL' ? Colors.blueAccent : Colors.purpleAccent),
                ),
              ),
              title: Row(
                children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222731),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(c.audienceLabel, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
                ],
              ),
              subtitle: Text(
                'Fecha: ${_dateOnly.format(c.createdAt)}  •  Destinatarios: ${c.recipientsCount} (${c.successfulSends} exitosos, ${c.failedSends} fallidos)',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Eliminar registro',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref.read(campaignsProvider.notifier).deleteCampaign(c.id);
                  if (ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Campaña eliminada del historial')),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: GALERÍA DE PLANTILLAS
  // ==========================================
  Widget _buildTemplatesTab() {
    final state = ref.watch(campaignsProvider);
    final templates = state.templates;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.35,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.category,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                      ),
                    ),
                    const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222731),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 14, color: Colors.amberAccent),
                  label: const Text('Usar Esta Plantilla', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ref.read(campaignsProvider.notifier).applyTemplate(t);
                    _messageController.text = t.message;
                    _campaignNameController.text = t.name;
                    _tabController.animateTo(0);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
