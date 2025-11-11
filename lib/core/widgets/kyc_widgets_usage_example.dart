// KYC Widgets Usage Examples
// This file demonstrates how to use the KYC status widgets throughout the app

/*

1. KYC STATUS BANNER (Full-width banner with action)
   Use in main screens like Dashboard, Profile, etc.
   
   const KycStatusBanner()
   
   // With custom margin
   const KycStatusBanner(
     margin: EdgeInsets.all(16),
   )
   
   // Show even when approved
   const KycStatusBanner(
     showOnApproved: true,
   )

2. KYC STATUS CARD (Detailed card widget)
   Use in Profile or Settings screens for more detailed status info
   
   const KycStatusCard()
   
   // With custom spacing
   const KycStatusCard(
     margin: EdgeInsets.symmetric(horizontal: 16),
     padding: EdgeInsets.all(20),
   )

3. KYC STATUS INDICATOR (Compact clickable badge)
   Use in AppBar for quick status check
   
   const KycStatusIndicator()
   
   // In AppBar
   AppBar(
     title: Text('Dashboard'),
     actions: [
       Padding(
         padding: EdgeInsets.only(right: 8),
         child: Center(child: KycStatusIndicator()),
       ),
     ],
   )

4. KYC STATUS BADGE (Display-only badge)
   Use to show status inline with other content
   
   KycStatusBadge(status: user.kycStatus)
   
   // Compact version
   KycStatusBadge(
     status: user.kycStatus,
     compact: true,
   )

5. KYC STATUS ICON (Simple icon with tooltip)
   Use in lists or compact spaces
   
   const KycStatusIcon()
   
   // Custom size
   const KycStatusIcon(size: 20)

6. APP BAR WITH KYC (AppBar with integrated KYC indicator)
   Use as replacement for standard AppBar
   
   const AppBarWithKyc(
     title: 'My Profile',
   )
   
   // Disable KYC indicator
   const AppBarWithKyc(
     title: 'Settings',
     showKycIndicator: false,
   )
   
   // With actions
   AppBarWithKyc(
     title: 'Dashboard',
     actions: [
       IconButton(
         icon: Icon(Icons.notifications),
         onPressed: () {},
       ),
     ],
   )

7. PROFILE HEADER WITH KYC (Profile section with KYC badge)
   Use in Profile or Account screens
   
   ProfileHeaderWithKyc(
     displayName: user.displayName,
     email: user.email,
     photoUrl: user.profilePhotoUrl,
   )

EXAMPLE SCREEN IMPLEMENTATION:

```dart
class MyProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithKyc(
        title: 'My Profile',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with KYC badge
            BlocBuilder<AuthBloc, BaseState<AuthData>>(
              builder: (context, state) {
                if (state is DataState<AuthData> && state.data?.user != null) {
                  final user = state.data!.user!;
                  return ProfileHeaderWithKyc(
                    displayName: user.displayName,
                    email: user.email,
                    photoUrl: user.profilePhotoUrl,
                  );
                }
                return SizedBox.shrink();
              },
            ),
            
            // KYC status card
            const KycStatusCard(),
            
            // Other profile content...
          ],
        ),
      ),
    );
  }
}
```

NOTIFICATION LISTENER:
The KycNotificationListener is already set up in main.dart and will automatically
show notifications when KYC status changes. No additional setup needed.

ROUTE GUARDS:
Routes are already protected with KYC middleware. To add KYC protection to a new route:

```dart
AuthGuard.createProtectedRoute(
  name: Routes.newFeature,
  page: () => const NewFeatureScreen(),
  requiresKyc: true,  // Add this flag
)
```

Protected routes (requiring KYC verification):
- Dashboard
- Wallet
- Payment
- Tracking
- Browse Requests

*/
