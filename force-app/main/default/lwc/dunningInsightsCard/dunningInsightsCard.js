import { LightningElement, api } from 'lwc';
import getDunningInsights from '@salesforce/apex/AIDunningInsightsController.getDunningInsights';
import labelDunningInsights from '@salesforce/label/c.Dunning_Insights';
import labelKnowMore from '@salesforce/label/c.Know_More';
import labelLoading from '@salesforce/label/c.Loading';
import labelCurrentlyActive from '@salesforce/label/c.Currently_Active';
import labelCurrentDunningEfficiency from '@salesforce/label/c.Current_Dunning_Efficiency';
import labelAIRecommended from '@salesforce/label/c.AI_Recommended';
import labelDunningAgent from '@salesforce/label/c.Dunning_Agent';
import labelStrategy from '@salesforce/label/c.Strategy';
import labelFrequency from '@salesforce/label/c.Frequency';
import labelRiskReduction from '@salesforce/label/c.Risk_Reduction';
import labelTimely from '@salesforce/label/c.Timely_Followup';
import labelTooFew from '@salesforce/label/c.Too_Few_Reminders';
import labelExcessiveVolume from '@salesforce/label/c.Excessive_Reminder_Volume';
import labelSpacedTooFar from '@salesforce/label/c.Reminders_Spaced_Too_Far';
import labelTooFrequent from '@salesforce/label/c.Reminders_Too_Frequent';
import labelNotAligned from '@salesforce/label/c.Reminders_Not_Aligned';
import labelRemindersAligned from '@salesforce/label/c.Reminders_Aligned';
import labelMissedPreventive from '@salesforce/label/c.Missed_Preventive_Reminders';
import labelPreDueAggressive from '@salesforce/label/c.PreDue_Reminders_Aggressive';

export default class DunningInsightsCard extends LightningElement {
  @api recordId;

  activeStrategyLabel = null;
  currentPerformanceTag = null;
  currentPerformanceText = null;
  currentPerformancePct = null;
  hasPerformanceError = false;
  recommendedStrategyText = null;
  recommendedFrequency = null;
  recommendedRisk = null;
  isLoading = true;
  hasData = false;
  enableDunningEfficiency = false;
  enableAIDunning = false;

  _standardEnabled = false;
  _recommendedEnabled = false;

  label = {
      dunningInsights: labelDunningInsights,
      knowMore: labelKnowMore,
      loading: labelLoading,
      currentlyActive: labelCurrentlyActive,
      aiRecommended: labelAIRecommended,
      strategy: labelStrategy,
      frequency: labelFrequency,
      riskReduction: labelRiskReduction,
  };

  connectedCallback() {
    this._load();
  }

  // set recordId(value) {
  //   this._recordId = value;
  //   this._load();
  // }
  // get recordId() {
  //   return this._recordId;
  // }
  // _recordId;

  get standardEnabled() {
    return this._standardEnabled;
  }
  get recommendedEnabled() {
    return this._recommendedEnabled;
  }

  _load() {
    if (!this.recordId) {
      this.isLoading = false;
      return;
    }
    this.isLoading = true;
    getDunningInsights({ accountId: this.recordId })
      .then((data) => {
        this.hasData = true;
        this.enableDunningEfficiency = data?.enableDunningEfficiency ?? false;
        this.enableAIDunning = data?.enableAIDunning ?? false;
        this._standardEnabled = data?.standardStrategy?.enabled ?? false;
        this._recommendedEnabled = data?.recommendedStrategy?.enabled ?? false;

        if (this._standardEnabled) this.activeStrategyLabel = labelCurrentDunningEfficiency;
        else if (this._recommendedEnabled) this.activeStrategyLabel = labelAIRecommended;
        else this.activeStrategyLabel = labelDunningAgent;

        const standard = data?.standardStrategy || {};
        const recommended = data?.recommendedStrategy || {};
        this.recommendedStrategyText = recommended.strategy || recommended.insights || null;
        this.recommendedFrequency = recommended.reminderFrequency || null;
        this.recommendedRisk = recommended.overdueRisk != null ? String(recommended.overdueRisk) : null;

        let eff = data?.dunningEfficiencyResult;
        if (this._recommendedEnabled && data?.aiDunningEfficiencyResult?.dei != null) {
          eff = data.aiDunningEfficiencyResult;
        } else if (this._standardEnabled && data?.standardDunningEfficiencyResult?.dei != null) {
          eff = data.standardDunningEfficiencyResult;
        }
        if (eff) {
          this.currentPerformanceTag = eff.dunningTag || null;
          const tagLower = (eff.dunningTag || '').toLowerCase();
          const isTagError = tagLower.includes('under') || tagLower.includes('over');
          const insights = this._generateDunningInsights(
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
          if (insights.length > 0) {
            this.currentPerformanceText = insights[0].message;
            this.hasPerformanceError = insights[0].isError || isTagError;
          } else {
            this.currentPerformanceText = standard.insights || null;
            this.hasPerformanceError = isTagError;
          }
          this.currentPerformancePct = eff.dei != null ? Math.round(Number(eff.dei) * 100) : null;
        } else {
          this.currentPerformanceText = standard.insights || null;
          this.currentPerformancePct = data?.overdueRisk != null ? Math.round(Number(data.overdueRisk)) : null;
          this.hasPerformanceError = false;
        }
        this.isLoading = false;
      })
      .catch((error) => {
        this.isLoading = false;
        this.hasData = false;
        console.error('DunningInsightsCard: getDunningInsights failed', error?.body?.message ?? error?.message ?? error);
        if (error?.body?.stackTrace) {
          console.error('Stack trace:', error.body.stackTrace);
        }
      });
  }

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
    return insights.filter((i) => {
      const key = `${i.index}-${i.message}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).sort((a, b) => a.index - b.index);
  }

  get barStyle() {
    const pct = this.currentPerformancePct != null ? Math.min(100, Math.max(0, this.currentPerformancePct)) : 0;
    return `width: ${pct}%`;
  }

  get displayPct() {
    return this.currentPerformancePct != null ? `${this.currentPerformancePct}%` : '';
  }

  get hasPerformanceBar() {
    return this.currentPerformancePct != null;
  }

  get hasPerformanceSuccess() {
    return !this.hasPerformanceError;
  }

  get dunningBoxClass() {
    if (this.hasPerformanceError) return 'dunning-box dunning-box-red';
    return 'dunning-box dunning-box-green';
  }

  get dunningBarClass() {
    if (this.hasPerformanceError) return 'dunning-bar dunning-bar-red';
    return 'dunning-bar dunning-bar-green';
  }

  get dunningPctClass() {
    if (this.hasPerformanceError) return 'dunning-pct dunning-pct-red';
    return 'dunning-pct dunning-pct-green';
  }

  get isCardVisible() {
    if (this.isLoading) return true;
    return this.enableDunningEfficiency || this.enableAIDunning;
  }

  /** Show first (current performance) box only when dunning efficiency is enabled and we have data. */
  get hasCurrentPerformance() {
    if (!this.enableDunningEfficiency) return false;
    return this.currentPerformanceTag != null || this.currentPerformanceText != null || this.currentPerformancePct != null;
  }

  /** Show AI Recommended box only when AI dunning is enabled and we have data. */
  get hasRecommendedSection() {
    if (!this.enableAIDunning) return false;
    return this.recommendedStrategyText != null || this.recommendedFrequency != null || this.recommendedRisk != null;
  }

  handleKnowMore() {
    this.dispatchEvent(
      new CustomEvent('knowmore', {
        bubbles: true,
        composed: true,
        detail: { recordId: this.recordId },
      })
    );
  }
}