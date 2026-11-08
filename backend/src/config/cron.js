// Best-effort ping while this process is running. A suspended process cannot
// wake itself; use an external scheduler when wake-up across sleep is needed.
const intervalMs = 14 * 60 * 1000;

export const createKeepAliveJob = ({
  env = process.env,
  fetchImpl = globalThis.fetch,
  schedule = setInterval,
  unschedule = clearInterval,
  logger = console,
  requestTimeoutMs = 10000,
} = {}) => {
  let endpoint;
  if (env.NODE_ENV === "production" && env.KEEP_ALIVE_ENABLED === "true") {
    try {
      const origin = new URL(env.API_URL);
      if (origin.protocol !== "https:" || origin.username || origin.password ||
          origin.pathname !== "/" || origin.search || origin.hash) {
        throw new Error("Invalid origin");
      }
      endpoint = new URL("/api/v1/health", origin).href;
    } catch {
      // Never log the configured URL or exception: either could contain secrets.
      logger.warn(JSON.stringify({ code: "KEEP_ALIVE_CONFIG_INVALID" }));
    }
  }

  let started = false, timer = null, inFlight = null;
  const ping = async () => {
    if (!started || inFlight) return;
    const controller = new AbortController();
    inFlight = controller;
    const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);
    timeout.unref?.();
    try {
      const response = await fetchImpl(endpoint, {
        method: "GET",
        redirect: "error",
        signal: controller.signal,
        headers: { Accept: "application/json" },
      });
      await response.body?.cancel();
      if (started) {
        const message = JSON.stringify({
          code: response.status === 200 ? "KEEP_ALIVE_OK" : "KEEP_ALIVE_HTTP_ERROR",
          status: response.status,
        });
        if (response.status === 200) logger.log(message);
        else logger.warn(message);
      }
    } catch {
      if (started) logger.warn(JSON.stringify({ code: "KEEP_ALIVE_REQUEST_FAILED" }));
    } finally {
      clearTimeout(timeout);
      inFlight = null;
    }
  };

  return {
    start() {
      if (started || !endpoint) return false;
      started = true;
      timer = schedule(ping, intervalMs);
      timer.unref?.();
      void ping();
      return true;
    },
    stop() {
      started = false;
      if (timer !== null) unschedule(timer);
      timer = null;
      inFlight?.abort();
    },
  };
};
