public with sharing class CLR_PdfForFlow implements Queueable, Database.AllowsCallouts{
  private List<String> recordIds;
  public CLR_PdfForFlow(List<String> recordIds) {
        this.recordIds = recordIds;
    }


  public void execute(QueueableContext context)  {
    System.debug(this.recordIds);
    List<celsrm__Credit_Review__c> creditReviews = [SELECT Id, Name,
              celsrm__Status__c,
              celsrm__Requested_Credit_Limit__c,
              celsrm__Account__r.Name,
              celsrm__Account__r.celsrm__Payment_Behaviour_Text__c,
              celsrm__Account__r.celsrm__Payment_Behaviour_Trend__c,
              CurrencyIsoCode,
              Moody_s_Credit_Limit__c,
              Status_Moodys__c,
              Status_Description__c,
              BvD_ID_Number__c,
              Date_of_Incorporation__c,
              Status_Date_Moody__c,
              MORE_Evaluation_Score__c,
              MORE_Evaluation_Probability_of_Default__c,
              MORE_Evaluation_Year__c,
              MORE_Evaluation_Confidence_Level__c,
              Reactive_Score__c,
              Reactive_Probability_of_Default__c,
              Reactive_Confidence_Level__c,
              Reactive_Date__c,
              Qualitative_Score__c,
              Qualitative_score_Confidence_level__c,
              Qualitative_Score_Date__c,
              Liquidity_Ratio__c,
              Current_Ratio__c,
              MORE_Credit_Limit__c,
              Reactive_Credit_Limit__c,
              Qualitative_Credit_Limit__c,
              Registered_Capital__c,
              Requested_Credit_Limit_EUR__c
       FROM celsrm__Credit_Review__c
       WHERE Id = :this.recordIds];

    List<ContentVersion> cvs = new List<ContentVersion>();
    if(creditReviews != null && creditReviews.size() > 0) {
      for(celsrm__Credit_Review__c creditReview : creditReviews) {
        if (creditReview != null && creditReview.BvD_ID_Number__c != null && creditReview.BvD_ID_Number__c != '' && creditReview.Requested_Credit_Limit_EUR__c != null && creditReview.Requested_Credit_Limit_EUR__c > 50000) {
        PageReference pdf = Page.CreditLimitRequestPDF;
        pdf.getParameters().put('id', creditReview.Id);
        Blob data = pdf.getContentAsPdf();
        String fileName = 'Moodys_' + creditReview.Name + '.pdf';

        ContentVersion cv = new ContentVersion(
          Title = fileName,
          PathOnClient = fileName,
          VersionData = data,
          FirstPublishLocationId = creditReview.Id
        );
        cvs.add(cv);
        }
      }      
    }

    if(cvs.size() > 0) {
      insert(cvs);
    }
  }
}