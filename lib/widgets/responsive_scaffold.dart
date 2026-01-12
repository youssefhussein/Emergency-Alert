import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.backgroundColor,
    this.scrollable = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: body);

    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
