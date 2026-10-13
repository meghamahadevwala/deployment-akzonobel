import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import getDunningInsights from '@salesforce/apex/AIDunningInsightsController.getDunningInsights';
import refreshDunningInsights from '@salesforce/apex/AIDunningInsightsController.refreshDunningInsights';
import updateDunningStrategy from '@salesforce/apex/AIDunningInsightsController.updateDunningStrategy';
import labelDunningStrategyDiagnosisTitle from '@salesforce/label/c.Dunning_Strategy_Diagnosis_Title';
import labelAIPoweredCollectionStrategyAnalysis from '@salesforce/label/c.AI_Powered_Collection_Strategy_Analysis';
import labelLastUpdated from '@salesforce/label/c.Last_Updated';
import labelRefresh from '@salesforce/label/c.Refresh';
import labelRecalculationStarted from '@salesforce/label/c.Recalculation_Started';
import labelRecalcBanner from '@salesforce/label/c.Dunning_Efficiency_Recalculation_Banner';
import labelPaymentCycleHelptext from '@salesforce/label/c.Payment_Cycle_Helptext';
import labelAverageDaysPastDue from '@salesforce/label/c.Average_Days_Past_Due';
import labelAverageDPDHelptext from '@salesforce/label/c.Average_DPD_Helptext';
import labelBusinessScale from '@salesforce/label/c.Business_Scale';
import labelBusinessScaleHelptext from '@salesforce/label/c.Business_Scale_Helptext';
import labelDunningEfficiency from '@salesforce/label/c.Dunning_Efficiency';
import labelDunningAnalysis from '@salesforce/label/c.Dunning_Analysis';
import labelDunningFrequency from '@salesforce/label/c.Dunning_Frequency';
import labelDunningStrategy from '@salesforce/label/c.Dunning_Strategy';
import labelReminderFrequency from '@salesforce/label/c.Reminder_Frequency';
import labelRiskOfOverdueInvoices from '@salesforce/label/c.Risk_Of_Overdue_Invoices';
import labelAIRecommendedStrategyHelptext from '@salesforce/label/c.AI_Recommended_Strategy_Helptext';
import labelAligned from '@salesforce/label/c.Aligned';
import labelInsufficientDunningObserved from '@salesforce/label/c.Insufficient_Dunning_Observed';
import labelInsufficientDunningDetected from '@salesforce/label/c.Insufficient_Dunning_Detected';
import labelExcessiveDunningObserved from '@salesforce/label/c.Excessive_Dunning_Observed';
import labelExcessiveDunningDetected from '@salesforce/label/c.Excessive_Dunning_Detected';
import labelDEIAlignedDesc from '@salesforce/label/c.DEI_Aligned_Desc';
import labelNA from '@salesforce/label/c.NA';
import labelIrregularPaymentCycle from '@salesforce/label/c.Irregular_Payment_Cycle';
import labelWeakPaymentCycles from '@salesforce/label/c.Weak_Payment_Cycles';
import labelPaymentCycles from '@salesforce/label/c.Payment_Cycles';
import labelNever from '@salesforce/label/c.Never';
import labelJustNow from '@salesforce/label/c.Just_Now';
import labelYesterday from '@salesforce/label/c.Yesterday';
import labelCheckUpdatedInsights from '@salesforce/label/c.Check_Updated_Insights';
import labelAIInsightsRefreshedRecently from '@salesforce/label/c.AI_Insights_Refreshed_Recently';
import labelRefreshAIInsights from '@salesforce/label/c.Refresh_AI_Insights';
import labelConfirmDunningStrategyChange from '@salesforce/label/c.Confirm_Dunning_Strategy_Change';
import labelStandardStrategy from '@salesforce/label/c.Standard_Strategy';
import labelAIRecommendedStrategy from '@salesforce/label/c.AI_Recommended_Strategy';
import labelTimely from '@salesforce/label/c.Timely_Followup';
import labelTooFew from '@salesforce/label/c.Too_Few_Reminders';
import labelExcessiveVolume from '@salesforce/label/c.Excessive_Reminder_Volume';
import labelSpacedTooFar from '@salesforce/label/c.Reminders_Spaced_Too_Far';
import labelTooFrequent from '@salesforce/label/c.Reminders_Too_Frequent';
import labelNotAligned from '@salesforce/label/c.Reminders_Not_Aligned';
import labelRemindersAligned from '@salesforce/label/c.Reminders_Aligned';
import labelMissedPreventive from '@salesforce/label/c.Missed_Preventive_Reminders';
import labelPreDueAggressive from '@salesforce/label/c.PreDue_Reminders_Aggressive';
import labelOverall from '@salesforce/label/c.Overall';
import labelAIDunningEfficiency from '@salesforce/label/c.AI_Dunning_Efficiency';
import labelStandardRuleEfficiency from '@salesforce/label/c.Standard_Rule_Efficiency';
import labelAIDunningEfficiencyEmpty from '@salesforce/label/c.AI_Dunning_Efficiency_Empty';
import labelStandardRuleEfficiencyEmpty from '@salesforce/label/c.Standard_Rule_Efficiency_Empty';

const TREND_DATA = [
  { key: '1', month: 'Sep-25', dunningFreq: 30, dso: 58, recommendedFreq: 7 },
  { key: '2', month: 'Oct-25', dunningFreq: 28, dso: 55, recommendedFreq: 7 },
  { key: '3', month: 'Nov-25', dunningFreq: 32, dso: 62, recommendedFreq: 7 },
  { key: '4', month: 'Dec-25', dunningFreq: 29, dso: 54, recommendedFreq: 7 },
  { key: '5', month: 'Jan-26', dunningFreq: 30, dso: 59, recommendedFreq: 7 },
  { key: '6', month: 'Feb-26', dunningFreq: 31, dso: 61, recommendedFreq: 7 },
];

const RECOMMENDATION_TREND_DATA = [
  { key: '1', month: 'Sep-25', strategy: 'Proactive', riskReduction: 85, recommendedFreq: 7 },
  { key: '2', month: 'Oct-25', strategy: 'Proactive', riskReduction: 82, recommendedFreq: 7 },
  { key: '3', month: 'Nov-25', strategy: 'Proactive', riskReduction: 88, recommendedFreq: 7 },
  { key: '4', month: 'Dec-25', strategy: 'Proactive', riskReduction: 84, recommendedFreq: 7 },
  { key: '5', month: 'Jan-26', strategy: 'Proactive', riskReduction: 86, recommendedFreq: 7 },
  { key: '6', month: 'Feb-26', strategy: 'Proactive', riskReduction: 87, recommendedFreq: 7 },
];

export default class DunningInsightsModal extends LightningElement {
  @api isOpen = false;
  @api recordId;

  standardEnabled = false;
  recommendedEnabled = false;
  enableDunningEfficiency = false;
  enableAIDunning = false;
  lastInsightDate = null;
  isRefreshing = false;
  isLoading = true;
  /** True when refresh started TransactionMetricsBatch; show "calculation in progress" message. */
  calculationInProgress = false;

  standardReminderFrequency = null;
  dunningEfficiencyTag = null;
  performanceEfficiencyPct = null;
  performanceImpactText = null;
  deiValue = null;

  /** AI Recommended column: same shape as aiDunningInsights recommendedStrategy */
  recommendedStrategy = { strategy: null, reminderFrequency: null, overdueRisk: null, enabledDate: null };

  kpiPaymentCycles = [];
  kpiPredictedPayment = '--';
  kpiDpd = '--';
  kpiBusinessSize = null;

  label = {
      dunningStrategyDiagnosisTitle: labelDunningStrategyDiagnosisTitle,
      aiPoweredCollectionStrategyAnalysis: labelAIPoweredCollectionStrategyAnalysis,
      lastUpdated: labelLastUpdated,
      refresh: labelRefresh,
      recalcBanner: labelRecalcBanner,
      paymentCycleHelptext: labelPaymentCycleHelptext,
      averageDaysPastDue: labelAverageDaysPastDue,
      averageDPDHelptext: labelAverageDPDHelptext,
      businessScale: labelBusinessScale,
      businessScaleHelptext: labelBusinessScaleHelptext,
      dunningEfficiency: labelDunningEfficiency,
      dunningFrequency: labelDunningFrequency,
      aiRecommendedStrategy: labelAIRecommendedStrategy,
      aiRecommendedStrategyHelptext: labelAIRecommendedStrategyHelptext,
      dunningStrategy: labelDunningStrategy,
      reminderFrequency: labelReminderFrequency,
      riskOfOverdueInvoices: labelRiskOfOverdueInvoices,
      overall: labelOverall,
      aiDunningEfficiency: labelAIDunningEfficiency,
      standardRuleEfficiency: labelStandardRuleEfficiency,
      aiDunningEfficiencyEmpty: labelAIDunningEfficiencyEmpty,
      standardRuleEfficiencyEmpty: labelStandardRuleEfficiencyEmpty,
      dunningAnalysis: labelDunningAnalysis,
  };
  
  kpiPrimaryCycleScore = null;
  kpiSecondaryCycleScore = null;

  standardIssues = [];
  selectedEfficiencyTab = 'overall';

  aiDunningDeiValue = null;
  aiDunningEfficiencyTag = null;
  aiDunningIssues = [];

  stdRuleDeiValue = null;
  stdRuleEfficiencyTag = null;
  standardRuleIssues = [];

  trendData = TREND_DATA;
  recommendationTrendData = RECOMMENDATION_TREND_DATA;

  get isStandardSelected() {
    return this.standardEnabled;
  }

  get isAiSelected() {
    return this.recommendedEnabled;
  }

  get isReactiveStrategy() {
    const s = this.recommendedStrategy?.strategy;
    return s != null && s.toLowerCase() === 'reactive';
  }

  get isProactiveStrategy() {
    const s = this.recommendedStrategy?.strategy;
    return s != null && s.toLowerCase() === 'proactive';
  }

  get _reminderFreqDays() {
    const freq = this.recommendedStrategy?.reminderFrequency;
    if (freq == null) return null;
    const num = parseInt(String(freq), 10);
    return Number.isNaN(num) ? null : num;
  }

  get showBenefitPoints() {
    return this.isProactiveStrategy || this.isReactiveStrategy;
  }

  get benefit1Title() {
    if (this.isReactiveStrategy) return 'Payment Run Aligned Outreaches';
    return 'Increased Reminder Frequency';
  }

  get benefit1Points() {
    if (this.isReactiveStrategy) {
      return [
        'Reminders timed to the customer\'s payment run cycle to maximise response rate; Outreach only when payment action is less likely',
      ];
    }
    const freq = this._reminderFreqDays;
    const freqLabel = freq != null && freq <= 14 ? `every ${freq} days` : 'at a proactive cadence';
    return [
      'Keeps open invoices top-of-mind before they age further; Cadence is calibrated to the account\'s delay in payment',
    ];
  }

  get benefit2Title() {
    if (this.isReactiveStrategy) return 'Curated as needed Outreach';
    return 'Multiple Touchpoints Strategy';
  }

  get benefit1Point() {
    return this.benefit1Points[0] || '';
  }

  get benefit2Point() {
    return this.benefit2Points[0] || '';
  }

  get benefit2Points() {
    if (this.isReactiveStrategy) {
      return [
        'well-timed reminder as per payment cycle — prevents customer fatigue',
        'Focused touchpoint maintains collection pressure without over-communicating',
      ];
    }
    return [
      'AI recommends reminders as per invoice aging and risk level for consistent follow-up',
      'Persistent professional outreach reduces DSO without increasing customer friction',
    ];
  }

  get showReminderFrequency() {
    return this.recommendedStrategy?.reminderFrequency && !this.isReactiveStrategy;
  }

  get aiCardsClass() {
    return this.showReminderFrequency ? 'ai-cards' : 'ai-cards ai-cards--single';
  }

  get formattedAiEnabledDate() {
    const dt = this.recommendedStrategy?.enabledDate;
    if (!dt) return null;
    const d = new Date(dt);
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
    return d.toLocaleDateString(undefined, options);
  }

  get isDataReady() {
    return !this.isLoading;
  }

  get showDunningEfficiency() {
    return this.enableDunningEfficiency;
  }

  get showAIRecommended() {
    return this.enableAIDunning;
  }

  // ── Efficiency Tab Management ──

  get efficiencyTabs() {
    const active = this.selectedEfficiencyTab;
    return [
      {
        key: 'overall',
        label: this.label.overall,
        className: active === 'overall' ? 'eff-tab eff-tab--active' : 'eff-tab',
      },
      {
        key: 'aiDunning',
        label: this.label.aiDunningEfficiency,
        className: active === 'aiDunning' ? 'eff-tab eff-tab--active' : 'eff-tab',
      },
      {
        key: 'standardRule',
        label: this.label.standardRuleEfficiency,
        className: active === 'standardRule' ? 'eff-tab eff-tab--active' : 'eff-tab',
      },
    ];
  }

  get isOverallTab() {
    return this.selectedEfficiencyTab === 'overall';
  }

  get isAiDunningTab() {
    return this.selectedEfficiencyTab === 'aiDunning';
  }

  get isStandardRuleTab() {
    return this.selectedEfficiencyTab === 'standardRule';
  }

  handleEfficiencyTabChange(event) {
    this.selectedEfficiencyTab = event.currentTarget.dataset.tab;
  }

  // ── AI Dunning Efficiency getters ──

  get hasAiEfficiencyData() {
    return this.aiDunningDeiValue != null || this.aiDunningEfficiencyTag != null;
  }

  get hasAiDeiInsight() {
    return this.aiDunningDeiValue != null || this.aiDunningEfficiencyTag != null;
  }

  get _isAiDeiError() {
    if (this.aiDunningDeiValue == null) {
      const tag = (this.aiDunningEfficiencyTag || '').toLowerCase();
      return tag.includes('under') || tag.includes('over');
    }
    return this.aiDunningDeiValue < -0.25 || this.aiDunningDeiValue > 0.25;
  }

  get aiDeiTag() {
    if (this.aiDunningDeiValue == null) return this.aiDunningEfficiencyTag || labelDunningEfficiency;
    const dei = this.aiDunningDeiValue;
    if (dei >= -0.25 && dei <= 0.25) return labelAligned;
    if (dei > -0.75 && dei < -0.25) return labelInsufficientDunningObserved;
    if (dei <= -0.75) return labelInsufficientDunningDetected;
    if (dei > 0.25 && dei < 0.75) return labelExcessiveDunningObserved;
    return labelExcessiveDunningDetected;
  }

  get aiDeiDescription() {
    if (this.aiDunningDeiValue == null) return '';
    const dei = this.aiDunningDeiValue;
    const absPct = Math.round(Math.abs(dei) * 100);
    if (dei >= -0.25 && dei <= 0.25) return labelDEIAlignedDesc;
    if (dei > -0.75 && dei < -0.25)
      return `Insufficient Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as follow-up may be too light for delayed payments.`;
    if (dei <= -0.75)
      return `Insufficient Dunning detected with High Ineffectiveness (${absPct}%) as collection effort may be significantly low for high payment delays.`;
    if (dei > 0.25 && dei < 0.75)
      return `Excessive Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as collection reminder frequency found to be higher than needed given the customer's payment behavior.`;
    return `Excessive Dunning detected with High Ineffectiveness (${absPct}%) as collection pressure may be substantially higher than required given the customer's payment behavior.`;
  }

  get aiDeiAlertClass() {
    return this._isAiDeiError ? 'alert-box alert-amber' : 'alert-box alert-green';
  }

  get aiDeiIconName() {
    return this._isAiDeiError ? 'utility:warning' : 'utility:success';
  }

  get aiDeiIconClass() {
    return this._isAiDeiError ? 'icon-amber' : 'icon-green';
  }

  // ── Standard Rule Efficiency getters ──

  get hasStandardEfficiencyData() {
    return this.stdRuleDeiValue != null || this.stdRuleEfficiencyTag != null;
  }

  get hasStdDeiInsight() {
    return this.stdRuleDeiValue != null || this.stdRuleEfficiencyTag != null;
  }

  get _isStdDeiError() {
    if (this.stdRuleDeiValue == null) {
      const tag = (this.stdRuleEfficiencyTag || '').toLowerCase();
      return tag.includes('under') || tag.includes('over');
    }
    return this.stdRuleDeiValue < -0.25 || this.stdRuleDeiValue > 0.25;
  }

  get stdDeiTag() {
    if (this.stdRuleDeiValue == null) return this.stdRuleEfficiencyTag || labelDunningEfficiency;
    const dei = this.stdRuleDeiValue;
    if (dei >= -0.25 && dei <= 0.25) return labelAligned;
    if (dei > -0.75 && dei < -0.25) return labelInsufficientDunningObserved;
    if (dei <= -0.75) return labelInsufficientDunningDetected;
    if (dei > 0.25 && dei < 0.75) return labelExcessiveDunningObserved;
    return labelExcessiveDunningDetected;
  }

  get stdDeiDescription() {
    if (this.stdRuleDeiValue == null) return '';
    const dei = this.stdRuleDeiValue;
    const absPct = Math.round(Math.abs(dei) * 100);
    if (dei >= -0.25 && dei <= 0.25) return labelDEIAlignedDesc;
    if (dei > -0.75 && dei < -0.25)
      return `Insufficient Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as follow-up may be too light for delayed payments.`;
    if (dei <= -0.75)
      return `Insufficient Dunning detected with High Ineffectiveness (${absPct}%) as collection effort may be significantly low for high payment delays.`;
    if (dei > 0.25 && dei < 0.75)
      return `Excessive Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as collection reminder frequency found to be higher than needed given the customer's payment behavior.`;
    return `Excessive Dunning detected with High Ineffectiveness (${absPct}%) as collection pressure may be substantially higher than required given the customer's payment behavior.`;
  }

  get stdDeiAlertClass() {
    return this._isStdDeiError ? 'alert-box alert-amber' : 'alert-box alert-green';
  }

  get stdDeiIconName() {
    return this._isStdDeiError ? 'utility:warning' : 'utility:success';
  }

  get stdDeiIconClass() {
    return this._isStdDeiError ? 'icon-amber' : 'icon-green';
  }

  get hasDeiInsight() {
    return this.deiValue != null || this.dunningEfficiencyTag != null;
  }

  get isDeiError() {
    if (this.deiValue == null) {
      const tag = (this.dunningEfficiencyTag || '').toLowerCase();
      return tag.includes('under') || tag.includes('over');
    }
    return this.deiValue < -0.25 || this.deiValue > 0.25;
  }

  get deiTag() {
    if (this.deiValue == null) return this.dunningEfficiencyTag || labelDunningEfficiency;
    const dei = this.deiValue;
    if (dei >= -0.25 && dei <= 0.25) return labelAligned;
    if (dei > -0.75 && dei < -0.25) return labelInsufficientDunningObserved;
    if (dei <= -0.75) return labelInsufficientDunningDetected;
    if (dei > 0.25 && dei < 0.75) return labelExcessiveDunningObserved;
    return labelExcessiveDunningDetected;
  }

  get deiDescription() {
    if (this.deiValue == null) return this.performanceImpactText || '';
    const dei = this.deiValue;
    const absPct = Math.round(Math.abs(dei) * 100);
    if (dei >= -0.25 && dei <= 0.25) {
      return labelDEIAlignedDesc;
    }
    if (dei > -0.75 && dei < -0.25) {
      return `Insufficient Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as follow-up may be too light for delayed payments.`;
    }
    if (dei <= -0.75) {
      return `Insufficient Dunning detected with High Ineffectiveness (${absPct}%) as collection effort may be significantly low for high payment delays.`;
    }
    if (dei > 0.25 && dei < 0.75) {
      return `Excessive Dunning observed, indicating Moderate Ineffectiveness (${absPct}%) as collection reminder frequency found to be higher than needed given the customer's payment behavior.`;
    }
    return `Excessive Dunning detected with High Ineffectiveness (${absPct}%) as collection pressure may be substantially higher than required given the customer's payment behavior.`;
  }

  get deiAlertClass() {
    return this.isDeiError ? 'alert-box alert-amber' : 'alert-box alert-green';
  }

  get deiIconName() {
    return this.isDeiError ? 'utility:warning' : 'utility:success';
  }

  get deiIconClass() {
    return this.isDeiError ? 'icon-amber' : 'icon-green';
  }

  get kpiBusinessSizeDisplay() {
    return this.kpiBusinessSize || labelNA;
  }

  get _maxCycleScore() {
    const scores = [this.kpiPrimaryCycleScore, this.kpiSecondaryCycleScore].filter(s => s != null);
    if (scores.length === 0) return null;
    return Math.max(...scores);
  }

  get kpiCycleTitle() {
    if (!this.kpiPaymentCycles || this.kpiPaymentCycles.length === 0) return labelIrregularPaymentCycle;
    const maxScore = this._maxCycleScore;
    if (maxScore == null) return labelIrregularPaymentCycle;
    return maxScore < 50 ? labelWeakPaymentCycles : labelPaymentCycles;
  }

  get kpiCycleTitleClass() {
    const maxScore = this._maxCycleScore;
    if (maxScore == null) return 'kpi-card__label kpi-card__label-warn';
    return maxScore < 50 ? 'kpi-card__label kpi-card__label-warn' : 'kpi-card__label';
  }

  get strategyGridClass() {
    if (this.showDunningEfficiency && this.showAIRecommended) return 'strategy-grid';
    return 'strategy-grid strategy-grid-single';
  }

  get standardColumnClass() {
    return this.standardEnabled ? 'strategy-col strategy-col-selected' : 'strategy-col';
  }

  get aiColumnClass() {
    return this.recommendedEnabled ? 'strategy-col strategy-col-ai strategy-col-selected' : 'strategy-col strategy-col-ai';
  }

  get selectedStrategyLabel() {
    return this.recommendedEnabled ? labelAIRecommendedStrategy : labelStandardStrategy;
  }

  get hasLastInsightDate() {
    return !!this.lastInsightDate;
  }

  get relativeTimeLabel() {
    if (!this.lastInsightDate) return labelNever;
    const dt = new Date(this.lastInsightDate);
    const now = new Date();
    const diffMs = now - dt;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHr = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHr / 24);

    if (diffSec < 60) return labelJustNow;
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHr < 24) return `${diffHr}h ago`;
    if (diffDay === 1) return labelYesterday;
    return dt.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  }

  get isWithin24Hours() {
    if (!this.lastInsightDate) return false;
    const dt = new Date(this.lastInsightDate);
    const now = new Date();
    return (now - dt) < 24 * 60 * 60 * 1000;
  }

  /** Disable when refreshing. When calculation is in progress, allow refresh to poll for updated data. */
  get isRefreshDisabled() {
    return this.isRefreshing || (!this.calculationInProgress && this.isWithin24Hours);
  }

  get refreshTitle() {
    if (this.calculationInProgress) return labelCheckUpdatedInsights;
    if (this.isWithin24Hours) return labelAIInsightsRefreshedRecently;
    return labelRefreshAIInsights;
  }

  get refreshIconClass() {
    return this.isRefreshing ? 'refresh-icon refresh-icon--spinning' : 'refresh-icon';
  }

  // handleRefresh() {
  //   if (this.isRefreshing) return;
  //   // If calculation already in progress, poll for updated data (don't start another batch).
  //   const startBatch = !this.calculationInProgress && !this.isWithin24Hours;
  //   if (!startBatch && !this.calculationInProgress) return;
  //   this.isRefreshing = true;
  //   this._loadData(startBatch);
  // }

  get _riskPct() {
    const v = this.recommendedStrategy?.overdueRisk;
    if (v == null || v === '') return 0;
    const num = typeof v === 'string' ? parseFloat(String(v).replace('%', '')) : Number(v);
    return Number.isNaN(num) ? 0 : Math.min(100, Math.max(0, num));
  }

  /** 0-30 = green (low risk), 31-60 = amber (medium), 61-100 = red (high) */
  get _riskLevel() {
    const pct = this._riskPct;
    if (pct <= 30) return 'low';
    if (pct <= 60) return 'mid';
    return 'high';
  }

  get recommendedRiskBarStyle() {
    return `width: ${this._riskPct}%`;
  }

  get riskBoxClass() {
    const level = this._riskLevel;
    if (level === 'high') return 'risk-box risk-box-red';
    if (level === 'mid') return 'risk-box risk-box-amber';
    return 'risk-box risk-box-green';
  }

  get riskValueClass() {
    const level = this._riskLevel;
    if (level === 'high') return 'risk-box__value risk-box__value-red';
    if (level === 'mid') return 'risk-box__value risk-box__value-amber';
    return 'risk-box__value risk-box__value-green';
  }

  get riskBarTrackClass() {
    const level = this._riskLevel;
    if (level === 'high') return 'risk-box__bar risk-box__bar-red';
    if (level === 'mid') return 'risk-box__bar risk-box__bar-amber';
    return 'risk-box__bar risk-box__bar-green';
  }

  get riskBarFillClass() {
    const level = this._riskLevel;
    if (level === 'high') return 'risk-box__bar-fill risk-box__bar-fill-red';
    if (level === 'mid') return 'risk-box__bar-fill risk-box__bar-fill-amber';
    return 'risk-box__bar-fill risk-box__bar-fill-green';
  }

  /** When modal opens with recordId, load data. Re-load when recordId changes while open (sync with parent). */
  _isOpenPrev = false;
  _lastLoadedRecordId = null;

  renderedCallback() {
    if (this.isOpen && this.recordId && this._lastLoadedRecordId !== this.recordId) {
      this._loadData();
    }
    if (this.isOpen && !this._isOpenPrev) {
      document.body.style.overflow = 'hidden';
    } else if (!this.isOpen && this._isOpenPrev) {
      document.body.style.overflow = '';
    }
    if (!this.isOpen) {
      this._lastLoadedRecordId = null;
      this.isLoading = true;
    }
    this._isOpenPrev = this.isOpen;
  }

  disconnectedCallback() {
    document.body.style.overflow = '';
  }

  /**
   * Same logic as aiDunningInsights/dunningInsightsCard: build insights from dunningEfficiencyResult metrics.
   */
  _generateDunningInsights(rar, rur, car, prar, prur, countR, freqR, paymentR, preDueCountR, dueDateR) {
    const insights = [];
    rar = parseFloat(rar) || 0;
    rur = parseFloat(rur) || 0;
    car = parseFloat(car) || 0;
    prar = parseFloat(prar) || 0;
    prur = parseFloat(prur) || 0;
    const absRur = Math.abs(rur);
    const absCar = Math.abs(car);
    const absPrar = Math.abs(prar);
    const absPrur = Math.abs(prur);

    if (absRur <= 0.25) {
      insights.push({ index: 1, type: 'success', isError: false, message: labelTimely, desc: countR });
    } else if (rur <= -0.25) {
      insights.push({ index: 1, type: 'error', isError: true, message: labelTooFew, desc: countR });
    } else if (rur >= 0.25) {
      insights.push({ index: 1, type: 'error', isError: true, message: labelExcessiveVolume, desc: countR });
    }

    if (absRur >= 0.25) {
      if (rar <= -0.25) insights.push({ index: 2, type: 'error', isError: true, message: labelSpacedTooFar, desc: freqR });
      else if (rar >= 0.25) insights.push({ index: 2, type: 'error', isError: true, message: labelTooFrequent, desc: freqR });
    }

    if (rur <= -0.25) {
      insights.push({ index: 3, type: 'error', isError: true, message: labelNotAligned, desc: paymentR });
    } else if (absCar >= 0.25) {
      insights.push({ index: 3, type: 'error', isError: true, message: labelNotAligned, desc: paymentR });
    } else if (absCar < 0.25) {
      insights.push({ index: 3, type: 'success', isError: false, message: labelRemindersAligned, desc: paymentR });
    }

    if (absPrar >= 0.25 && absPrur >= 0.25) {
      if (prur <= -0.25) insights.push({ index: 4, type: 'error', isError: true, message: labelMissedPreventive, desc: preDueCountR });
      else if (prar >= 0.25 || prur >= 0.25) insights.push({ index: 4, type: 'error', isError: true, message: labelPreDueAggressive, desc: preDueCountR });
    }

    const seen = new Set();
    return insights
      .filter((i) => {
        const key = `${i.index}-${i.message}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      })
      .sort((a, b) => a.index - b.index);
  }

  _loadData(isRefresh = false) {
    if (!this.recordId) return;
    this.isLoading = true;
    const apexMethod = isRefresh ? refreshDunningInsights : getDunningInsights;
    apexMethod({ accountId: this.recordId })
      .then((data) => {
        this.calculationInProgress = data?.calculationInProgress ?? false;
        if (this.calculationInProgress) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: labelRecalculationStarted,
              message: labelRecalcBanner,
              variant: 'info',
            })
          );
        }
        this.enableDunningEfficiency = data?.enableDunningEfficiency ?? false;
        this.enableAIDunning = data?.enableAIDunning ?? false;
        this.standardEnabled = data?.standardStrategy?.enabled ?? false;
        this.recommendedEnabled = data?.recommendedStrategy?.enabled ?? false;

        const pb = data?.paymentBehaviour || {};
        this.kpiPaymentCycles = pb.paymentCycles || [];
        this.kpiPredictedPayment = pb.predictedPayment || labelNA;
        this.kpiDpd = pb.dpd || '--';
        this.kpiBusinessSize = pb.businessSize || null;
        this.kpiPrimaryCycleScore = pb.primaryCycleScore != null ? pb.primaryCycleScore : null;
        this.kpiSecondaryCycleScore = pb.secondaryCycleScore != null ? pb.secondaryCycleScore : null;

        const standard = data?.standardStrategy || {};
        this.standardReminderFrequency = standard.reminderFrequency || null;

        const recommended = data?.recommendedStrategy || {};
        this.recommendedStrategy = {
          strategy: recommended.strategy || recommended.insights || null,
          reminderFrequency: recommended.reminderFrequency || null,
          overdueRisk: recommended.overdueRisk != null ? String(recommended.overdueRisk) : null,
          enabledDate: recommended.enabledDate || null,
        };

        const eff = data?.dunningEfficiencyResult;
        if (eff) {
          this.dunningEfficiencyTag = eff.dunningTag ?? null;
          this.deiValue = eff.dei != null ? parseFloat(eff.dei) : null;
          this.performanceEfficiencyPct = eff.dei != null ? Math.round(Number(eff.dei) * 100) : null;
          this.performanceImpactText = this.performanceEfficiencyPct != null
            ? `Current strategy shows ${this.performanceEfficiencyPct}% efficiency with extended payment delays and increased DSO.`
            : '';

          if (eff.dei != null) {
            const raw = this._generateDunningInsights(
              eff.rar,
              eff.rur,
              eff.car,
              eff.prar,
              eff.prur,
              eff.countReasoning,
              eff.freqReasoning,
              eff.paymentReasoning,
              eff.preDueCountReasoning,
              eff.dueDateReasoning
            );
            this.standardIssues = raw.map((insight, i) => ({
              key: String(i),
              title: insight.message,
              description: typeof insight.desc === 'string' ? insight.desc : (insight.desc != null ? String(insight.desc) : ''),
              isError: insight.isError,
              iconName: insight.isError ? 'utility:error' : 'utility:success',
              iconClass: insight.isError ? 'icon-red' : 'icon-green',
              boxClass: insight.isError ? 'issue-box issue-box--error' : 'issue-box issue-box--success',
            }));
          } else {
            this.standardIssues = [];
            if (standard.insights) {
              this.standardIssues = [{ key: '0', title: standard.insights, description: '', isError: false, iconName: 'utility:success', iconClass: 'icon-green', boxClass: 'issue-box issue-box--success' }];
            }
          }
        } else {
          this.dunningEfficiencyTag = null;
          this.deiValue = null;
          this.performanceEfficiencyPct = null;
          this.performanceImpactText = '';
          this.standardIssues = [];
          if (standard.insights) {
            this.standardIssues = [{ key: '0', title: standard.insights, description: '', isError: false, iconName: 'utility:success', iconClass: 'icon-green', boxClass: 'issue-box issue-box--success' }];
          }
        }

        // AI Dunning Efficiency variant
        const aiEff = data?.aiDunningEfficiencyResult;
        if (aiEff) {
          this.aiDunningEfficiencyTag = aiEff.dunningTag ?? null;
          this.aiDunningDeiValue = aiEff.dei != null ? parseFloat(aiEff.dei) : null;
          if (aiEff.dei != null) {
            const aiRaw = this._generateDunningInsights(
              aiEff.rar, aiEff.rur, aiEff.car, aiEff.prar, aiEff.prur,
              aiEff.countReasoning, aiEff.freqReasoning, aiEff.paymentReasoning,
              aiEff.preDueCountReasoning, aiEff.dueDateReasoning
            );
            this.aiDunningIssues = aiRaw.map((insight, i) => ({
              key: String(i),
              title: insight.message,
              description: typeof insight.desc === 'string' ? insight.desc : (insight.desc != null ? String(insight.desc) : ''),
              isError: insight.isError,
              iconName: insight.isError ? 'utility:error' : 'utility:success',
              iconClass: insight.isError ? 'icon-red' : 'icon-green',
              boxClass: insight.isError ? 'issue-box issue-box--error' : 'issue-box issue-box--success',
            }));
          } else {
            this.aiDunningIssues = [];
          }
        } else {
          this.aiDunningDeiValue = null;
          this.aiDunningEfficiencyTag = null;
          this.aiDunningIssues = [];
        }

        // Standard Rule Efficiency variant
        const stdEff = data?.standardDunningEfficiencyResult;
        if (stdEff) {
          this.stdRuleEfficiencyTag = stdEff.dunningTag ?? null;
          this.stdRuleDeiValue = stdEff.dei != null ? parseFloat(stdEff.dei) : null;
          if (stdEff.dei != null) {
            const stdRaw = this._generateDunningInsights(
              stdEff.rar, stdEff.rur, stdEff.car, stdEff.prar, stdEff.prur,
              stdEff.countReasoning, stdEff.freqReasoning, stdEff.paymentReasoning,
              stdEff.preDueCountReasoning, stdEff.dueDateReasoning
            );
            this.standardRuleIssues = stdRaw.map((insight, i) => ({
              key: String(i),
              title: insight.message,
              description: typeof insight.desc === 'string' ? insight.desc : (insight.desc != null ? String(insight.desc) : ''),
              isError: insight.isError,
              iconName: insight.isError ? 'utility:error' : 'utility:success',
              iconClass: insight.isError ? 'icon-red' : 'icon-green',
              boxClass: insight.isError ? 'issue-box issue-box--error' : 'issue-box issue-box--success',
            }));
          } else {
            this.standardRuleIssues = [];
          }
        } else {
          this.stdRuleDeiValue = null;
          this.stdRuleEfficiencyTag = null;
          this.standardRuleIssues = [];
        }

        this.lastInsightDate = data?.lastInsightDate || null;
        this.isRefreshing = false;
        this.isLoading = false;
        this._lastLoadedRecordId = this.recordId;
      })
      .catch(() => {
        this._lastLoadedRecordId = null;
        this.isRefreshing = false;
        this.isLoading = false;
      });
  }

  async handleSelectStandard(event) {
    event.preventDefault();
    event.stopPropagation();
    const newValue = !this.standardEnabled;
    const strategyName = labelStandardStrategy;
    const action = newValue ? 'enable' : 'disable';

    const confirmed = await LightningConfirm.open({
      message: `Are you sure you want to ${action} ${strategyName}?`,
      variant: 'header',
      label: labelConfirmDunningStrategyChange,
      theme: 'info',
    });

    if (!confirmed) return;

    this.standardEnabled = newValue;
    this.recommendedEnabled = this.standardEnabled ? false : this.recommendedEnabled;

    this._updateStrategy('standard', this.standardEnabled);
    this._updateStrategy('recommended', this.recommendedEnabled);
  }

  async handleSelectAi(event) {
    const toggleEl = event.target;
    const newValue = toggleEl.checked;
    const strategyName = labelAIRecommendedStrategy;
    const action = newValue ? 'enable' : 'disable';

    const confirmed = await LightningConfirm.open({
      message: `Are you sure you want to ${action} ${strategyName}?`,
      variant: 'header',
      label: labelConfirmDunningStrategyChange,
      theme: 'info',
    });

    if (!confirmed) {
      toggleEl.checked = this.recommendedEnabled;
      return;
    }

    this.recommendedEnabled = newValue;
    this.standardEnabled = this.recommendedEnabled ? false : this.standardEnabled;
    this.recommendedStrategy = {
      ...this.recommendedStrategy,
      enabledDate: newValue ? new Date().toISOString() : null,
    };

    this._updateStrategy('recommended', this.recommendedEnabled);
    this._updateStrategy('standard', this.standardEnabled);
  }

  _updateStrategy(strategyType, enabled) {
    if (!this.recordId) return;
    updateDunningStrategy({
      accountId: this.recordId,
      strategyType,
      enabled,
    })
      .then(() => {
        this.dispatchEvent(
          new CustomEvent('strategyupdated', {
            detail: { accountId: this.recordId, strategyType, enabled },
            bubbles: true,
            composed: true,
          })
        );
      })
      .catch((err) => {
        console.error('Error updating strategy:', err);
      });
  }

  handleBackdropClick() {
    this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
  }

  handleContentClick(e) {
    e.stopPropagation();
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
  }
}