// ========================================================================
// Triggers - Barrel Export
// ========================================================================

const { onParcelAwaitingConfirmation, onParcelStatusUpdate } = require('./parcel-triggers');
const { onChatMessageNotification, onChatPageUpdated } = require('./chat-triggers');

module.exports = {
  onParcelAwaitingConfirmation,
  onParcelStatusUpdate,
  onChatMessageNotification,
  onChatPageUpdated
};
