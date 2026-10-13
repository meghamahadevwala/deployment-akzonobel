import { LightningElement, api } from 'lwc';
import fetchStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.fetchStickyNotes';
import saveStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotes';
import saveStickyNotesColor from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotesColor';
import labelQuickNote from '@salesforce/label/c.Quick_Note';
import labelAddNotePlaceholder from '@salesforce/label/c.Add_Note_Placeholder';
import labelLatestNote from '@salesforce/label/c.Latest_Note';
import labelLatestNoteModalTitle from '@salesforce/label/c.Latest_Note_Modal_Title';
import labelCancel from '@salesforce/label/c.Cancel';
import labelSave from '@salesforce/label/c.Save';
import labelClose from '@salesforce/label/c.Close';

/**
 * Set to true when deploying to an org with the celsrm managed package installed.
 * Set to false for unmanaged / unpackaged orgs.
 */
const IS_MANAGED = true;
const NS = IS_MANAGED ? 'celsrm__' : '';

const NOTE_COLORS = [
  { key: '1', class: 'priority-dot dot-yellow', style: 'rgba(231, 245, 29, 0.404)' },
  { key: '2', class: 'priority-dot dot-green', style: 'rgba(169, 245, 81, 0.425)' },
  { key: '3', class: 'priority-dot dot-red', style: 'rgba(245, 5, 5, 0.363)' },
  { key: '4', class: 'priority-dot dot-purple', style: 'rgba(235, 166, 206, 0.685)' },
  { key: '5', class: 'priority-dot dot-white', style: '#ffffff' },
];

export default class QuickNoteCard extends LightningElement {
  label = {
    quickNote: labelQuickNote,
    addNotePlaceholder: labelAddNotePlaceholder,
    latestNote: labelLatestNote,
    latestNoteModalTitle: labelLatestNoteModalTitle,
    cancel: labelCancel,
    save: labelSave,
    close: labelClose,
  };

  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    if (value) this.loadNotes();
  }

  stickyNotes = '';
  latestNotes = '';
  noteColorStyle = '';
  priorityColors = NOTE_COLORS;
  showMaxModal = false;
  tempStickyNotes = '';

  /** Full-box highlight: apply note color to textarea background, or default. */
  get noteInputStyle() {
    return this.noteColorStyle ? this.noteColorStyle : 'background-color: #f8fafc';
  }

  connectedCallback() {
    if (this.recordId) {
      this.loadNotes();
    }
  }

  async loadNotes() {
    if (!this.recordId) return;
    await fetchStickyNotes({ recordId: this.recordId })
      .then((result) => {
        if (result) {
          this.stickyNotes = result[NS + 'Sticky_Note__c'] || '';
          if (result[NS + 'Sticky_Note_Color__c']) {
            this.noteColorStyle = 'background:' + result[NS + 'Sticky_Note_Color__c'];
          }
          this.latestNotes = result[NS + 'Latest_Note__c'] || '';
        }
      })
      .catch((error) => {
        console.error('QuickNoteCard: fetchStickyNotes error', error);
      });
  }

  handleNoteInput(e) {
    this.stickyNotes = e.target.value;
  }

  handleSaveNote() {
    if (!this.recordId) return;
    saveStickyNotes({ notes: this.stickyNotes, recordId: this.recordId })
      .then((result) => {
        if (result) this.stickyNotes = result;
        this.loadNotes();
      })
      .catch((error) => {
        console.error('QuickNoteCard: saveStickyNotes error', error);
      });
  }

  handleColorClick(event) {
    const color = event.currentTarget.dataset.color;
    if (!color || !this.recordId) return;
    this.noteColorStyle = 'background:' + color;
    saveStickyNotesColor({ noteColor: color, recordId: this.recordId })
      .then(() => {})
      .catch((error) => {
        console.error('QuickNoteCard: saveStickyNotesColor error', error);
      });
  }

  handleMaximize() {
    this.tempStickyNotes = this.stickyNotes;
    document.body.style.overflow = 'hidden';
    this.showMaxModal = true;
  }

  handleCloseMaxModal() {
    document.body.style.overflow = 'auto';
    this.showMaxModal = false;
  }

  handleModalNoteChange(event) {
    this.tempStickyNotes = event.target.value;
  }

  handleSaveMaxModal() {
    this.stickyNotes = this.tempStickyNotes;
    this.showMaxModal = false;
    document.body.style.overflow = 'auto';
    if (!this.recordId) return;
    saveStickyNotes({ notes: this.stickyNotes, recordId: this.recordId })
      .then((result) => {
        if (result) this.stickyNotes = result;
        this.loadNotes();
      })
      .catch((error) => {
        console.error('QuickNoteCard: saveStickyNotes (modal) error', error);
      });
  }
}