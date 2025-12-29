import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/routes/routes.dart';

class WalletFundingPaymentScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String transactionId;
  final String userId;
  final double amount;

  const WalletFundingPaymentScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.transactionId,
    required this.userId,
    required this.amount,
  });

  @override
  State<WalletFundingPaymentScreen> createState() =>
      _WalletFundingPaymentScreenState();
}

class _WalletFundingPaymentScreenState
    extends State<WalletFundingPaymentScreen> {
  late InAppWebViewController webViewController;
  bool isLoading = true;
  double loadingProgress = 0;
  bool hasProcessedPayment = false;
  final nav = GetIt.instance<NavigationService>();
  StreamSubscription<DocumentSnapshot>? _transactionStatusSubscription;

  @override
  void initState() {
    super.initState();
    _startTransactionStatusListener();
  }

  @override
  void dispose() {
    _transactionStatusSubscription?.cancel();
    super.dispose();
  }

  void _startTransactionStatusListener() {
    // Listen to funding_orders collection with the prefixed reference
    final fundingOrderId = 'F-${widget.reference}';

    _transactionStatusSubscription = FirebaseFirestore.instance
        .collection('funding_orders')
        .doc(fundingOrderId)
        .snapshots()
        .listen((docSnapshot) {
      if (!mounted || hasProcessedPayment) return;

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final status = data['status'] as String?;

          // Check if payment was successful
          if (status == 'success' ||
              status == 'confirmed' ||
              status == 'completed') {
            hasProcessedPayment = true;
            _navigateToConfirmationScreen();
          }
          // Check if payment failed
          else if (status == 'failed' ||
              status == 'cancelled' ||
              status == 'expired') {
            hasProcessedPayment = true;
            _navigateToConfirmationScreen();
          }
        }
      }
    });
  }

  void _navigateToConfirmationScreen() {
    nav.navigateTo(
      Routes.walletFundingSuccess,
      arguments: {
        'transactionId': widget.transactionId,
        'reference': widget.reference,
        'amount': widget.amount,
        'userId': widget.userId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Complete Payment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Proceed to confirmation',
            onPressed: () {
              _navigateToConfirmationScreen();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.authorizationUrl),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                loadingProgress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium('Failed to load payment page. Please try again.', color: AppColors.white),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllow: "camera; microphone",
              iframeAllowFullscreen: true,
            ),
          ),

          // Loading indicator
          if (isLoading)
            Container(
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    const AppText(
                      'Loading payment page...',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

          // Progress bar
          if (loadingProgress < 1.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: loadingProgress,
                backgroundColor: AppColors.onSurfaceVariant.withAlpha((0.2 * 255).toInt()),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
