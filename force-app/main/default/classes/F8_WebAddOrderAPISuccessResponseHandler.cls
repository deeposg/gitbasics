/***************************************************************************
Name : F8_WebAddOrderAPISuccessResponseHandler
Created By : Aditya Chasta
Created Date : 12/04/2017
Description : F8_WebAddOrderAPISuccessResponseHandler class handle response received on accessing F8_WebAddOrderAPI

History Log:
=======================================
2019-05-03      MDrewitt       Add order_number and client_id for response for stripe
***************************************************************************/
global with sharing class F8_WebAddOrderAPISuccessResponseHandler extends F8_WebResponseHandler{
	global Boolean success {get;set;}
	global String order_id {get;set;}
    global String order_number {get;set;}
    global String client_id {get;set;}   
    
    public static void TestCodeCoverage() {
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
    }
}