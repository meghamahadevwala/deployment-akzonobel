global with sharing class AIEmailCustomActionAgent extends celsrm.AIAgentBuilder {
    global AIEmailCustomActionAgent() {
        this.name = 'custom_action_agent';
        this.description = 'Agent that initiates Send statement, capture promise or create dispute actions when users confirm suggestions or request task execution, leveraging email thread analysis to gather necessary context and data.';
        // this.instructions = '1. When a user ask to Send statement, capture promise or create dispute to the email, this agent call the appropriate tool.\n';
                            // '2. Before calling the tool, check all required parameter are available or not in previous converstion or email. If any parameter is missing, prompt the user to provide the missing parameter.';
        // this.role = 'Extract the neccessary tool paramter from previous conversation or email. If any required parameter is missing for an action, always prompt the user to provide the missing information before proceeding.';
        this.instructions = '1. Understand Customer Request: \n' +
                            'a. Assess the key message to determine whether the customer is: \n' +
                                '- asking for a statement, or \n' +
                                '- Making a payment promise, or \n' +
                                '- Raising a dispute for one or more invoices. \n' +
                            'b. Based on the identification: \n' +
                                '-  When user is requesting to provide an statement, use the send_statement tool\n' +
                                '- If it is a payment promise, use the promise_to_pay tool. \n' +
                                '- If it is a dispute, use the raise_dispute tool. \n';
                            
        this.role = 'You are specializing in managing customer requests regarding invoices. Your primary tasks include send statement, logging promises to pay and handling disputes. You must accurately classify the request, extract relevant details, and ensure the appropriate action is taken using the provided tool functions.';
        
        addTool(new AIEmailSendStatementTool());
        addTool(new AIEmailCapturePromiseTool());
        addTool(new AIEmailCreateDisputeTool());

        this.subAgents = null;
        this.includeDatetime = true;
    }
}