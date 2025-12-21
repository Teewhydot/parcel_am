import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_text.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.centerTitle = true,
    this.hasGradientBackground = false,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final Color? appBarBackgroundColor;
  final bool centerTitle;
  final bool hasGradientBackground;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? (hasGradientBackground ? Colors.transparent : AppColors.background),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title != null || leading != null || actions != null 
        ? AppBar(
            title: title != null ? AppText.titleLarge(title!) : null,
            leading: leading,
            actions: actions,
            backgroundColor: appBarBackgroundColor ?? (hasGradientBackground ? Colors.transparent : null),
            centerTitle: centerTitle,
            elevation: 0,
            scrolledUnderElevation: 0,
          )
        : null,
      body: _buildBody(),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  Widget _buildBody() {
    Widget bodyWidget = body ?? const SizedBox.shrink();
    
    if (safeAreaTop || safeAreaBottom) {
      bodyWidget = SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: bodyWidget,
      );
    }
    
    return bodyWidget;
  }
}