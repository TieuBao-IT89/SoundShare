import { Router } from 'express';
import { createLyricsController } from '../controllers/lyrics.controller.js';
import { createRateLimit } from '../middleware/upload-limits.middleware.js';

export const createLyricsRouter = ({ service, requireAuth }) => {
  const router = Router({ mergeParams: true });
  const controller = createLyricsController(service);
  router.use(requireAuth);
  router.use((req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
  router.use(createRateLimit({ limit: 120 }));
  router.get('/', controller.read);
  router.put('/', createRateLimit({ limit: 20 }), controller.save);
  router.delete('/', createRateLimit({ limit: 20 }), controller.remove);
  return router;
};
