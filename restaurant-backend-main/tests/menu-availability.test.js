const Branch = require('../src/models/Branch.model');
const {
  normalizeTimeZone,
  zonedClock,
  isMenuItemAvailableAt
} = require('../src/utils/menu-availability');

describe('timezone-aware menu availability', () => {
  test('uses Asia/Kolkata for new restaurant branches', () => {
    expect(new Branch({ restaurantId: '64b000000000000000000001', name: 'Main' }).timezone)
      .toBe('Asia/Kolkata');
  });

  test('rejects invalid IANA timezones on branch writes', async () => {
    const branch = new Branch({
      restaurantId: '64b000000000000000000001',
      name: 'Invalid timezone branch',
      timezone: 'India/Somewhere'
    });
    await expect(branch.validate()).rejects.toThrow('Invalid IANA timezone');
  });

  test('evaluates an Indian lunch schedule in branch time, not server UTC', () => {
    const item = {
      isAvailable: true,
      availabilitySchedule: {
        days: ['Monday'],
        startTime: '11:00',
        endTime: '16:00'
      }
    };
    expect(isMenuItemAvailableAt(item, 'Asia/Kolkata', new Date('2026-08-17T06:00:00.000Z'))).toBe(true);
    expect(isMenuItemAvailableAt(item, 'Asia/Kolkata', new Date('2026-08-17T04:00:00.000Z'))).toBe(false);
    expect(isMenuItemAvailableAt(item, 'Asia/Kolkata', new Date('2026-08-16T06:00:00.000Z'))).toBe(false);
  });

  test('keeps legacy/default items published and hides drafts', () => {
    const at = new Date('2026-08-17T12:00:00.000Z');
    expect(isMenuItemAvailableAt({}, 'UTC', at)).toBe(true);
    expect(isMenuItemAvailableAt({ publishStatus: 'Published' }, 'UTC', at)).toBe(true);
    expect(isMenuItemAvailableAt({ publishStatus: 'Draft' }, 'UTC', at)).toBe(false);
  });

  test('publishes scheduled items only after their publish instant', () => {
    const item = {
      publishStatus: 'Scheduled',
      publishAt: '2026-08-17T12:00:00.000Z'
    };
    expect(isMenuItemAvailableAt(item, 'Asia/Kolkata', new Date('2026-08-17T11:59:59.000Z'))).toBe(false);
    expect(isMenuItemAvailableAt(item, 'Asia/Kolkata', new Date('2026-08-17T12:00:00.000Z'))).toBe(true);
  });

  test('supports serving windows that cross midnight', () => {
    const item = {
      availabilitySchedule: { startTime: '22:00', endTime: '02:00' }
    };
    expect(isMenuItemAvailableAt(item, 'UTC', new Date('2026-08-17T23:00:00.000Z'))).toBe(true);
    expect(isMenuItemAvailableAt(item, 'UTC', new Date('2026-08-17T01:00:00.000Z'))).toBe(true);
    expect(isMenuItemAvailableAt(item, 'UTC', new Date('2026-08-17T12:00:00.000Z'))).toBe(false);
  });

  test('handles one-sided schedules and disabled items', () => {
    expect(isMenuItemAvailableAt({ availabilitySchedule: { startTime: '10:00' } }, 'UTC', new Date('2026-08-17T11:00:00.000Z'))).toBe(true);
    expect(isMenuItemAvailableAt({ availabilitySchedule: { endTime: '10:00' } }, 'UTC', new Date('2026-08-17T11:00:00.000Z'))).toBe(false);
    expect(isMenuItemAvailableAt({ isAvailable: false }, 'UTC')).toBe(false);
  });

  test('falls back safely for an invalid timezone', () => {
    expect(normalizeTimeZone('Not/A-Timezone')).toBe('UTC');
    expect(zonedClock(new Date('2026-08-17T08:15:00.000Z'), 'Not/A-Timezone'))
      .toEqual({ day: 'Monday', minutes: 495 });
  });
});