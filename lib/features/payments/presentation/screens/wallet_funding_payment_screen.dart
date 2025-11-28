import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';
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
    _transactionStatusSubscription = FirebaseFirestore.instance
        .collection('walletTransactions')
        .doc(widget.transactionId)
        .snapshots()
        .listen((docSnapshot) {
      if (!mounted || hasProcessedPayment) return;

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final status = data['status'] as String?;
          final paymentStatus = data['paymentStatus'] as String?;

          // Check if payment was successful
          if (paymentStatus == 'success' ||
              paymentStatus == 'completed' ||
              status == 'success' ||
              status == 'completed') {
            hasProcessedPayment = true;
            _navigateToSuccessScreen();
          }
          // Check if payment failed
          else if (paymentStatus == 'failed' ||
              paymentStatus == 'cancelled' ||
              status == 'failed' ||
              status == 'cancelled') {
            hasProcessedPayment = true;
            _handlePaymentFailure();
          }
        }
      }
    });
  }

  void _navigateToSuccessScreen() {
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

  void _handlePaymentFailure() {
    nav.goBack();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment failed or was cancelled. Please try again.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Complete Payment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                    'Are you sure you want to cancel this payment? You will need to start over.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue Payment'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      nav.goBack();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
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
                const SnackBar(
                  content: Text('Failed to load payment page. Please try again.'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 4),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    AppText(
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
