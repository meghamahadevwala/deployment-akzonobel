import { LightningElement, api, wire } from 'lwc';
import getPredictions from '@salesforce/apex/PaymentPredictionController.getPredictions';

function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function getConfidenceClass(confidence) {
  if (confidence >= 85) return 'conf-emerald';
  if (confidence >= 75) return 'conf-blue';
  return 'conf-amber';
}

export default class PaymentPredictionModal extends LightningElement {
  @api isOpen = false;
  @api recordId;
  predictions = [];

  @wire(getPredictions, { accountId: '$recordId',isInvoiceListRequired:true })
  wiredPredictions({ error, data }) {
    if (data) {
      this.predictions = data.map((p, idx) => ({
        key: String(idx),
        dateFormatted: formatDate(p.predictionDate),
        totalAmountFormatted: (p.totalAmount || 0).toLocaleString(),
        invoiceCount: p.invoiceCount,
        confidence: p.confidence,
        confidenceClass: getConfidenceClass(p.confidence),
        badgeClass: 'prediction-block__badge ' + getConfidenceClass(p.confidence),
        invoices: (p.invoices || []).map((inv, i) => ({
          key: String(i),
          number: inv.invNumber,
          invoiceDateFormatted: formatDate(inv.invoiceDate),
          dueDateFormatted: formatDate(inv.dueDate),
          balanceFormatted: (inv.balance || 0).toLocaleString(),
          confidence: inv.confidence,
          confidenceClass: getConfidenceClass(inv.confidence),
          badgeClass: 'badge ' + getConfidenceClass(inv.confidence),
          reasoning: inv.reasoning,
          dpd: inv.dpd,
          documentType: inv.documentType,
        })),
      }));
    } else if (error) {
      console.error('Error fetching modal predictions:', error);
      this.predictions = [];
    }
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