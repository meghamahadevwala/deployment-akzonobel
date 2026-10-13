import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getAIInsightFeatureFlags from '@salesforce/apex/AIDunningInsightsController.getAIInsightFeatureFlags';
import openAccountToView from '@salesforce/label/c.Open_Account_To_View';

/** Min width (px) for AI panel. */
const AI_PANEL_MIN_PX = 280;
/** Max width (px) for AI panel: fits 2 cards (280px each) + gap + padding; prevents blank space when sliding right. */
const AI_PANEL_MAX_PX = 610;
/** Min width (px) for metrics panel. */
const METRICS_PANEL_MIN_PX = 240;
const RESIZE_HANDLE_PX = 32;
const DEFAULT_AI_PERCENT = 40;

export default class AccountDashboard extends LightningElement {
  @api recordId;

  label = {
    openAccountToView
  };
  aiPanelPercent = DEFAULT_AI_PERCENT;
  showPaymentModal = false;
  showDunningModal = false;
  enableAIDunning = false;
  enableAIPaymentPrediction = false;
  /** RecordId passed to dunning modal when opened (from card event or effectiveRecordId). */
  dunningModalRecordId = null;
  _resizing = false;
  _mainEl = null;
  _boundMouseMove = null;
  _boundMouseUp = null;
  _initialPercentSet = false;

  @wire(CurrentPageReference)
  pageRef;

  @wire(getAIInsightFeatureFlags)
  wiredAIInsightFeatureFlags({ data, error }) {
    if (data) {
      this.enableAIDunning = data.enableAIDunning === true;
      this.enableAIPaymentPrediction = data.enableAIPaymentPrediction === true;
      return;
    }
    if (error) {
      this.enableAIDunning = false;
      this.enableAIPaymentPrediction = false;
      console.error('AccountDashboard: getAIInsightFeatureFlags failed', error?.body?.message ?? error?.message ?? error);
    }
  }

  /** Use recordId from props (App Builder) or from current page context (record page). */
  get effectiveRecordId() {
    return this.recordId || this.pageRef?.attributes?.recordId || null;
  }

  get mainGridStyle() {
    if (!this.showAiInsights) {
      return 'grid-template-columns: 1fr';
    }
    return `grid-template-columns: ${this.aiPanelPercent}% 32px 1fr`;
  }

  get showAiInsights() {
    return this.enableAIDunning || this.enableAIPaymentPrediction;
  }

  connectedCallback() {
    this._boundMouseMove = this._handleMouseMove.bind(this);
    this._boundMouseUp = this._handleMouseUp.bind(this);
  }

  disconnectedCallback() {
    this._removeResizeListeners();
  }

  renderedCallback() {
    if (!this.showAiInsights) return;
    if (this._initialPercentSet) return;
    const main = this.template.querySelector('.dashboard__main');
    if (!main) return;
    const total = main.getBoundingClientRect().width;
    if (total <= 0) return;
    const defaultWidth = total * (DEFAULT_AI_PERCENT / 100);
    const targetWidth = Math.min(AI_PANEL_MAX_PX, Math.max(AI_PANEL_MIN_PX, defaultWidth));
    const minPct = (AI_PANEL_MIN_PX / total) * 100;
    const maxFromMetrics = ((total - RESIZE_HANDLE_PX - METRICS_PANEL_MIN_PX) / total) * 100;
    const maxFromAiPanel = (AI_PANEL_MAX_PX / total) * 100;
    const maxPct = Math.min(maxFromMetrics, maxFromAiPanel);
    this.aiPanelPercent = Math.min(maxPct, Math.max(minPct, (targetWidth / total) * 100));
    this._initialPercentSet = true;
  }

  handleResizeStart() {
    this._resizing = true;
    this._mainEl = this.template.querySelector('.dashboard__main');
    document.addEventListener('mousemove', this._boundMouseMove);
    document.addEventListener('mouseup', this._boundMouseUp);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  }

  _handleMouseMove(e) {
    if (!this._resizing || !this._mainEl) return;
    const rect = this._mainEl.getBoundingClientRect();
    const total = rect.width;
    const pct = ((e.clientX - rect.left) / total) * 100;
    const minPct = total > 0 ? (AI_PANEL_MIN_PX / total) * 100 : 25;
    const maxFromMetrics = total > 0 ? ((total - RESIZE_HANDLE_PX - METRICS_PANEL_MIN_PX) / total) * 100 : 75;
    const maxFromAiPanel = total > 0 ? (AI_PANEL_MAX_PX / total) * 100 : 50;
    const maxPct = Math.min(maxFromMetrics, maxFromAiPanel);
    this.aiPanelPercent = Math.min(maxPct, Math.max(minPct, pct));
  }

  _handleMouseUp() {
    this._removeResizeListeners();
    document.body.style.cursor = '';
    document.body.style.userSelect = '';
    this._resizing = false;
    this._mainEl = null;
  }

  _removeResizeListeners() {
    document.removeEventListener('mousemove', this._boundMouseMove);
    document.removeEventListener('mouseup', this._boundMouseUp);
  }

  handlePaymentKnowMore() {
    this.showPaymentModal = true;
  }

  handleDunningKnowMore(event) {
    this.dunningModalRecordId = event.detail?.recordId ?? this.effectiveRecordId;
    this.showDunningModal = true;
  }

  handlePaymentModalClose() {
    this.showPaymentModal = false;
  }

  handleDunningModalClose() {
    this.showDunningModal = false;
  }
}