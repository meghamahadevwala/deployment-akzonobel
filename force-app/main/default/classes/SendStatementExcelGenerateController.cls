public with sharing class SendStatementExcelGenerateController {
    public String accountId {get; set; }
    public String listView {get; set; }
    public String tableBody {get; set; }
    public SendStatementExcelGenerateController() {
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        listView = ApexPages.currentPage().getParameters().get('listView');

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', accountId);
        inMap.put('StatementFormat', 'Excel');
        inMap.put('ListView', listView);
        inMap = SendStatementActionController.createStatementAttachment(inMap);
        tableBody = SendStatementActionController.generateAttachmentAndEmailBody(inMap);
    }
}