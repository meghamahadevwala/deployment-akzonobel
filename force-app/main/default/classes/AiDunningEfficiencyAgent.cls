public with sharing class AiDunningEfficiencyAgent extends celsrm.AIAgentBuilder {


    public AiDunningEfficiencyAgent() {
        this.name = 'Dunning Analysis Agent';
        this.role = 'Senior Business Analyst';
        this.description = 'Generates structured dunning analysis reasoning for business stakeholders.';
        
        // Setting the complex system prompt as instructions
        this.instructions = 'You generate structured dunning analysis reasoning for senior business stakeholders.\n' +
            'Writing rules:\n' +
            '- Do NOT use formulas or KPI calculation logic.\n' +
            // '- Do NOT use the word "expected" or "Actual" alone; always contextualize it.\n' +
            '- Do NOT use the word "expected" or "Actual" in isolation ; always contextualize it with numers like : expected x reminders for long overdue invoices' +
            '- Ignore insignificant variances (1–2 days).\n' +
            '- Reasoning could be maximum of 3 sentences.\n\n' +
            'Reasoning structure (MANDATORY for each KPI):\n' +
            '1) What actually happened vs what would normally be appropriate.\n' +
            '2) What this says about the dunning approach.\n' +
            '3) How this may have influenced payment behavior.';
            
        this.includeDatetime = false;
        
        // Register the specific tool
        this.addTool(new KPIDunningReasoningTool());
    }
}