const WEEK_DAYS = new Set([
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday'
]);

const isValidTimeZone = (timeZone) => {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone }).format();
    return true;
  } catch (_) {
    return false;
  }
};

const normalizeTimeZone = (timeZone) => {
  const value = String(timeZone || '').trim();
  return value && isValidTimeZone(value) ? value : 'UTC';
};

const zonedClock = (date, timeZone) => {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: normalizeTimeZone(timeZone),
    weekday: 'long',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23'
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return {
    day: values.weekday,
    minutes: Number(values.hour) * 60 + Number(values.minute)
  };
};

const parseTime = (value) => {
  const match = /^(\d{2}):(\d{2})$/.exec(String(value || ''));
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  return hour <= 23 && minute <= 59 ? hour * 60 + minute : null;
};

const isMenuItemAvailableAt = (item, timeZone, at = new Date()) => {
  if (!item || item.isAvailable === false) return false;
  const publishStatus = item.publishStatus || 'Published';
  if (publishStatus === 'Draft') return false;
  if (publishStatus === 'Scheduled') {
    const publishAt = item.publishAt ? new Date(item.publishAt) : null;
    if (!publishAt || Number.isNaN(publishAt.getTime()) || publishAt > at) {
      return false;
    }
  }
  const schedule = item.availabilitySchedule;
  if (!schedule) return true;
  const days = Array.isArray(schedule.days)
    ? schedule.days.filter((day) => WEEK_DAYS.has(day))
    : [];
  const clock = zonedClock(at, timeZone);
  if (days.length && !days.includes(clock.day)) return false;

  const start = parseTime(schedule.startTime);
  const end = parseTime(schedule.endTime);
  if (start === null && end === null) return true;
  if (start !== null && end === null) return clock.minutes >= start;
  if (start === null && end !== null) return clock.minutes <= end;
  if (start <= end) return clock.minutes >= start && clock.minutes <= end;
  return clock.minutes >= start || clock.minutes <= end;
};

module.exports = {
  isValidTimeZone,
  normalizeTimeZone,
  zonedClock,
  parseTime,
  isMenuItemAvailableAt
};