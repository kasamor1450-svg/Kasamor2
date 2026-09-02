/**
 * =========================================================================
 * AgroApp Cloud API & Supabase Client Adapter
 * Ù…Ø´Ø±ÙˆØ¹ Ø£Ø¨Ù†Ø§Ø¡ Ù…ØµØ·ÙÙ‰ Ø­Ø³Ù† Ø§Ù„Ø²Ø±Ø§Ø¹ÙŠ - Ø§Ù„Ù‚Ø¶Ø§Ø±Ù
 * Ù…Ø­Ø±Ùƒ Ø§Ù„Ø±Ø¨Ø· Ø§Ù„Ø³Ø­Ø§Ø¨ÙŠ Ø§Ù„Ù…Ø¨Ø§Ø´Ø± Ù…Ø¹ Supabase (PostgreSQL + Realtime + Storage)
 * =========================================================================
 */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.AgroAPI = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  
  async function waitForSupabaseCDN() {
    for (let i = 0; i < 40; i++) {
      if (typeof window !== 'undefined' && window.supabase && typeof window.supabase.createClient === 'function') {
        return true;
      }
      await new Promise(r => setTimeout(r, 100));
    }
    return (typeof window !== 'undefined' && window.supabase && typeof window.supabase.createClient === 'function');
  }
  
  const STORAGE_CONFIG_KEY = 'AGRO_SUPABASE_CLOUD_CONFIG';
  const DEFAULT_SUPABASE_URL = 'https://iuavmonqyvokldpvdqtm.supabase.co';
  const DEFAULT_SUPABASE_KEY = 'sb_publishable_62ldmJkE5F6DaEB1DipflQ_M1g0n57l';

  class SupabaseCloudAdapter {
    constructor() {
      this.client = null;
      this.url = '';
      this.anonKey = '';
      this.isConnected = false;
      this.realtimeChannel = null;
      this.listeners = [];
      this.loadConfig();
    }

    /**
     * Load stored credentials from LocalStorage
     */
    loadConfig() {
      try {
        const raw = localStorage.getItem(STORAGE_CONFIG_KEY);
        if (raw) {
          const cfg = JSON.parse(raw);
          if (cfg && cfg.url && cfg.anonKey) {
            this.url = cfg.url;
            this.anonKey = cfg.anonKey;
          }
        }
        if (!this.url || !this.anonKey) {
          this.url = DEFAULT_SUPABASE_URL;
          this.anonKey = DEFAULT_SUPABASE_KEY;
        }
        if (this.url && this.anonKey) {
          this.initClient(this.url, this.anonKey);
        }
      } catch (e) {
        console.warn('Could not load Supabase config:', e);
      }
    }

    /**
     * Save credentials and initialize
     */
    async saveConfig(url, anonKey) {
      this.url = (url || '').trim();
      this.anonKey = (anonKey || '').trim();
      localStorage.setItem(STORAGE_CONFIG_KEY, JSON.stringify({ url: this.url, anonKey: this.anonKey }));
      return await this.initClient(this.url, this.anonKey);
    }

    /**
     * Clear Supabase config
     */
    clearConfig() {
      this.url = '';
      this.anonKey = '';
      this.client = null;
      this.isConnected = false;
      localStorage.removeItem(STORAGE_CONFIG_KEY);
      this.notifyStatus(false, 'ØªÙ… ÙÙƒ Ø§Ù„Ø§Ø±ØªØ¨Ø§Ø· Ø§Ù„Ø³Ø­Ø§Ø¨ÙŠ');
    }

    /**
     * Initialize Supabase JS Client
     */
    async initClient(url, anonKey) {
      const finalUrl = (url || DEFAULT_SUPABASE_URL || '').trim();
      const finalKey = (anonKey || DEFAULT_SUPABASE_KEY || '').trim();
      this.url = finalUrl;
      this.anonKey = finalKey;

      if (!finalUrl || !finalKey) {
        this.isConnected = false;
        return { success: false, error: 'الرجاء إدخال الرابط والمفتاح' };
      }

      await waitForSupabaseCDN();

      try {
        if (typeof window !== 'undefined' && window.supabase && window.supabase.createClient) {
          this.client = window.supabase.createClient(url, anonKey, {
            global: {
              headers: {
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache'
              }
            }
          });
          // Test query
          const { data, error } = await this.client.from('farm_info').select('id, name').limit(1);
          if (error && error.code !== 'PGRST116') {
            console.warn('Supabase test query warning:', error);
          }
          this.isConnected = true;
          this.setupRealtimeSubscription();
          this.notifyStatus(true, 'Ù…ØªØµÙ„ Ø³Ø­Ø§Ø¨ÙŠØ§Ù‹ Ù…Ø¹ Supabase PostgreSQL');
          return { success: true, message: 'ØªÙ… Ø§Ù„Ø§ØªØµØ§Ù„ Ø§Ù„Ø³Ø­Ø§Ø¨ÙŠ Ø¨Ù†Ø¬Ø§Ø­!' };
        } else {
          return { success: false, error: 'Ù…ÙƒØªØ¨Ø© Supabase JS ØºÙŠØ± Ù…Ø­Ù…Ù„Ø©' };
        }
      } catch (err) {
        this.isConnected = false;
        console.error('Supabase connection failed:', err);
        return { success: false, error: err.message || 'ÙØ´Ù„ Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ù€ Supabase' };
      }
    }

    /**
     * Realtime Listeners for changes made by other 4 users
     */
    setupRealtimeSubscription() {
      if (!this.client || this.realtimeChannel) return;

      try {
        this.realtimeChannel = this.client
          .channel('agro-project-realtime')
          .on('postgres_changes', { event: '*', schema: 'public' }, (payload) => {
            console.log('âš¡ Realtime Cloud Event:', payload);
            this.notifyChange(payload);
          })
          .subscribe((status) => {
            console.log('âš¡ Realtime Subscription Status:', status);
          });
      } catch (e) {
        console.warn('Could not setup realtime channel:', e);
      }
    }

    /**
     * Subscribe to Realtime Data Changes
     */
    onDataChange(callback) {
      if (typeof callback === 'function') {
        this.listeners.push(callback);
      }
      return () => {
        this.listeners = this.listeners.filter(fn => fn !== callback);
      };
    }

    notifyChange(payload) {
      this.listeners.forEach(fn => {
        try { fn(payload); } catch (e) { console.error(e); }
      });
    }

    notifyStatus(status, message) {
      if (typeof window !== 'undefined' && window.updateCloudStatusIndicator) {
        window.updateCloudStatusIndicator(status, message);
      }
    }

    /**
     * Upload an invoice photo to Supabase Storage bucket 'invoices'
     */
    async uploadInvoicePhoto(file, expenseId) {
      if (!this.client) throw new Error('Supabase ØºÙŠØ± Ù…ØªØµÙ„');
      const ext = file.name ? file.name.split('.').pop() : 'jpg';
      const fileName = `receipt-${expenseId || Date.now()}-${Math.floor(Math.random()*1000)}.${ext}`;
      const filePath = `expenses/${fileName}`;

      const { data, error } = await this.client.storage
        .from('invoices')
        .upload(filePath, file, { cacheControl: '3600', upsert: true });

      if (error) throw error;

      const { data: urlData } = this.client.storage.from('invoices').getPublicUrl(filePath);
      return urlData.publicUrl;
    }

    /**
     * Fetch complete snapshot from PostgreSQL
     */
    async fetchCloudState() {
      if (!this.client) return null;
      try {
        const [
          farmInfoRes, usersRes, partnersRes, capitalInjRes,
          plotsRes, plotOpsRes, fuelTxRes, inventoryRes, inventoryTxRes,
          harvestRes, salesRes, machineryRes, laborRes,
          expensesRes, auditLogsRes
        ] = await Promise.all([
          this.client.from('farm_info').select('*').limit(1),
          this.client.from('users').select('*'),
          this.client.from('partners').select('*'),
          this.client.from('capital_injections').select('*'),
          this.client.from('plots').select('*'),
          this.client.from('plot_operations').select('*'),
          this.client.from('fuel_transactions').select('*').order('date', { ascending: false }),
          this.client.from('inventory_items').select('*'),
          this.client.from('inventory_transactions').select('*').order('date', { ascending: false }),
          this.client.from('harvest_intakes').select('*').order('date', { ascending: false }),
          this.client.from('crop_sales').select('*').order('date', { ascending: false }),
          this.client.from('machinery').select('*'),
          this.client.from('labor').select('*'),
          this.client.from('expenses').select('*').order('date', { ascending: false }),
          this.client.from('audit_logs').select('*').order('timestamp', { ascending: false }).limit(200)
        ]);

        const rawPlots = plotsRes.data || [];
        const rawOps = plotOpsRes.data || [];

        return {
          farmInfo: (farmInfoRes.data && farmInfoRes.data[0]) ? {
            name: farmInfoRes.data[0].name,
            location: farmInfoRes.data[0].location,
            totalArea: Number(farmInfoRes.data[0].total_area_feddan || 1450),
            seasonStart: farmInfoRes.data[0].season_start,
            seasonDurationMonths: farmInfoRes.data[0].season_duration_months || 6,
            currency: farmInfoRes.data[0].currency || 'جنيه سوداني'
          } : undefined,
          users: (usersRes.data || []).map(u => ({
          id: u.id,
          name: u.name,
          username: u.username,
          password: u.password_hash || u.password || 'Moh@2026',
          password_hash: u.password_hash || u.password || 'Moh@2026',
          role: u.role,
          roleTitle: u.role_title || u.roleTitle || 'عضو في الإدارة',
          phone: u.phone
        })),
          partners: (partnersRes.data || []).map(p => ({
            id: p.id, name: p.name, fullName: p.full_name,
            shares: p.shares, totalShares: p.total_shares,
            paidCapital: Number(p.paid_capital || 0), role: p.role, notes: p.notes
          })),
          capitalInjections: (capitalInjRes.data || []).map(ci => ({
            id: ci.id, partnerId: ci.partner_id, partnerName: ci.partner_name,
            date: ci.date, amount: Number(ci.amount || 0), paymentMethod: ci.payment_method,
            purpose: ci.purpose, loggedBy: ci.logged_by, notes: ci.notes,
            capitalType: (ci.notes && ci.notes.includes('[نوع: غير مسترد]')) ? 'non_refundable' : ((ci.notes && ci.notes.includes('[نوع: مسترد]')) ? 'refundable' : (ci.capital_type || 'refundable'))
          })),
          plots: rawPlots.map(pl => {
            const ops = rawOps
              .filter(op => op.plot_id === pl.id)
              .map(op => ({
                id: op.id,
                type: op.type,
                date: op.date,
                status: op.status,
                driver: op.driver,
                fuelBarrels: Number(op.fuel_barrels || 0),
                createdBy: op.created_by,
                notes: op.notes
              }));
            return {
              id: pl.id,
              name: pl.name,
              area: Number(pl.area_feddan || 0),
              areaFeddan: Number(pl.area_feddan || 0),
              crop: pl.crop,
              targetSowingDate: pl.target_sowing_date,
              prepFeddans: Number(pl.prep_feddans || 0),
              plantedFeddans: Number(pl.planted_feddans || 0),
              status: pl.status || 'active',
              operations: ops
            };
          }),
          fuelTransactions: (fuelTxRes.data || []).map(f => ({
            id: f.id, date: f.date, type: f.type, quantity: Number(f.quantity || 0),
            unit: f.unit || 'برميل', driver: f.driver, plot: f.plot,
            operationName: f.operation_name, op: f.operation_name,
            loggedBy: f.logged_by, notes: f.notes
          })),
          inventory: (inventoryRes.data || []).map(i => ({
            id: i.id, name: i.name, category: i.category,
            purchasedQty: Number(i.purchased_qty || 0),
            usedQty: Number(i.used_qty || 0),
            remainingQty: Number(i.remaining_qty || 0),
            unit: i.unit, unitPrice: Number(i.unit_price || 0),
            reorderLevel: Number(i.reorder_level || 0)
          })),
          inventoryTransactions: (inventoryTxRes.data || []).map(itx => ({
            id: itx.id, date: itx.date, itemId: itx.item_id, itemName: itx.item_name,
            category: itx.category, type: itx.type, quantity: Number(itx.quantity || 0),
            unit: itx.unit, unitPrice: Number(itx.unit_price || 0), totalCost: Number(itx.total_cost || 0),
            plot: itx.plot, crop: itx.crop, receiver: itx.receiver, loggedBy: itx.logged_by,
            notes: itx.notes, saleId: itx.sale_id
          })),
          harvestIntakes: (harvestRes.data || []).map(h => ({
            id: h.id, date: h.date, plot: h.plot, crop: h.crop,
            bags: Number(h.bags || 0), weightTons: Number(h.weight_tons || 0),
            storageLocation: h.storage_location, supervisor: h.supervisor,
            qualityGrade: h.quality_grade, notes: h.notes
          })),
          cropSales: (salesRes.data || []).map(s => ({
            id: s.id, date: s.date, buyerName: s.buyer_name, crop: s.crop,
            bags: Number(s.bags || 0), pricePerBag: Number(s.price_per_bag || 0),
            totalAmount: Number(s.total_amount || 0), paidAmount: Number(s.paid_amount || 0),
            remainingAmount: Number(s.remaining_amount || 0), paymentMethod: s.payment_method,
            deliveryLocation: s.delivery_location, status: s.status,
            loggedBy: s.logged_by, notes: s.notes
          })),
          machinery: (machineryRes.data || []).map(m => ({
            id: m.id, name: m.name, type: m.type, plate: m.plate, driver: m.driver,
            status: m.status, hoursOperated: Number(m.hours_operated || 0),
            oilChangeDueHours: Number(m.oil_change_due_hours || 0), fuelTankCapacity: Number(m.fuel_tank_capacity || 0),
            feddanDone: Number(m.feddan_done || 0), fuelUsedBarrels: Number(m.fuel_used_barrels || 0)
          })),
          labor: (laborRes.data || []).map(l => ({
            id: l.id, name: l.name, role: l.role, workerType: l.worker_type,
            startDate: l.start_date, endDate: l.end_date, monthlySalary: Number(l.monthly_salary || 0),
            daysWorked: Number(l.days_worked || 0), monthsWorked: Number(l.months_worked || 0),
            deductionsAmount: Number(l.deductions_amount || 0), overtime: Number(l.overtime || 0),
            totalDue: Number(l.total_due || 0), totalPaid: Number(l.total_paid || 0),
            status: l.status, task: l.task, plot: l.plot, crop: l.crop,
            areaFeddan: Number(l.area_feddan || 0), lastUpdatedBy: l.last_updated_by
          })),
          expenses: (expensesRes.data || []).map(e => ({
            id: e.id, date: e.date, category: e.category, amount: Number(e.amount || 0),
            plot: e.plot, crop: e.crop, op: e.op || e.notes, isUnderReview: !!e.is_under_review,
            createdBy: e.created_by, modifiedBy: e.modified_by, receiptPhotoUrl: e.receipt_photo_url, notes: e.notes
          })),
          auditLogs: (auditLogsRes.data || []).map(a => ({
            id: a.id, timestamp: a.timestamp, action: a.action, details: a.details,
            section: a.section, userName: a.user_name
          }))
        };
      } catch (err) {
        console.error('Failed to fetch snapshot from Supabase:', err);
        return null;
      }
    }

    /**
     * High-level CRUD operations against Supabase
     */
    async insertExpense(exp) {
      if (!this.client) return null;
      const row = {
        id: exp.id, date: exp.date, category: exp.category, amount: exp.amount,
        plot: exp.plot, crop: exp.crop, op: exp.op || exp.notes, is_under_review: !!exp.isUnderReview,
        created_by: exp.createdBy, modified_by: exp.modifiedBy || null,
        notes: exp.notes, receipt_photo_url: exp.receiptPhotoUrl || null
      };
      const { data, error } = await this.client.from('expenses').upsert(row).select().single();
      if (error) console.warn('Supabase insert expense warning:', error);
      return data;
    }

    async updateUserCredentials(userId, newUsername, newPassword) {
      if (!this.client) return { success: false, error: 'No client' };
      try {
        const { data, error } = await this.client
          .from('users')
          .update({
            username: newUsername,
            password_hash: newPassword
          })
          .eq('id', userId);
        if (error) throw error;
        return { success: true };
      } catch (err) {
        console.error('Supabase update user credentials error:', err);
        return { success: false, error: err.message };
      }
    },

    async updateExpense(id, exp) {
      if (!this.client) return null;
      const row = {
        date: exp.date, category: exp.category, amount: exp.amount,
        plot: exp.plot, crop: exp.crop, op: exp.op || exp.notes, is_under_review: !!exp.isUnderReview,
        modified_by: exp.modifiedBy, notes: exp.notes, receipt_photo_url: exp.receiptPhotoUrl || null
      };
      const { data, error } = await this.client.from('expenses').update(row).eq('id', id);
      if (error) console.warn('Supabase update expense warning:', error);
      return data;
    }

    async deleteExpense(id) {
      if (!this.client) return null;
      const { data, error } = await this.client.from('expenses').delete().eq('id', id);
      if (error) console.warn('Supabase delete expense warning:', error);
      return !error;
    }

    async insertHarvest(h) {
      if (!this.client) return null;
      const row = {
        id: h.id, date: h.date, plot: h.plot, crop: h.crop, bags: h.bags,
        weight_tons: h.weightTons, storage_location: h.storageLocation,
        supervisor: h.supervisor, quality_grade: h.qualityGrade, notes: h.notes
      };
      return await this.client.from('harvest_intakes').upsert(row);
    }

    async insertSale(s) {
      if (!this.client) return null;
      const row = {
        id: s.id, date: s.date, buyer_name: s.buyerName, crop: s.crop,
        bags: s.bags, price_per_bag: s.pricePerBag, total_amount: s.totalAmount,
        paid_amount: s.paidAmount, remaining_amount: s.remainingAmount,
        payment_method: s.paymentMethod, delivery_location: s.deliveryLocation,
        status: s.status, logged_by: s.loggedBy, notes: s.notes
      };
      return await this.client.from('crop_sales').upsert(row);
    }

    async insertFuelTx(f) {
      if (!this.client) return null;
      const row = {
        id: f.id, date: f.date, type: f.type, quantity: f.quantity,
        unit: f.unit || 'برميل', driver: f.driver, plot: f.plot,
        operation_name: f.operationName || f.op, logged_by: f.loggedBy, notes: f.notes
      };
      return await this.client.from('fuel_transactions').upsert(row);
    }
  }

  return new SupabaseCloudAdapter();
}));