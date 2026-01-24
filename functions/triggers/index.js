// ========================================================================
// Triggers - Barrel Export
// ========================================================================

const { onParcelAwaitingConfirmation, onParcelStatusUpdate } = require('./parcel-triggers');
const { onChatMessageCreated, onChatMessageNotification } = require('./chat-triggers');

module.exports = {
  onParcelAwaitingConfirmation,
  onParcelStatusUpdate,
  // New RTDB trigger for chat messages
  onChatMessageCreated,
  // Legacy alias (maps to onChatMessageCreated for backward compatibility)
  onChatMessageNotification,
};
