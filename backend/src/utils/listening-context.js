export const recommendationContext = (at, utcOffsetMinutes = 420) => {
  const hour = new Date(at.getTime() + utcOffsetMinutes * 60000).getUTCHours();
  const daypart =
    hour < 5 || hour >= 22
      ? "night"
      : hour < 12
        ? "morning"
        : hour < 18
          ? "afternoon"
          : "evening";
  return { daypart, utcOffsetMinutes };
};
