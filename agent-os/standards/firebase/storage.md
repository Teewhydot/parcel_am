# Firebase Storage Best Practices

## File Organization
- Organize files in logical folder structure: /users/{userId}/profile.jpg
- Use user UID in path for user-specific files: /users/{uid}/uploads/...
- Store public files in /public/ directory with read-only Security Rules
- Keep file paths meaningful and readable
- Use consistent naming conventions for files
- Avoid deeply nested folder structures (keep it under 3-4 levels)
- Use timestamps or UUIDs for unique filenames to avoid collisions

## Uploads
- Show upload progress with UploadTask.snapshotEvents stream
- Allow users to pause/resume uploads with pause() and resume()
- Allow users to cancel uploads with cancel()
- Compress images before uploading to reduce bandwidth and storage costs
- Use putFile() for local files, putData() for bytes, putString() for base64
- Set appropriate metadata (contentType, customMetadata) during upload
- Generate unique filenames to prevent overwriting: '${DateTime.now().millisecondsSinceEpoch}_${file.name}'
- Handle upload failures with try-catch and retry logic

## Downloads
- Use getDownloadURL() to get permanent download links
- Cache download URLs locally to avoid repeated Storage calls
- Download URLs are valid for a limited time - refresh if expired
- Use getData() for small files (< 10MB) to get bytes directly
- Use writeToFile() for larger files to avoid memory issues
- Show download progress when downloading large files
- Handle download failures gracefully with user feedback

## Image Handling
- Compress images before upload using image package
- Generate thumbnails on upload using Cloud Functions
- Store multiple image sizes (thumbnail, medium, full) for responsive loading
- Use cached_network_image package for efficient image loading and caching
- Set max dimensions when compressing: 1920x1080 for full size, 400x400 for thumbnails
- Use JPEG for photos (smaller size), PNG for images requiring transparency
- Consider WebP format for better compression with quality

## Security Rules
- Restrict uploads/downloads using Firebase Storage Security Rules
- Validate file size in Security Rules: request.resource.size < 10 * 1024 * 1024 (10MB)
- Validate file type: request.resource.contentType.matches('image/.*')
- Ensure users can only access their own files: request.auth.uid == userId
- Use allow read, write: if conditions for granular control
- Test Security Rules thoroughly - wrong rules can expose user data
- Document Security Rules clearly with comments

## Metadata
- Set content type explicitly: metadata.contentType = 'image/jpeg'
- Use custom metadata for app-specific information: metadata.customMetadata = {'userId': uid}
- Store file description, tags, or categorization in custom metadata
- Access metadata with getMetadata() when needed
- Update metadata with updateMetadata() without re-uploading file
- Include upload timestamp in metadata for tracking

## Performance & Optimization
- Compress files before upload to save bandwidth and storage
- Use resumable uploads for large files (automatic with putFile)
- Implement concurrent uploads with proper queue management
- Cache download URLs to reduce Storage API calls
- Lazy load images in lists - don't load all at once
- Use thumbnails for list views, full images for detail views
- Prefetch images that will likely be needed soon

## Cost Optimization
- Monitor storage usage and bandwidth in Firebase Console
- Delete old or unused files regularly
- Implement file retention policies (auto-delete after N days)
- Use Cloud Functions to clean up orphaned files
- Compress images aggressively to reduce storage costs
- Use CDN caching for frequently accessed files (Firebase Storage has built-in CDN)
- Set appropriate cache control headers in metadata

## Error Handling
- Handle StorageException with specific error codes
- Provide user-friendly error messages for common errors (no permission, file not found, network error)
- Implement retry logic for transient network errors
- Show upload/download failure with option to retry
- Log errors for debugging but don't expose to users
- Handle cases where file doesn't exist gracefully

## File Deletion
- Delete files when no longer needed with delete()
- Clean up user files when user deletes account
- Use Cloud Functions to delete files when corresponding Firestore documents are deleted
- Implement soft delete with Firestore flag before actual Storage deletion
- Handle delete permission errors appropriately
- Don't assume delete() success - wrap in try-catch

## Testing
- Use Firebase Emulator for local storage testing
- Test upload/download flows with various file types and sizes
- Test error scenarios (network failure, permission denied, file too large)
- Test Security Rules with different user contexts
- Mock Firebase Storage in unit tests
- Test image compression and thumbnail generation
- Test concurrent uploads and downloads

## User Experience
- Show progress indicators during uploads/downloads
- Allow users to cancel long-running operations
- Provide visual feedback for successful uploads (checkmark, confirmation)
- Cache images locally for offline access when appropriate
- Implement image placeholders and progressive loading
- Handle slow networks gracefully with timeouts
- Allow users to view upload/download history

## Profile Pictures
- Store profile pictures at consistent path: /users/{uid}/profile.jpg
- Generate and store thumbnail: /users/{uid}/profile_thumb.jpg
- Update user profile document in Firestore with download URL
- Allow users to update/delete profile pictures
- Compress profile pictures to reasonable size (e.g., 800x800 max)
- Show cached image while new profile picture uploads
- Handle cases where profile picture doesn't exist (default avatar)

## Video & Large Files
- For videos, use resumable uploads (automatic with putFile)
- Show upload progress with percentage and estimated time remaining
- Use Cloud Functions for video transcoding if needed
- Store multiple video qualities for adaptive streaming
- Set appropriate chunk size for large file uploads
- Consider using Firebase Extensions for video processing
- Test with various file sizes up to your maximum allowed limit