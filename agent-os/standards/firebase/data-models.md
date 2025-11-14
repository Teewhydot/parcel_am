# Data Models & Serialization Best Practices

## Model Classes
- Create separate Dart model classes for each Firestore collection/document type
- Use immutable model classes with final fields
- Store models in lib/models/ or lib/data/models/ directory
- Name models descriptively: UserModel, PostModel, CommentModel
- Keep models simple - just data, no business logic
- Use proper null safety - mark nullable fields with ? operator
- Define all fields as final for immutability

## JSON Serialization
- Implement toJson() method to convert model to Map<String, dynamic>
- Implement fromJson() factory constructor to create model from JSON
- Use json_serializable package for automatic serialization code generation
- Annotate models with @JsonSerializable() when using json_serializable
- Run build_runner to generate serialization code: flutter pub run build_runner build
- Handle DateTime serialization explicitly (Firestore Timestamp vs ISO 8601 string)
- Handle nested objects and lists properly in serialization

## Freezed (Recommended)
- Use Freezed package for immutable models with built-in serialization
- Annotate models with @freezed and @JsonSerializable()
- Benefits: immutability, copyWith(), ==, hashCode, toString() generated automatically
- Run build_runner to generate Freezed code: flutter pub run build_runner watch --delete-conflicting-outputs
- Use unions for state classes with multiple variants
- Freezed works seamlessly with json_serializable for JSON conversion

## Firestore Integration
- Store Timestamp fields as Firestore Timestamp, not DateTime
- Use DocumentReference for relationships between collections
- Convert Timestamp to DateTime in model: timestamp.toDate()
- Convert DateTime to Timestamp when saving: Timestamp.fromDate(dateTime)
- Use FieldValue.serverTimestamp() for created/updated timestamps
- Store user references as DocumentReference or just UID string

## Field Naming
- Use camelCase for Dart model fields: userId, createdAt, isPublished
- Use snake_case or camelCase consistently in Firestore (recommend camelCase)
- Keep Firestore field names matching Dart field names for simplicity
- Use @JsonKey(name: 'firebase_field_name') if names must differ
- Document field purpose with comments for complex models

## Required vs Optional Fields
- Mark required fields as non-nullable: final String userId
- Mark optional fields as nullable: final String? bio
- Provide default values in fromJson() for backward compatibility
- Handle missing fields gracefully - don't crash on old document format
- Use @Default() annotation with Freezed for default values
- Validate required fields in model constructors or factory methods

## Timestamps
- Include createdAt and updatedAt timestamps on most collections
- Use FieldValue.serverTimestamp() when creating documents
- Store as Firestore Timestamp type, not String or int
- Convert to DateTime for display: timestamp.toDate()
- Handle null timestamps gracefully (document created before field existed)
- Use @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) for custom handling

## Lists & Arrays
- Use List<T> for arrays in models: List<String> tags
- Implement proper serialization for list of objects
- Use FieldValue.arrayUnion() and arrayRemove() for atomic array operations
- Consider subcollections instead of large arrays (over 100 items)
- Handle empty lists vs null lists consistently
- Use @Default([]) with Freezed for empty list default

## Relationships
- Store DocumentReference for strong relationships
- Store just ID (String) for loose relationships
- Use subcollections for one-to-many relationships
- Denormalize frequently accessed data to avoid extra reads
- Use collection group queries when querying across subcollections
- Document relationship structure clearly

## Data Validation
- Validate data in model constructors or factory methods
- Throw exceptions for invalid data that should never occur
- Return null or default values for data that can be missing
- Implement custom fromJson logic for complex validation
- Use assert() for development-time checks
- Document validation requirements in model comments

## Model Organization
```dart
// Example with Freezed and json_serializable
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    String? bio,
    @Default([]) List<String> followedTopics,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

## Repository Pattern
- Create repository classes to handle Firestore operations
- Keep models free of Firebase dependencies
- Repository converts between Firestore documents and models
- Handle serialization errors in repository, not in models
- Use dependency injection to provide repositories to BLoCs
- Mock repositories in tests for isolated testing

## Error Handling
- Handle serialization errors with try-catch in repositories
- Provide default values for missing or invalid fields when safe
- Log serialization errors for debugging
- Don't crash app on malformed data - handle gracefully
- Validate data types before accessing (e.g., check if field is String)
- Use typed getters that can handle null or wrong type safely

## Migrations & Versioning
- Plan for schema changes - old app versions will read new data
- Add new fields as optional (nullable) for backward compatibility
- Provide default values for new fields in fromJson()
- Use Cloud Functions to migrate data when breaking changes needed
- Version your data models if necessary (add version field)
- Document schema changes in code comments or changelog

## Enums
- Use Dart enums for fields with fixed set of values
- Use json_serializable's @JsonValue for custom JSON values
- Use enhanced enums (Dart 2.17+) for enums with methods
- Handle unknown enum values gracefully in fromJson()
- Consider using sealed classes instead of enums for complex states

## Best Practices
- Keep models simple and focused - one model per document type
- Use code generation (Freezed, json_serializable) to reduce boilerplate
- Test serialization/deserialization with unit tests
- Document complex fields with comments
- Use const constructors where possible
- Implement == and hashCode (automatic with Freezed or Equatable)
- Use copyWith() for updating immutable models (automatic with Freezed)
- Keep serialization logic separate from business logic

## Testing
- Write unit tests for toJson() and fromJson() methods
- Test with valid, invalid, and missing fields
- Test with old document formats to ensure backward compatibility
- Mock Firestore documents in tests
- Test DateTime/Timestamp conversion carefully
- Test nested objects and lists thoroughly