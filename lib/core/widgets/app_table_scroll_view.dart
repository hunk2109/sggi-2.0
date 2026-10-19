import 'package:flutter/material.dart';

/// Un contenedor de tabla reutilizable con barras de desplazamiento horizontal y vertical
/// explícitas, siempre visibles y navegables con mouse/touch en aplicaciones de escritorio.
class AppTableScrollView extends StatefulWidget {
  final Widget child;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final bool expandChildToWidth;

  const AppTableScrollView({
    super.key,
    required this.child,
    this.minWidth,
    this.padding,
    this.expandChildToWidth = false,
  });

  @override
  State<AppTableScrollView> createState() => _AppTableScrollViewState();
}

class _AppTableScrollViewState extends State<AppTableScrollView> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double minW = widget.minWidth ?? constraints.maxWidth;
        final double targetWidth = constraints.maxWidth > minW ? constraints.maxWidth : minW;

        final Widget innerContent = Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
        );

        final Widget contentWithSizing = widget.expandChildToWidth
            ? SizedBox(
                width: targetWidth,
                child: innerContent,
              )
            : ConstrainedBox(
                constraints: BoxConstraints(minWidth: minW),
                child: innerContent,
              );

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 10,
          radius: const Radius.circular(5),
          notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 10,
            radius: const Radius.circular(5),
            notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: contentWithSizing,
              ),
            ),
          ),
        );
      },
    );
  }
}
