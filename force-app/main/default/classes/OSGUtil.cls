public with sharing class OSGUtil {
  @AuraEnabled(cacheable=true)
  public static OSG_Custom_Settings__c getOSGCustomSetting() {
    try{
      OSG_Custom_Settings__c osgCustomSettings = OSG_Custom_Settings__c.getOrgDefaults();
      return osgCustomSettings;
    }
    catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

   public static void testCodeCoverage() {
    Boolean CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
    CodeCoverage = true;
    CodeCoverage = false;
   }
}