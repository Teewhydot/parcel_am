# Clean Architecture Violations Report

**Generated:** 2025-11-15
**Scope:** Complete codebase scan
**Status:** 7 CRITICAL violations found

---

## 🚨 CRITICAL VIOLATIONS

### 1. UseCase Direct Repository Instantiation (2 violations)

**Pattern:** UseCases directly instantiate repository implementations instead of using constructor injection.

| File | Line | Violation |
|------|------|-----------|
| `lib/features/travellink/domain/usecases/wallet_usecase.dart` | 8 | `final walletRepo = WalletRepositoryImpl();` |
| `lib/features/travellink/domain/usecases/kyc_usecase.dart` | 6 | `final kycRepo = KycRepositoryImpl();` |

**Impact:**
- Violates Dependency Inversion Principle
- Makes unit testing impossible (can't mock repositories)
- Creates tight coupling between domain and data layers
- **Same violation previously fixed in auth_usecase.dart**

**Required Fix:**
```dart
// WRONG:
class WalletUseCase {
  final walletRepo = WalletRepositoryImpl();
}

// CORRECT:
class WalletUseCase {
  final WalletRepository walletRepo;
  WalletUseCase(this.walletRepo);
}
```

---

### 2. BLoC Direct UseCase Fallback Instantiation (2 violations)

**Pattern:** BLoCs have nullable UseCase parameters with fallback to direct instantiation.

| File | Line | Violation |
|------|------|-----------|
| `lib/features/travellink/presentation/bloc/wallet/wallet_bloc.dart` | 18 | `_walletUseCase = walletUseCase ?? WalletUseCase()` |
| `lib/features/travellink/presentation/bloc/kyc/kyc_bloc.dart` | 13 | `_kycUseCase = kycUseCase ?? KycUseCase()` |

**Impact:**
- Makes UseCase parameter optional, defeating DI purpose
- Fallback creates unmanaged dependencies
- Root cause: Missing DI registration (see #3)

**Required Fix:**
```dart
// WRONG:
KycBloc({KycUseCase? kycUseCase})
  : _kycUseCase = kycUseCase ?? KycUseCase();

// CORRECT:
KycBloc({required KycUseCase kycUseCase})
  : _kycUseCase = kycUseCase;
```

---

### 3. Missing DI Registration (3 violations)

**Pattern:** BLoCs and UseCases not properly registered in dependency injection container.

| Component | Location | Issue |
|-----------|----------|-------|
| `WalletBloc` | `injection_container.dart:162` | Registered as `WalletBloc()` instead of `WalletBloc(walletUseCase: sl())` |
| `WalletUseCase` | `injection_container.dart` | NOT registered at all |
| `KycUseCase` | `injection_container.dart` | NOT registered at all |

**Impact:**
- BLoCs cannot receive proper dependencies
- Forces use of fallback instantiation patterns (violation #2)
- No central dependency management

**Required Fix:**
```dart
// In TravelLink feature DI module or injection_container.dart:

// Use Cases
sl.registerLazySingleton(() => WalletUseCase(sl()));
sl.registerLazySingleton(() => KycUseCase(sl()));

// BLoCs
sl.registerFactory(() => WalletBloc(walletUseCase: sl()));
sl.registerFactory(() => KycBloc(kycUseCase: sl()));
```

---

## ⚠️ ARCHITECTURAL ISSUES

### 4. Duplicate Wallet Feature

**Issue:** Two separate wallet feature implementations exist:

| Location | Status | Components |
|----------|--------|------------|
| `lib/features/wallet/` | PARTIAL | ✅ Data layer<br>✅ Domain entities/repositories<br>❌ NO usecases<br>❌ NO presentation |
| `lib/features/travellink/` | COMPLETE | ✅ Full wallet implementation<br>✅ UseCases<br>✅ BLoC<br>✅ Screens |

**Impact:**
- Code duplication and confusion
- Unclear which implementation to use
- Maintenance burden

**Recommendation:**
- Consolidate into single wallet feature
- OR clearly document purpose of each
- OR remove the incomplete `lib/features/wallet/`

---

### 5. Core Services Direct Firebase Access (DOCUMENTED)

**Status:** Previously identified in `CLEAN_ARCHITECTURE_STATUS.md` as technical debt.

**Services with violations:**
1. `lib/core/services/presence_service.dart:43` - Direct Firestore access
2. `lib/core/services/chat_notification_service.dart`
3. `lib/core/services/escrow_notification_service.dart`
4. `lib/core/services/push_notification_service.dart`
5. `lib/core/services/firebase_service.dart`
6. `lib/core/services/notification_service.dart`
7. `lib/core/services/error_handler.dart`

**Note:** Core services are infrastructure-level, but should ideally abstract domain logic through use cases.

---

## ✅ PREVIOUSLY FIXED VIOLATIONS

These violations were identified and fixed in earlier refactoring:

| Feature | Violation | Status |
|---------|-----------|--------|
| Auth | Direct repository instantiation in `auth_usecase.dart` | ✅ FIXED |
| Auth | Direct usecase instantiation in `auth_bloc.dart` | ✅ FIXED |
| Chat Screens | Direct Firebase imports and queries | ✅ FIXED |
| Dashboard | Direct data source instantiation | ✅ FIXED |
| Package Tracking | 75% of operations using data sources | ✅ FIXED |

---

## 📊 SUMMARY

### Violation Breakdown
- **Critical DI Violations:** 7
  - UseCase direct instantiation: 2
  - BLoC fallback instantiation: 2
  - Missing DI registration: 3
- **Architectural Issues:** 2
  - Duplicate wallet feature: 1
  - Core services (documented): ~8 services
- **Total Issues:** 9 critical + 2 architectural

### Compliance Status
- **Fully Compliant Features:** Chat, Package, Auth, Escrow, Parcel, Notifications
- **Violations Found:** KYC, Wallet (in TravelLink)
- **Overall Compliance:** ~85% (down from 95% - new violations discovered)

---

## 🎯 RECOMMENDED FIX ORDER

1. **Fix KYC Feature DI** (30 min)
   - Add constructor injection to `KycUseCase`
   - Make `kycUseCase` required in `KycBloc`
   - Register both in DI container

2. **Fix Wallet Feature DI** (30 min)
   - Add constructor injection to `WalletUseCase`
   - Make `walletUseCase` required in `WalletBloc`
   - Register both in DI container

3. **Resolve Duplicate Wallet Feature** (15 min)
   - Delete `lib/features/wallet/` OR consolidate

4. **Core Services Refactoring** (OPTIONAL - 2-3 hours)
   - Move to technical debt backlog
   - Requires careful architectural planning

---

*This report identifies violations missed in the initial refactoring pass.*
