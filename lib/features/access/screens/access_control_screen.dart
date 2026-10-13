import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../providers/access_provider.dart';

class AccessControlScreen extends ConsumerStatefulWidget {
  const AccessControlScreen({super.key});

  @override
  ConsumerState<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends ConsumerState<AccessControlScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  final _timeFormat = DateFormat('hh:mm:ss a');

  @override
  void initState() {
    super.initState();
    // Auto-focus barcode scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    _codeController.clear();
    await ref.read(accessProvider.notifier).scanCode(code);
    _focusNode.requestFocus();
  }

  Future<void> _openManualMemberSelect() async {
    final searchCtrl = TextEditingController();
    List<MemberModel> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E232B),
            title: const Row(
              children: [
                Icon(Icons.person_search, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('Buscar Socio para Acceso Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Escriba nombre o cédula...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) async {
                      if (val.trim().length >= 2) {
                        setDialogState(() => isSearching = true);
                        final s = ref.read(memberServiceProvider);
                        final res = await s.searchMembers(val.trim());
                        setDialogState(() {
                          searchResults = res;
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : searchResults.isEmpty
                            ? const Center(child: Text('Ingrese al menos 2 caracteres para buscar', style: TextStyle(color: Colors.white38)))
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final m = searchResults[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                      child: Text(m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : 'S', style: const TextStyle(color: AppTheme.primary)),
                                    ),
                                    title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('Código: ${m.displayCode} | Plan: ${m.activePlanName ?? "Ninguno"}', style: const TextStyle(fontSize: 11)),
                                    trailing: ElevatedButton(
                                      child: const Text('Registrar Acceso'),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        ref.read(accessProvider.notifier).scanById(m.id);
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accessProvider);
    final notifier = ref.read(accessProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Stats
          Row(
            children: [
              _buildStatChip(
                icon: Icons.people_outline,
                label: 'Total Accesos Hoy',
                value: state.totalToday.toString(),
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label: 'Autorizados',
                value: state.authorizedCount.toString(),
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.highlight_off,
                label: 'Rechazados / Alertas',
                value: state.rejectedCount.toString(),
                color: Colors.redAccent,
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('Acceso Manual (Nombre)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF232936),
                  foregroundColor: Colors.white,
                ),
                onPressed: _openManualMemberSelect,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar asistencias',
                onPressed: () => notifier.loadRecentAttendances(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Screen: Left Scanner Panel (380px) & Right History Table (Expanded)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT PANEL: Scan Terminal & Visual Access Feedback
                SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      // Terminal Input Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.qr_code_scanner, color: AppTheme.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Escanear Carnet / Código',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _codeController,
                              focusNode: _focusNode,
                              autofocus: true,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              decoration: InputDecoration(
                                hintText: 'Ej. 1002 (Presione Enter)',
                                hintStyle: const TextStyle(fontSize: 13, letterSpacing: 0, fontWeight: FontWeight.normal),
                                prefixIcon: const Icon(Icons.barcode_reader, size: 22),
                                suffixIcon: state.isProcessingScan
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: _handleScan,
                                      ),
                              ),
                              onSubmitted: (_) => _handleScan(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Live Access Feedback Monitor
                      Expanded(
                        child: _buildLiveFeedbackCard(state),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // RIGHT PANEL: Attendance Activity Log Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Registro en Vivo de Molinetes / Puerta',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip('all', 'Todos', state.filter, (f) => notifier.setFilter(f)),
                                _buildFilterChip('authorized', 'Autorizados', state.filter, (f) => notifier.setFilter(f)),
                                _buildFilterChip('rejected', 'Rechazados', state.filter, (f) => notifier.setFilter(f)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Table
                        Expanded(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : state.filteredAttendances.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.access_time, size: 48, color: Colors.white24),
                                          SizedBox(height: 12),
                                          Text('Sin registros de asistencia para mostrar', style: TextStyle(color: Colors.white54)),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          headingRowHeight: 42,
                                          dataRowMinHeight: 46,
                                          dataRowMaxHeight: 46,
                                          columns: const [
                                            DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Dispositivo / Punto', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Detalle / Motivo', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: state.filteredAttendances.map((att) {
                                            return DataRow(
                                              cells: [
                                                DataCell(Text(_timeFormat.format(att.visitDate), style: const TextStyle(fontSize: 12))),
                                                DataCell(
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                                    child: Text(att.memberCode ?? 'S/C', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(att.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: att.isAuthorized ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      att.isAuthorized ? 'AUTORIZADO' : 'RECHAZADO',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: att.isAuthorized ? Colors.greenAccent : Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(Text(att.device ?? 'Molinete Principal', style: const TextStyle(fontSize: 11, color: Colors.white70))),
                                                DataCell(
                                                  Text(
                                                    att.rejectionReason ?? (att.isAuthorized ? 'Acceso correcto' : 'Denegado'),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: att.isAuthorized ? Colors.white60 : Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeedbackCard(AccessState state) {
    final last = state.lastScan;

    if (last == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Terminal en Espera',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            SizedBox(height: 6),
            Text(
              'Pase el carnet de acceso o ingrese el código de socio para verificar estado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final isOk = last.allowed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFF0C2415) : const Color(0xFF2B1014),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOk ? Colors.greenAccent : Colors.redAccent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            size: 72,
            color: isOk ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            isOk ? 'ACCESO AUTORIZADO' : 'ACCESO RECHAZADO',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isOk ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            last.memberName ?? (last.memberCode != null ? 'Código: ${last.memberCode}' : 'Socio no identificado'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (last.memberCode != null)
            Text(
              'Código: #${last.memberCode}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              last.reason ?? last.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOk ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hora: ${_timeFormat.format(last.timestamp)}',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2028),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String activeFilter, Function(String) onSelect) {
    final isSelected = activeFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFF1F242C),
      onSelected: (_) => onSelect(key),
    );
  }
}
