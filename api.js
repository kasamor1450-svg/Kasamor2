/**
 * =========================================================================
 * AgroApp API Client & Cloud Sync Adapter
 * Ù…Ø´Ø±ÙˆØ¹ Ø£Ø¨Ù†Ø§Ø¡ Ù…ØµØ·ÙÙ‰ Ø­Ø³Ù† Ø§Ù„Ø²Ø±Ø§Ø¹ÙŠ - Ø§Ù„Ù‚Ø¶Ø§Ø±Ù
 * Ø·Ø¨Ù‚Ø© Ø§Ù„Ø±Ø¨Ø· Ù…Ø¹ Ø£ÙŠ Ø®Ø§Ø¯Ù… Ø³Ø­Ø§Ø¨ÙŠ Ø£Ùˆ ÙˆØ§Ø¬Ù‡Ø© Ø¨Ø±Ù…Ø¬Ø© ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ù…Ø³ØªÙ‚Ø¨Ù„ÙŠØ§Ù‹
 * =========================================================================
 */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['./database'], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('./database'));
  } else {
    root.AgroAPI = factory(root.AgroDatabase);
  }
}(typeof self !== 'undefined' ? self : this, function (db) {
  'use strict';

  class AgroApiClient {
    constructor(config = {}) {
      this.baseUrl = config.baseUrl || '/api/v1';
      this.mode = config.mode || 'offline-first'; // 'offline-first' | 'online-only' | 'hybrid'
      this.db = db || (typeof window !== 'undefined' ? window.AgroDatabase : null);
    }

    /**
     * Generic fetch wrapper
     */
    async request(endpoint, options = {}) {
      if (this.mode === 'offline-first') {
        return this.handleOfflineRequest(endpoint, options);
      }

      try {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
          headers: {
            'Content-Type': 'application/json',
            ...(options.headers || {})
          },
          ...options
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        return await response.json();
      } catch (err) {
        console.warn(`Cloud API request failed, falling back to local database:`, err);
        return this.handleOfflineRequest(endpoint, options);
      }
    }

    /**
     * Handle requests against local Database Engine
     */
    handleOfflineRequest(endpoint, options) {
      if (!this.db) return { success: false, error: 'Database not available' };
      
      const cleanEndpoint = endpoint.replace(/^\//, '');
      const parts = cleanEndpoint.split('/');
      const table = parts[0];
      const id = parts[1];

      if (options.method === 'POST') {
        const record = JSON.parse(options.body || '{}');
        const inserted = this.db.insert(table, record);
        return { success: true, data: inserted };
      } else if (options.method === 'PUT' || options.method === 'PATCH') {
        const updateData = JSON.parse(options.body || '{}');
        const updated = this.db.update(table, id, updateData);
        return { success: !!updated, data: updated };
      } else if (options.method === 'DELETE') {
        const deleted = this.db.delete(table, id);
        return { success: deleted };
      } else {
        // GET
        if (id) {
          const item = this.db.findById(table, id);
          return { success: !!item, data: item };
        } else {
          const data = this.db.get(table);
          return { success: true, data: data };
        }
      }
    }

    // High level domain methods
    async getExpenses() { return this.request('/expenses'); }
    async addExpense(exp) { return this.request('/expenses', { method: 'POST', body: JSON.stringify(exp) }); }
    async getHarvest() { return this.request('/harvestIntakes'); }
    async getSales() { return this.request('/cropSales'); }
    async getPartners() { return this.request('/partners'); }
    async getMachinery() { return this.request('/machinery'); }
    async getLabor() { return this.request('/labor'); }
    async getInventory() { return this.request('/inventory'); }
    async getPlots() { return this.request('/plots'); }
    async getFuel() { return this.request('/fuelTransactions'); }
  }

  return new AgroApiClient();
}));