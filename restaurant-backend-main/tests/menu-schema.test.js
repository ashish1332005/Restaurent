const mongoose = require('mongoose');
const MenuItem = require('../src/models/MenuItem.model');
const ServiceRequest = require('../src/models/ServiceRequest.model');

const base = () => ({
    branchId: new mongoose.Types.ObjectId(),
    categoryId: new mongoose.Types.ObjectId(),
    name: 'Rajasthani Thali',
    basePrice: 399
});

describe('multilingual meal and thali schema', () => {
    test('keeps normal menu items backward compatible', async () => {
        const item = new MenuItem(base());
        await expect(item.validate()).resolves.toBeUndefined();
        expect(item.itemType).toBe('Single Item');
    });

    test('accepts bilingual unlimited thali with mixed refill rules', async () => {
        const item = new MenuItem({
            ...base(),
            itemType: 'Thali',
            nameHi: 'राजस्थानी थाली',
            descriptionHi: 'पारंपरिक भोजन',
            thaliConfig: {
                serviceType: 'Unlimited',
                dineInOnly: true,
                servingDurationMinutes: 60,
                includedItems: [
                    { name: 'Roti', nameHi: 'रोटी', quantity: 4, unit: 'pieces', refillPolicy: 'Unlimited' },
                    { name: 'Sweet', nameHi: 'मिठाई', quantity: 1, unit: 'piece', refillPolicy: 'None' }
                ]
            },
            availabilitySchedule: { days: ['Saturday', 'Sunday'], startTime: '11:00', endTime: '16:00' }
        });
        await expect(item.validate()).resolves.toBeUndefined();
        expect(item.thaliConfig.includedItems).toHaveLength(2);
    });

    test('accepts bilingual variants and add-ons', async () => {
        const item = new MenuItem({
            ...base(),
            variants: [
                { name: 'Small', nameHi: 'Small Hindi', price: 199, sku: 'THALI-S' },
                { name: 'Large', nameHi: 'Large Hindi', price: 299, sku: 'THALI-L' }
            ],
            modifiers: [
                { name: 'Extra Cheese', nameHi: 'Cheese Hindi', price: 40 }
            ]
        });
        await expect(item.validate()).resolves.toBeUndefined();
    });

    test('requires a publish date for scheduled items', async () => {
        const scheduled = new MenuItem({ ...base(), publishStatus: 'Scheduled' });
        await expect(scheduled.validate()).rejects.toThrow('Scheduled menu items require a publish date');
        const valid = new MenuItem({
            ...base(),
            publishStatus: 'Scheduled',
            publishAt: new Date(Date.now() + 60000)
        });
        await expect(valid.validate()).resolves.toBeUndefined();
    });

    test('accepts spice, dietary and allergen metadata', async () => {
        const item = new MenuItem({
            ...base(),
            spiceLevel: 'Hot',
            dietaryTags: ['Jain', 'Gluten-Free'],
            allergens: ['Milk', 'Nuts']
        });
        await expect(item.validate()).resolves.toBeUndefined();
    });

    test('rejects unsupported dietary metadata', async () => {
        const item = new MenuItem({
            ...base(),
            spiceLevel: 'Extreme',
            dietaryTags: ['Unknown Diet'],
            allergens: ['Unknown Allergen']
        });
        await expect(item.validate()).rejects.toThrow();
    });

    test('rejects duplicate option names ignoring case', async () => {
        const item = new MenuItem({
            ...base(),
            variants: [
                { name: 'Large', price: 299 },
                { name: 'large', price: 349 }
            ]
        });
        await expect(item.validate()).rejects.toThrow('Variant names must be unique');
    });

    test('rejects duplicate non-empty variant SKUs', async () => {
        const item = new MenuItem({
            ...base(),
            variants: [
                { name: 'Small', price: 199, sku: 'SIZE-1' },
                { name: 'Large', price: 299, sku: 'size-1' }
            ]
        });
        await expect(item.validate()).rejects.toThrow('Variant SKUs must be unique');
    });

    test('rejects duplicate add-on names ignoring case', async () => {
        const item = new MenuItem({
            ...base(),
            modifiers: [
                { name: 'Cheese', price: 30 },
                { name: 'cheese', price: 50 }
            ]
        });
        await expect(item.validate()).rejects.toThrow('Add-on names must be unique');
    });

    test('rejects a thali without included items', async () => {
        const item = new MenuItem({ ...base(), itemType: 'Thali', thaliConfig: { includedItems: [] } });
        await expect(item.validate()).rejects.toThrow('A thali must include at least one item');
    });

    test('requires a limit for Limited refill items', async () => {
        const item = new MenuItem({
            ...base(),
            itemType: 'Thali',
            thaliConfig: {
                serviceType: 'Limited',
                includedItems: [{ name: 'Chaas', quantity: 1, unit: 'glass', refillPolicy: 'Limited' }]
            }
        });
        await expect(item.validate()).rejects.toThrow('Limited refill items require a refill limit');
    });

    test('rejects invalid schedule time', async () => {
        const item = new MenuItem({ ...base(), availabilitySchedule: { startTime: '25:90' } });
        await expect(item.validate()).rejects.toThrow('Invalid start time');
    });
});
describe('thali refill request schema', () => {
    test('accepts a tracked limited refill request', async () => {
        const request = new ServiceRequest({
            branchId: new mongoose.Types.ObjectId(),
            tableId: new mongoose.Types.ObjectId(),
            tableSessionId: new mongoose.Types.ObjectId(),
            type: 'Refill',
            menuItemId: new mongoose.Types.ObjectId(),
            dishName: 'Chaas',
            dishNameHi: 'Chaas Hindi',
            refillPolicy: 'Limited',
            refillLimit: 2,
            refillNumber: 1
        });
        await expect(request.validate()).resolves.toBeUndefined();
    });

    test('rejects unsupported service request types', async () => {
        const request = new ServiceRequest({
            branchId: new mongoose.Types.ObjectId(),
            tableId: new mongoose.Types.ObjectId(),
            type: 'Extra Food'
        });
        await expect(request.validate()).rejects.toThrow();
    });
});