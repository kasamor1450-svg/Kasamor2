/**
 * =========================================================================
 * AgroApp Database Engine (Data Access Layer - DAL)
 * Ù…Ø´Ø±ÙˆØ¹ Ø£Ø¨Ù†Ø§Ø¡ Ù…ØµØ·ÙÙ‰ Ø­Ø³Ù† Ø§Ù„Ø²Ø±Ø§Ø¹ÙŠ - Ø§Ù„Ù‚Ø¶Ø§Ø±Ù
 * ÙˆØ­Ø¯Ø© Ø¥Ø¯Ø§Ø±Ø© ÙˆÙ‚Ø±Ø§Ø¡Ø© ÙˆØ­ÙØ¸ ÙˆÙ…Ø¹Ø§Ù„Ø¬Ø© Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø³ØªÙ‚Ù„Ø©
 * =========================================================================
 */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.AgroDatabase = factory();
    root.DB = root.AgroDatabase; // Alias for convenience
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  const STORAGE_KEY = 'AGRO_MASTER_PERMANENT_DATABASE_2026_LIVE';
  const BACKUP_PREFIX = 'AGRO_DB_BACKUP_';
  const DB_VERSION = '2026.8.31';

  let listeners = [];
  let currentData = null;

  /**
   * Seed Data Fallback Loader (Embedded Pristine Data)
   */
  function getSeedData() {
    if (typeof window !== 'undefined' && window.AGRO_DEFAULT_SEEDED_DATA) {
      return JSON.parse(JSON.stringify(window.AGRO_DEFAULT_SEEDED_DATA));
    }
    return null;
  }

  /**
   * Database Class Definition
   */
  class DatabaseEngine {
    constructor() {
      this.version = DB_VERSION;
      this.storageKey = STORAGE_KEY;
      this.init();
    }

    /**
     * Initialize and load database state
     */
    init() {
      try {
        const raw = localStorage.getItem(this.storageKey);
        if (raw) {
          currentData = JSON.parse(raw);
        } else {
          // Check candidate legacy keys
          const candidateKeys = [
            'AGRO_MASTER_PERMANENT_DATABASE_2026_LIVE',
            'AGRO_MASTER_PERMANENT_DATABASE',
            'agro_management_system_master_state_2026_v2',
            'agro_management_system_state_v2026_master'
          ];
          for (let k of candidateKeys) {
            const oldRaw = localStorage.getItem(k);
            if (oldRaw) {
              try {
                currentData = JSON.parse(oldRaw);
                this.persist();
                break;
              } catch (e) {}
            }
          }
        }
      } catch (e) {
        console.warn('LocalStorage read error:', e);
      }

      if (!currentData) {
        currentData = getSeedData() || {};
        this.persist();
      }

      this.ensureSchemaIntegrity();
      return currentData;
    }

    /**
     * Ensure all tables and expected collections exist
     */
    ensureSchemaIntegrity() {
      if (!currentData) currentData = {};
      const requiredTables = [
        'users', 'plots', 'fuelTransactions', 'inventory',
        'inventoryTransactions', 'groceryTransactions', 'partners',
        'capitalInjections', 'harvestIntakes', 'cropSales',
        'zakatDeliveries', 'machinery', 'machineryMaintenance',
        'labor', 'expenses', 'budgetCaps', 'auditLogs'
      ];
      requiredTables.forEach(tbl => {
        if (!Array.isArray(currentData[tbl])) {
          currentData[tbl] = [];
        }
      });
      if (!currentData.farmInfo) {
        currentData.farmInfo = {
          name: "Ù…Ø´Ø±ÙˆØ¹ Ø£Ø¨Ù†Ø§Ø¡ Ù…ØµØ·ÙÙ‰ Ø­Ø³Ù† Ø§Ù„Ø²Ø±Ø§Ø¹ÙŠ",
          location: "Ø§Ù„Ù‚Ø¶Ø§Ø±ÙØŒ ÙƒØ³Ù…ÙˆØ± Ø§Ù„Ø´Ø±Ù‚ÙŠ",
          totalArea: 1450,
          seasonStart: "2026-06-01",
          seasonDurationMonths: 6,
          currency: "Ø¬Ù†ÙŠÙ‡ Ø³ÙˆØ¯Ø§Ù†ÙŠ"
        };
      }
      if (!currentData.fuelSummary) {
        currentData.fuelSummary = { purchased: 14, consumed: 10, inWarehouse: 4, unit: "Ø¨Ø±Ù…ÙŠÙ„" };
      }
      if (!currentData.capitalPlan) {
        currentData.capitalPlan = { totalCapital: 300000000, cultivationBudget: 200000000, harvestBudget: 100000000 };
      }
    }

    /**
     * Get whole database snapshot or a specific table
     */
    get(tableName) {
      if (!currentData) this.init();
      if (!tableName) return currentData;
      return currentData[tableName] || null;
    }

    /**
     * Insert a record into a table
     */
    insert(tableName, record) {
      if (!currentData) this.init();
      if (!Array.isArray(currentData[tableName])) {
        currentData[tableName] = [];
      }
      if (!record.id) {
        record.id = `${tableName.substr(0, 3)}-${Date.now()}-${Math.floor(Math.random()*1000)}`;
      }
      currentData[tableName].unshift(record);
      this.persist();
      this.notify(tableName, 'insert', record);
      return record;
    }

    /**
     * Find records matching predicate or query object
     */
    find(tableName, query) {
      const list = this.get(tableName);
      if (!Array.isArray(list)) return [];
      if (typeof query === 'function') {
        return list.filter(query);
      }
      if (typeof query === 'object' && query !== null) {
        return list.filter(item => {
          return Object.keys(query).every(key => item[key] === query[key]);
        });
      }
      return list;
    }

    /**
     * Find single record by ID
     */
    findById(tableName, id) {
      const list = this.get(tableName);
      if (!Array.isArray(list)) return null;
      return list.find(item => item.id === id) || null;
    }

    /**
     * Update a record by ID
     */
    update(tableName, id, updateData) {
      if (!currentData) this.init();
      const list = currentData[tableName];
      if (!Array.isArray(list)) return false;
      const idx = list.findIndex(item => item.id === id);
      if (idx === -1) return false;

      list[idx] = Object.assign({}, list[idx], updateData);
      this.persist();
      this.notify(tableName, 'update', list[idx]);
      return list[idx];
    }

    /**
     * Delete a record by ID
     */
    delete(tableName, id) {
      if (!currentData) this.init();
      const list = currentData[tableName];
      if (!Array.isArray(list)) return false;
      const idx = list.findIndex(item => item.id === id);
      if (idx === -1) return false;

      const deleted = list.splice(idx, 1)[0];
      this.persist();
      this.notify(tableName, 'delete', deleted);
      return true;
    }

    /**
     * Replace entire database state
     */
    replaceState(newState) {
      if (typeof newState !== 'object' || newState === null) return false;
      currentData = JSON.parse(JSON.stringify(newState));
      this.ensureSchemaIntegrity();
      this.persist();
      this.notify('*', 'replace', currentData);
      return true;
    }

    /**
     * Persist current state to localStorage and IndexedDB
     */
    persist() {
      if (!currentData) return;
      try {
        const jsonStr = JSON.stringify(currentData);
        localStorage.setItem(this.storageKey, jsonStr);
        // Automatic timestamped local backup (rotate last 3)
        const now = new Date().toISOString().split('T')[0];
        localStorage.setItem(`${BACKUP_PREFIX}${now}`, jsonStr);
      } catch (e) {
        console.error('Failed to save to localStorage:', e);
      }
    }

    /**
     * Subscribe to database change events
     */
    subscribe(callback) {
      if (typeof callback === 'function') {
        listeners.push(callback);
      }
      return () => {
        listeners = listeners.filter(fn => fn !== callback);
      };
    }

    /**
     * Notify subscribers
     */
    notify(table, action, payload) {
      listeners.forEach(fn => {
        try {
          fn({ table, action, payload, timestamp: new Date() });
        } catch (e) {
          console.error('Database listener error:', e);
        }
      });
    }

    /**
     * Export complete database as JSON string or Blob
     */
    exportJSON(pretty = true) {
      if (!currentData) this.init();
      return pretty ? JSON.stringify(currentData, null, 2) : JSON.stringify(currentData);
    }

    /**
     * Import JSON string into database
     */
    importJSON(jsonString) {
      try {
        const parsed = JSON.parse(jsonString);
        if (parsed && typeof parsed === 'object') {
          return this.replaceState(parsed);
        }
      } catch (e) {
        console.error('Failed to parse import JSON:', e);
        return false;
      }
      return false;
    }
  }

  return new DatabaseEngine();
}));