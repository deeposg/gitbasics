import { LightningElement, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import {refreshApex} from '@salesforce/apex';

import checkAttendee from '@salesforce/apex/Jhsc2AssignmentTool.checkAttendee';
import getJHSC2DLAppointments from '@salesforce/apex/Jhsc2AssignmentTool.getJHSC2DLAppointments';
import assignAttendee from '@salesforce/apex/Jhsc2AssignmentTool.assignAttendee';

export default class Jhsc2AssignmentToolLWC extends LightningElement {
  errorMessage;
  attendeeData;
  attendeeDataResult;
  serviceAppointmentId;
  orderItemId;
  serviceAppointments;
  showSpinner = false;
  showAppointments = false;

  @api recordId;

  @wire(checkAttendee, {recordId: '$recordId'}) checkAttendee (result){
    this.showSpinner = true;
    this.attendeeData = result.data;
    this.attendeeDataResult = result;

    if(result.data){
      if(this.attendeeData.length > 0){
        this.clearError();
        this.orderItemId = this.attendeeData[0].Order_Product__c;
        this.getValidAppointments();
      }
      else{
        this.errorMessage = "Attendee cannot be assigned! Ensure contact has valid mailing address and email!";  
      }
    }
    else{
      this.errorMessage = "Error occured! Contact your administrator.";
    }
    this.showSpinner = false;
  };

  getValidAppointments(){
    getJHSC2DLAppointments()
    .then(result => {
      console.log(result);
      if(result.length > 0){
        this.serviceAppointments = result;
      }
      else{
        this.errorMessage = 'No JHSCII Service Appointments with space remaining!';
      }
    })
    .catch(error => {
      this.errorMessage = error.body.message;
    })
  }

  selectAppointment(event){
    event.preventDefault();
    this.serviceAppointmentId = event.target.name;
    this.assignAttendee();
  }

  assignAttendee(){
    this.showSpinner = true;

    assignAttendee({attendeeId: this.recordId, orderProductId: this.orderItemId, saId: this.serviceAppointmentId})
    .then(result => {
      if(result == true){
        const event = new ShowToastEvent({
          title: 'Attendee successfully assigned!'
          });
        this.dispatchEvent(event);

        updateRecord({ fields: { Id: this.recordId } });

        this.showSpinner = false;
      }
    })
    .catch(error => {
      this.showSpinner = false;
      this.errorMessage = error.body.message;
    });
  }

  updateRecordView(recordId) {
    updateRecord({fields: { Id: recordId }});
  }

  clearError(){
    this.errorMessage = '';
  }
}