/***************************************************************************
Name : ErrorResponseHandler
Created By : Aditya Chasta
Created Date : 06/13/2017
Description : ErrorResponseHandler class handle error response received on accessing API
***************************************************************************/
global class F8_WebErrorResponseHandler extends F8_WebResponseHandler {
    public Boolean error {get; set;}
    public String error_id {get;set;}
    public String message {get;set;}
}