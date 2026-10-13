import { LightningElement, api  } from 'lwc';

export default class IframeComponent extends LightningElement {
    @api url;
    @api title;
    @api maxHeight;
    connectedCallback() {
        this.iframeStyle = this.maxHeight != null && this.maxHeight != '' ? "max-height: " + this.maxHeight : "";
    }
}