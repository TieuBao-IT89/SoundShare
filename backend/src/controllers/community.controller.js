// Keep HTTP serialization separate from validation and domain operations.
export const communityController =
  (action, { status = 200, empty = false } = {}) =>
  async (req, res) => {
    const data = await action(req.clerkUserId, req.validated);
    if (empty) res.status(status).end();
    else res.status(status).json({ success: true, data });
  };
