// ========================================================================
// Triggers - Barrel Export
// ========================================================================

const { onParcelAwaitingConfirmation } = require('./parcel-triggers');
const { onChatMessageNotification } = require('./chat-triggers');

module.exports = {
  onParcelAwaitingConfirmation,
  onChatMessageNotification
};
