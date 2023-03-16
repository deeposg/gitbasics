public with sharing class DashfullyViewApexController {

    @AuraEnabled
    public static List<String> getSessionDetails () {
        List<String> sessionDetails = new List<String>();
        
        sessionDetails.add( UserInfo.getSessionId() );
        sessionDetails.add( UserInfo.getOrganizationId() );
        sessionDetails.add( URL.getSalesforceBaseUrl().toExternalForm() );
        
        return sessionDetails;
    }
}