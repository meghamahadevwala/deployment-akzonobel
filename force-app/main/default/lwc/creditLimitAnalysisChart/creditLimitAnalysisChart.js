import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import d3Resource from '@salesforce/resourceUrl/D3'
import getChartDetails from '@salesforce/apex/WCM_FetchAccountDetails.getChartDetails';
import Credit_Limit_Analysis from '@salesforce/label/c.SRM_AD_Credit_Limit_Analysis';
import Total_AR from '@salesforce/label/c.SRM_AT_Total_AR';
import Open_Billing_Value from '@salesforce/label/c.SRM_AD_Open_Billing_Value';
import Open_Delivery_Value from '@salesforce/label/c.SRM_AD_Open_Delivery_Value';
import Short_Term_Exposure from '@salesforce/label/c.SRM_AD_Short_Term_Exposure';
import Order_Receivable_Delta from '@salesforce/label/c.Order_Receivable_Delta';



export default class CreditLimitAnalysisChart extends LightningElement {
    @api recordId;
    @track isD3Loaded;
    @track isD3AlreadyLoaded;
    @track allData;
    @track tooltip;
    label = {
        Credit_Limit_Analysis,
        Total_AR,
        Open_Billing_Value,
        Open_Delivery_Value,
        Short_Term_Exposure,
        Order_Receivable_Delta
    }

    connectedCallback() {
        this.isD3Loaded = false;
        this.isD3AlreadyLoaded = false;
        getChartDetails({
            recordId: this.recordId
        }).then(result => {
            if (result) {
                this.allData = JSON.parse(JSON.stringify(result));
            }
        }).catch(error => {
            console.log('error>>>' + error);
        });
        Promise.all([
            loadScript(this, d3Resource)
        ]).then(() => {
            this.isD3Loaded = true;
        });
    }

    get chartData() {
        if (this.isD3Loaded && !this.isD3AlreadyLoaded && this.allData) {
            let data = [];
            data.push({ label: 'Credit Exposure', range: [0, this.allData.shortTermExposure] });
            data.push({ label: 'Order Value (30 days)', range: [0, this.allData.totalAR] });
            data.push({ label: this.label.Open_Billing_Value , range: [this.allData.totalAR, this.allData.totalAR + this.allData.billingValue] });
            data.push({ label: this.label.Open_Delivery_Value, range: [this.allData.totalAR + this.allData.billingValue, this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue] });
            data.push({ label: 'Open Invoice Value', range: [this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue, this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue + this.allData.orderReceivableDelta] });
            data.push({ label: 'Special Credit Value', range: [this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue + this.allData.orderReceivableDelta, this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue + this.allData.orderReceivableDelta + this.allData.specialCreditValue] });
            // const data = [
            //     { label: 'Credit Exposure', range: [0, 75] },
            //     { label: 'Order Value (30 days)', range: [0, 50] },
            //     { label: 'Open Billing Value', range: [50, 57] },
            //     { label: 'Open Delivery Value', range: [57, 65] },
            //     { label: 'Open Sales Order', range: [65, 75] }
            // ];
            
            // Set up chart dimensions
            
            const height = 300;
            const margin = { top: 20, right: 20, bottom: 60, left: 110 };
            const width = this.template.querySelector(".border-class").getBoundingClientRect().width - margin.left - margin.right;

            const svg = d3.select(this.template.querySelector('.chart'))
                .attr('width', width + margin.left + margin.right)
                .attr('height', height + margin.top + margin.bottom)
                .append('g')
                .attr('transform', `translate(${margin.left},${margin.top})`);
                
                
            const color = d3.scaleOrdinal(d3.schemeSet2);

            const xScale = d3.scaleLinear()
                .domain([0, d3.max(data, d => d.range[1])])
                .range([0, width]);

            const yScale = d3.scaleBand()
                .domain(data.map(d => d.label))
                .range([0, height])
                .padding(0.1);

            
            // Add x axis
            svg.append('g')
            .attr('transform', `translate(0, ${height})`)
            .style('font-size', '9')
            .call(d3.axisBottom(xScale));
            // .selectAll('text')
            // .style('text-anchor', 'end')
            // .attr('dx', '-.8em')
            // .attr('dy', '.15em')
            // .attr('transform', 'rotate(-45)');

            // Add y axis
            svg.append('g')
            .style('font-size', '9')
            .call(d3.axisLeft(yScale));

            //Customize bar
            svg.selectAll('rect')
                .data(data)
                .enter()
                .append('rect')
                .attr('x', d => xScale(d.range[0]))
                .attr('y', d => yScale(d.label))
                .attr('width', d => xScale(d.range[1]) - xScale(d.range[0]))
                .attr('height', yScale.bandwidth())
                .attr('fill', (d, i) => color(i))
                // .on('mouseover', (event, d) => {
                //     this.showTooltip(event, `Value: ${d.label}`);
                // })
                .on('mouseover', (event, i) => {
                    const d = data[i]; // Access the data object based on the index
                    if (d) {
                        // this.showTooltip(event, `${d.label}: ${d.range[1] != null && d.range[1] != undefined || d.range[1] != '' ? d.range[1].toLocaleString() : 0 }`);
                        this.showTooltip(event, event.label == 'Credit Exposure' ? this.allData.shortTermExposure.toLocaleString() : event.label == 'Order Value (30 days)' ? this.allData.totalAR.toLocaleString() : event.label == 'Open Billing Value' ? this.allData.billingValue.toLocaleString() : event.label == 'Open Delivery Value' ? this.allData.deliveryValue.toLocaleString() : event.label == 'Open Sales Order' ? this.allData.openSalesOrder.toLocaleString() : event.label == 'Open Invoice Value' ? this.allData.orderReceivableDelta.toLocaleString(): event.label == 'Special Credit Value' ? this.allData.specialCreditValue.toLocaleString() : '');
                    }
                })
                .on('mousemove', (event, i) => {
                    // this.moveTooltip(event);
                    const d = data[i]; // Access the data object based on the index
                    if (d) {
                        // this.moveTooltip(event, `${d.label}: ${d.range[1] != null && d.range[1] != undefined || d.range[1] != '' ? d.range[1].toLocaleString() : 0 }`);
                        this.moveTooltip(event, event.label == 'Credit Exposure' ? this.allData.shortTermExposure.toLocaleString() : event.label == 'Order Value (30 days)' ? this.allData.totalAR.toLocaleString() : event.label == 'Open Billing Value' ? this.allData.billingValue.toLocaleString() : event.label == 'Open Delivery Value' ? this.allData.deliveryValue.toLocaleString() : event.label == 'Open Sales Order' ? this.allData.openSalesOrder.toLocaleString() : event.label == 'Open Invoice Value' ? this.allData.orderReceivableDelta.toLocaleString(): event.label == 'Special Credit Value' ? this.allData.specialCreditValue.toLocaleString() : '');
                    }
                })
                .on('mouseout', () => {
                    this.hideTooltip();
                });
            
            svg.selectAll('text')
                .data(data)
                .enter()
                .append('text')
                .attr('x', d => xScale((d.range[0] + d.range[1]) / 2))
                .attr('y', d => yScale(d.label) + yScale.bandwidth() / 2)
                .attr('text-anchor', 'middle')
                .attr('alignment-baseline', 'middle')
                .text(d => `${d.range[0]} - ${d.range[1]}`);
            
            // Create a tooltip div
            // const tooltip = svg.append("g")
            //     .style("pointer-events", "none");
            // const tooltip = d3
            //     .select(this.template.querySelector('.chart'))
            //     .append('div')
            //     // .style('position', 'absolute')
            //     .style('visibility', 'hidden')   
            //     .style('background-color', 'rgba(0, 0, 0, 0.8)')
            //     .style('color', 'white')
            //     .style('padding', '5px')
            //     .style('border-radius', '5px');

            // svg.selectAll('rect')
            //     .on('pointerenter', (event, d) => {
            //         console.log('Mouseover event:', event);
            //         console.log('Data object:', d);
            //         tooltip.text('Value: ' + d);
            //         tooltip.style('visibility', 'visible');
            //     })
            //     .on('pointermove', event => {
            //         console.log('mousemove event:', event);
            //         tooltip.style('top', event.pageY - 10 + 'px').style('left', event.pageX + 10 + 'px');
            //     })
            //     .on('pointerleave', () => {
            //         console.log('mouseout event:', event);
            //         tooltip.style('visibility', 'hidden');
            //     });

            // Add upper and lower boundary lines
            svg.append('line')
                .attr('x1', xScale(this.allData.creditLimit))
                .attr('y1', 0)
                .attr('x2', xScale(this.allData.creditLimit))
                .attr('y2', height)
                .attr('stroke', 'red')
                .attr('stroke-dasharray', '5');
            
            svg.append('line')
                .attr('x1', xScale(this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue + this.allData.openSalesOrder))
                .attr('y1', 0)
                .attr('x2', xScale(this.allData.totalAR + this.allData.billingValue + this.allData.deliveryValue + this.allData.openSalesOrder))
                .attr('y2', height)
                .attr('stroke', 'green')
                .attr('stroke-dasharray', '5');

            this.isD3AlreadyLoaded = true;
        }
    }
    showTooltip(ev, text) {
        const tooltip = d3.select(this.template.querySelector('.waterfall-chart-container'))
            .append('div')
            .attr('class', 'tooltip')
            .style('position', 'fixed')
            .style('visibility', 'visible')
            .style('background-color', 'rgba(0, 0, 0, 0.8)')
            .style('color', 'white')
            .style('padding', '5px')
            .style('border-radius', '5px')
            .text(text);
        console.log('event.pageX:: ' + event.pageX + "| event.pageY:: " + event.pageY);
        const xPosition = event.pageX - 100;
        const yPosition = event.pageY + 20;

        tooltip.style('left', `${xPosition}px`)
            .style('top', `${yPosition}px`)
            .style('visibility', 'visible');

        this.tooltip = tooltip;

        // this.moveTooltip(event);
    }
    

    moveTooltip(ev, text) {
        if (this.tooltip) {
            console.log('event.pageX:: ' + event.pageX + "| event.pageY:: " + event.pageY);
            const xPosition = event.pageX - 100;
            const yPosition = event.pageY + 20;
            this.tooltip.style('left', `${xPosition}px`)
            .style('top', `${yPosition}px`)
            .style('visibility', 'visible')
            .html(text);
            // this.tooltip.style('top', document.documentElement.clientHeight - 10 + 'px')
            //             .style('left', document.documentElement.clientWidth + 10 + 'px')
            //             .html(text);
        }
    }

    hideTooltip() {
        if (this.tooltip) {
            this.tooltip.remove();
        }
    }
}