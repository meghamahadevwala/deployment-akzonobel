public with sharing class AIEmailCreateDisputeTool extends celsrm.AIToolBuilder {
    public AIEmailCreateDisputeTool() {
        isActionTool = true;
        shouldToolAutoExecute = false;
        // TODO: change dispute type & Reason code static to dynamic
        List<String> disputeType = new List<String>{'Billing', 'Contractual basis', 'Delivery', 'Other', 'Payment method', 'Service'};
        Map<String, List<String>> disputeReason = new Map<String, List<String>>{
            'Billing' => new List<String>{'Incorrect Currency', 'Invoice is missing', 'Invoice recipient is incorrect', 'Missing PO reference','PO overbilled (duplicated order entry)','Price incorrect','Tax rate incorrect','Wrong Sold-To (no VAT numbers)'},
            'Contractual basis' => new List<String>{'Delivery performed by incorrect entity', 'Deviation of payment terms', 'PO cancelled', 'PO consumed', 'Requestor Unknown'},
            'Delivery' => new List<String>{'Article incorrect', 'Damaged goods', 'Export documentation incomplete', 'Late delivery Clause', 'Missing goods', 'Proof of delivery needed', 'Quality Issue', 'Quantity incorrect', 'Returned goods', 'Returns not processed'},
            'Other' => new List<String>{'Invoice disputed'},
            'Payment method' => new List<String>{'Credit Card rejected'},
            'Service' => new List<String>{'Service not performed', 'Service Report is missing', 'Waiting on commissioning/training'}
        };

        setFunction('raise_dispute', 'customer is raising a dispute for one or more invoices', 
            new Map<String, Object>{
                'type' => 'object',
                'properties' => new Map<String, Object>{
                    'invoice_numbers' => new Map<String, Object>{
                        'type' => 'array', 
                        'description' => 'list of invoice numbers', 
                        'items' => new Map<String, Object>{'type' => 'string'}
                    },
                    'dispute_type' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Capture the dispute type from these list of disputes ' + JSON.serialize(disputeType)
                    },
                    'dispute_reason' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Capture the dispute reason based on type from this reasons ' + JSON.serialize(disputeReason)  + ' :optional'
                    },
                    'email_response' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Generate a reply for the past email. Consider previous email threds. Mention sender and receiver. Generate email response only in HTML Format, nothing else. sample HTML Format: <body><p>Dear [Recipient Name],</p><p>Thank....x.</p><br></body>'+ 'Email/content rules to follow when writting :\n' +
                        '- Write from the Account Receivable team\'s perspective in crisp business language use keyword \'we\' , \'our\' .\n' +
                        '- Consider previous email threads and customer context when drafting the response.\n' +
                        '- Address the sender of the latest email. Preserve CC context when relevant.\n' +
                        '- Never include internal agent names, pipeline mechanics, Salesforce API names, or Salesforce record IDs in customer-facing text.\n' +
                        '- Do not include a human signature block.\n'
                    }
                },
                'required' => new List<String>{'invoice_numbers', 'dispute_type', 'email_response'}
            }
        );
    }
}