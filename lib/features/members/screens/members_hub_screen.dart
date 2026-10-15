import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../memberships/screens/memberships_catalog_screen.dart';
import 'members_screen.dart';

class MembersHubScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const MembersHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MembersHubScreen> createState() => _MembersHubScreenState();
}

class _MembersHubScreenState extends ConsumerState<MembersHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Navigation Hub Tabs
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF16191E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF282F3B)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Directorio de Socios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Planes de Membresía (Crear y Modificar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MembersScreen(),
              MembershipsCatalogScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
