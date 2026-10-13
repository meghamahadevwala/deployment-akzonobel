public with sharing class AIEmailSendStatementTool extends celsrm.AIToolBuilder{
    public AIEmailSendStatementTool() {
        shouldToolAutoExecute = false;
        isActionTool = true;
        setFunction('send_statement', ' \'Description & details about this action/tool: This sends a statement of account to the customer as per the latest message. \n When to choose this action to execute : when a statement is requested in the latest message either for a specific invoice/s or for different invoice buckets. Use only when an specific one account is pre-mapped against the latest message.\n What will system do when this action is triggered? :\n1)System will create an attachment containing list of invoices from an specific account. If the account is not pre-mapped with this is email /Email Content object; the statement generation will fail.\n2)List of invoices will have invoices as per \'Invoice Bucket \' or `Invoice Numbers`.The list of invoices will contain Invoice number , Invoice date , Invoice due date, Invoice\' days past due , amount of the invoice. \n3) System will send an email reply over the current email thread with email body as per `Email Response` parameter and attach the generated statement attachment. \n4) System will update the account with a note about sending statement and also log this activity in system for future reference. ', 
            new Map<String, Object>{
                'type' => 'object',
                'properties' => new Map<String, Object>{
                    'invoice_bucket' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'List of invoices type/bucket from which is requested to be sent. Options are: 1. overdue_invoices, 2. all_open_invoices(Default), 3. all_transactions 4. all_payments. This is optional only if specific invoice numbers are requested. If no clear request for invoice bucket or invoice numbers is mentioned, consider it as a request for all open invoices.'
                    },
                    'invoice_numbers' => new Map<String, Object>{
                        'type' => 'array',
                        'description' => 'list of invoice numbers if latest message specifically mentions the invoice numbers for which statement is requested. This is optional only if invoice bucket is mentioned in the request. If no clear request for invoice bucket or invoice numbers is mentioned, keep invoice_numbers field blank and consider it as a request for all open invoices in invoice_bucket.', 
                        'items' => new Map<String, Object>{
                            'type' => 'string'
                        }
                    },
                    'email_response' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Generate a reply for the past email. IMPORTANT: You must include {transaction.summary} inside the HTML body where invoice details are required to mention. Generate email response only in HTML Format, nothing else. sample HTML Format: <body><p>Dear [Recipient Name],</p><p>Thank....x.</p><br></body>' +
                        'Email/content rules to follow when writting :\n' +
                        '- Write from the Account Receivable team\'s perspective in crisp business language use keyword \'we\' , \'our\' .\n' +
                        '- Consider previous email threads and customer context when drafting the response.\n' +
                        '- Address the sender of the latest email. Preserve CC context when relevant.\n' +
                        '- Never include internal agent names, pipeline mechanics, Salesforce API names, or Salesforce record IDs in customer-facing text.\n' +
                        '- Do not include a human signature block.\n'
                    }
                }
            }
        );
    }
}