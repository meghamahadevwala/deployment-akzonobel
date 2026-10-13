import { LightningElement, api, wire } from 'lwc';
import getPredictions from '@salesforce/apex/PaymentPredictionController.getPredictions';

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export default class PaymentPredictionCard extends LightningElement {
  @api recordId;
  predictions = [];

  @wire(getPredictions, { accountId: '$recordId',isInvoiceListRequired:false })
  wiredPredictions({ error, data }) {
    if (data) {
      this.predictions = data.map((p, idx) => ({
        key: String(idx),
        dateFormatted: formatDate(p.predictionDate),
        invoiceCount: p.invoiceCount,
        totalK: (p.totalAmount / 1000).toFixed(1),
        confidence: p.confidence,
        barStyle: `width: ${p.confidence}%`,
      }));
    } else if (error) {
      console.error('Error fetching predictions:', error);
      this.predictions = [];
    }
  }

  handleKnowMore() {
    this.dispatchEvent(
      new CustomEvent('knowmore', { bubbles: true, composed: true })
    );
  }
}