import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import d3Resource from '@salesforce/resourceUrl/D3';
import getChartDetails from '@salesforce/apex/CreditLimitChangeHistoryChartController.getChartDetails';
import Credit_Limit_Changes from '@salesforce/label/c.Credit_Limit_Changes';
import Quarter from '@salesforce/label/c.Quarter';
import Changes from '@salesforce/label/c.Changes';


export default class ChangesPerQuarterChart extends LightningElement {
    @api recordId = '1232';
    @track isD3Loaded = false;
    @track chartData = [];
    @track tooltip;
    
    label = {
        Credit_Limit_Changes,
        Quarter,
        Changes
    };

    connectedCallback() {
        debugger;
        getChartDetails({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    this.chartData = this.processData(result);
                    this.renderChart();
                }
            })
            .catch(error => {
                console.error('Error fetching chart data:', error);
                this.renderChart(); 
            });
        // this.chartData = this.processData();
        Promise.all([
            loadScript(this, d3Resource)
        ]).then(() => {
            this.isD3Loaded = true;
        });
    }

    processData(result) {
        let quarterlyData = {};
        let data = JSON.parse(JSON.stringify(result));
        data.forEach(record => {
            let eventTime = new Date(record.EVENTTIME);
            let quarter = Math.floor((eventTime.getMonth() + 3) / 3);
            let year = eventTime.getFullYear();
            let key = `${year}-Q${quarter}`;
    
            if (!quarterlyData[key]) {
                quarterlyData[key] = 0;
            }
            
            quarterlyData[key]++;
        });
    
        return Object.keys(quarterlyData).map(key => {
            return { quarter: key, changes: quarterlyData[key] };
        });
    }
    

    renderChart() {
        if (!this.isD3Loaded) {
            return;
        }
    
        const data = this.chartData.length ? this.chartData : [{ quarter: '', changes: 0 }];
        const margin = { top: 20, right: 30, bottom: 40, left: 50 };
        const width = 960 - margin.left - margin.right;
        const height = 300 - margin.top - margin.bottom;
    
        // Create the SVG element and set its dimensions
        const svg = d3.select(this.template.querySelector('.chart'))
            .attr('width', width + margin.left + margin.right)
            .attr('height', height + margin.top + margin.bottom)
            .append('g')
            .attr('transform', `translate(${margin.left},${margin.top})`);
    
        // X Scale: maps quarters to horizontal positions with increased padding
        const x = d3.scaleBand()
            .domain(data.map(d => d.quarter))
            .range([0, width])
            .padding(0.4);  // Increase padding to decrease bar width
    
        // Y Scale: maps changes to vertical positions
        const y = d3.scaleLinear()
            .domain([0, d3.max(data, d => d.changes) || 1]) // Ensure a non-zero domain
            .nice()
            .range([height, 0]);
    
        // Add x-axis to the SVG
        svg.append('g')
            .attr('class', 'x-axis')
            .attr('transform', `translate(0,${height})`)
            .call(d3.axisBottom(x))
            .selectAll('text')  // Select all text elements within the x-axis
            .style('font-weight', 'normal')
            .style('font-stretch', 'normal')
            .style('font-style', 'normal')
            .style('letter-spacing', 'normal')
            .style('fill', '#706e6b');
    
        // Add y-axis to the SVG with ticks spaced by 1
        svg.append('g')
            .attr('class', 'y-axis')
            .call(d3.axisLeft(y).ticks(Math.ceil(d3.max(data, d => d.changes) || 1)))
            .selectAll('text')  // Select all text elements within the y-axis
            .style('font-weight', 'normal')
            .style('font-stretch', 'normal')
            .style('font-style', 'normal')
            .style('letter-spacing', 'normal')
            .style('fill', '#706e6b');
    
             // Add X Axis title
        svg.append('text')
        .attr('class', 'x-axis-title')
        .attr('x', width / 2)
        .attr('y', height + margin.bottom - 10)
        .attr('text-anchor', 'middle')
        .style('font-weight', 'normal')
        .style('font-stretch', 'normal')
        .style('font-style', 'normal')
        .style('line-height', '1.67')
        .style('letter-spacing', 'normal')
        .style('fill', 'black')
        .text(this.label.Quarter);

        // Add Y Axis title
        svg.append('text')
            .attr('class', 'y-axis-title')
            .attr('transform', 'rotate(-90)')
            .attr('x', -height / 2)
            .attr('y', -margin.left + 20)
            .attr('text-anchor', 'middle')
            .style('font-weight', 'normal')
            .style('font-stretch', 'normal')
            .style('font-style', 'normal')
            .style('line-height', '1.67')
            .style('letter-spacing', 'normal')
            .style('fill', 'black')
            .text(this.label.Changes);
        if (this.chartData.length) {
            // Create bars
            svg.selectAll('.bar')
                .data(data)
                .enter().append('rect')
                .attr('class', 'bar')
                .attr('x', d => x(d.quarter))
                .attr('y', d => y(d.changes))
                .attr('width', x.bandwidth())
                .attr('height', d => height - y(d.changes))
                .attr('fill', 'steelblue')
                // .on('mouseover', (event, i) => {
                //     const d = data[i]; // Access the data object based on the index
                //     if (d) {
                //         this.showTooltip(event, String(event.changes));
                //     }
                // })
                // .on('mousemove', (event, i) => {
                //     const d = data[i]; // Access the data object based on the index
                //     if (d) {
                //         this.moveTooltip(event, String(event.changes));
                //     }
                // })
                // .on('mouseout', () => {
                //     this.hideTooltip();
                // });
            svg.selectAll('.bar-label')
                .data(data)
                .enter().append('text')
                .attr('class', 'bar-label')
                .attr('x', d => x(d.quarter) + x.bandwidth() / 2)
                .attr('y', d => y(d.changes) - 5)
                .attr('text-anchor', 'middle')
                .style('font-weight', 'normal')
                .style('font-stretch', 'normal')
                .style('font-style', 'normal')
                .style('line-height', '1.67')
                .style('letter-spacing', 'normal')
                .style('fill', '#706e6b')
                .text(d => (d.changes));
        }

    }

    // renderChart() {
    //     if (!this.isD3Loaded || !this.chartData.length) {
    //         return;
    //     }
    
    //     const data = this.chartData;
    //     const margin = { top: 20, right: 30, bottom: 40, left: 50 };
    //     const width = 960 - margin.left - margin.right;
    //     const height = 300 - margin.top - margin.bottom;
    
    //     // Create the SVG element and set its dimensions
    //     const svg = d3.select(this.template.querySelector('.chart'))
    //         .attr('width', width + margin.left + margin.right)
    //         .attr('height', height + margin.top + margin.bottom)
    //         .append('g')
    //         .attr('transform', `translate(${margin.left},${margin.top})`);
    
    //     // X Scale: maps quarters to horizontal positions with increased padding
    //     const x = d3.scaleBand()
    //         .domain(data.map(d => d.quarter))
    //         .range([0, width])
    //         .padding(0.4);  // Increase padding to decrease bar width
    
    //     // Y Scale: maps changes to vertical positions
    //     const y = d3.scaleLinear()
    //         .domain([0, d3.max(data, d => d.changes)])
    //         .nice()
    //         .range([height, 0]);
    
    //     // Add x-axis to the SVG
    //     svg.append('g')
    //         .attr('class', 'x-axis')
    //         .attr('transform', `translate(0,${height})`)
    //         .call(d3.axisBottom(x));
    
    //     // Add y-axis to the SVG with ticks spaced by 1
    //     svg.append('g')
    //         .attr('class', 'y-axis')
    //         .call(d3.axisLeft(y).ticks(Math.ceil(d3.max(data, d => d.changes)))); // Ensure ticks are spaced by 1
    
    //     // Create bars
    //     svg.selectAll('.bar')
    //         .data(data)
    //         .enter().append('rect')
    //         .attr('class', 'bar')
    //         .attr('x', d => x(d.quarter))
    //         .attr('y', d => y(d.changes))
    //         .attr('width', x.bandwidth())
    //         .attr('height', d => height - y(d.changes))
    //         .attr('fill', 'steelblue')
    //         .on('mouseover', (event, i) => {
    //             const d = data[i]; // Access the data object based on the index
    //             if (d) {
    //                 // this.showTooltip(event, `${d.label}: ${d.range[1] != null && d.range[1] != undefined || d.range[1] != '' ? d.range[1].toLocaleString() : 0 }`);
    //                 this.showTooltip(event, String(event.changes));
    //             }
    //         })
    //         .on('mousemove', (event, i) => {
    //             const d = data[i]; // Access the data object based on the index
    //             if (d) {
    //                 this.moveTooltip(event, String(event.changes));
    //             }
    //         })
    //         .on('mouseout', () => {
    //             this.hideTooltip();
    //         });
    // }
    
    showTooltip(ev, text) {
        const tooltip2 = d3.select(this.template.querySelector('.chart-container'))
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
        const xPosition = event.pageX + 10;
        const yPosition = event.pageY + 10; 

        tooltip2.style('left', `${xPosition}px`)
            .style('top', `${yPosition}px`)
            .style('visibility', 'visible');

        this.tooltip = tooltip2;

        // this.moveTooltip(event);
    }

    moveTooltip(ev, text) {
        if (this.tooltip) {
            console.log('event.pageX:: ' + event.pageX + "| event.pageY:: " + event.pageY);
            const xPosition = event.pageX + 10;
            const yPosition = event.pageY + 10;
            this.tooltip.style('left', `${xPosition}px`)
            .style('top', `${yPosition}px`)
            .style('visibility', 'visible')
            .html(text);
        }
    }
    hideTooltip() {
        if (this.tooltip) {
            this.tooltip.remove();
        }
    }
    
}