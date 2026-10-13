public with sharing class KPIDunningReasoningTool extends celsrm.AIToolBuilder {

    public KPIDunningReasoningTool() {
        // Define the parameters schema
        Map<String, Object> props = new Map<String, Object>();
        props.put('reminder_count_reasoning', new Map<String, String>{'type' => 'string', 'description' => 'reasoning for reminder count'});
        props.put('reminder_frequency_reasoning', new Map<String, String>{'type' => 'string', 'description' => 'reasoning for reminder frequency'});
        props.put('days_to_payment_reasoning', new Map<String, String>{'type' => 'string', 'description' => 'reasoning for days between last reminder and payment'});
        props.put('pre-due-reminder_count_reasoning', new Map<String, String>{'type' => 'string', 'description' => 'reasoning for predue reminder count'});
        props.put('days_to_due_date_reasoning', new Map<String, String>{'type' => 'string', 'description' => 'reasoning for days between last pre-due-reminder and due date'});

        Map<String, Object> params = new Map<String, Object>{
            'type' => 'object',
            'properties' => props,
            'required' => new List<String>{
                'reminder_count_reasoning', 
                'reminder_frequency_reasoning', 
                'days_to_payment_reasoning', 
                'pre-due-reminder_count_reasoning', 
                'days_to_due_date_reasoning'
            }
        };

        // Call the base class method to set the function definition
        this.setFunction(
            'kpi_reasoning', 
            'Reasoning for reminder counts, frequency, and payment proximity.', 
            params
        );
    }

    // This method IS marked as virtual in your base class, so overriding it is fine
    public override String generatePrompt() {
        return 'Tool: kpi_reasoning - Analyzes dunning KPIs against business risk context.';
    }
}