import { LightningElement, wire, api } from 'lwc';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import resetCourse from '@salesforce/apex/OsgOnlineHelper.resetCourse';
import resendRegistrationEmail from '@salesforce/apex/OsgOnlineHelper.resendRegistrationEmail';

export default class OsgOnlineUtilityTool extends LightningElement {
    userId = Id;
    showSpinner = false;
    errorMessage;
    disableResetButton = true;
    disableResendButton = true;
    activeSections = [];
    contactId;
  
    @api recordId;
  
    @wire(getRecord, {recordId: '$recordId', layoutTypes: ['Full']}) attendee({data, error}){
      if(data){
        console.log(data);
        this.clearError();
        
        //check field values to determine available actions
        if(data.fields.Theory_Status__c.value == 'Failed'){
          this.disableResetButton = false;
        }
        else{
          this.disableResetButton = true;
        }

        if(data.fields.Contact__c.value != null){
          this.contactId = data.fields.Contact__c.value;
          this.disableResendButton = false;
        }
        else{
          this.disableResendButton = true;
        }

      }
      else{
        this.errorMessage = 'Error occured! Contact your administrator.';
      }
    };
  
    resetCourseProgress(){
      this.showSpinner = true;
      this.clearError();
      
      resetCourse({attendeeId: this.recordId})
      .then(result=> {
        if(result == true){
          const event = new ShowToastEvent({
            title : 'Attendee successfully reset!'
          });
          this.dispatchEvent(event);
  
          updateRecord({fields: { Id: this.recordId } });
          this.showSpinner = false;
        }
        else{
          const event = new ShowToastEvent({
            title : 'Error occured!'
          });
          this.dispatchEvent(event);
  
          updateRecord({fields: { Id: this.recordId } });
          this.showSpinner = false;
        }
      })
      .catch(error => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      })
    }

    resendRegistrationEmail(){
      this.showSpinner = true;
      this.clearError();

      resendRegistrationEmail({contactId: this.contactId})
      .then(result => {
        if(result == true){
          const event = new ShowToastEvent({
            title : 'Attendee successfully resent email!'
          });
          this.dispatchEvent(event);
  
          updateRecord({fields: { Id: this.recordId } });
          this.showSpinner = false;
        }
        else{
          const event = new ShowToastEvent({
            title : 'Error occured!'
          });
          this.dispatchEvent(event);
  
          updateRecord({fields: { Id: this.recordId } });
          this.showSpinner = false;
        }
      })
      .catch(error => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      })
    }
  
    clearError(){
      this.errorMessage = '';
    }
}