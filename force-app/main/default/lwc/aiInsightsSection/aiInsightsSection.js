import { LightningElement, api } from 'lwc';
import labelAIInsights from '@salesforce/label/c.AI_Insights';
import labelPoweredByCelonis from '@salesforce/label/c.Powered_By_Celonis_PI';

export default class AiInsightsSection extends LightningElement {
  @api recordId;
  @api showDunningCard = false;
  @api showPaymentPredictionCard = false;

  get label() {
    return {
      aiInsights: labelAIInsights,
      poweredByCelonis: labelPoweredByCelonis,
    };
  }

  handlePaymentKnowMore() {
    this.dispatchEvent(
      new CustomEvent('paymentknowmore', { bubbles: true, composed: true })
    );
  }

  handleDunningKnowMore(event) {
    this.dispatchEvent(
      new CustomEvent('dunningknowmore', {
        bubbles: true,
        composed: true,
        detail: event.detail || {},
      })
    );
  }
}