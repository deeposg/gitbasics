import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getServiceAppointments from '@salesforce/apex/AttendeeTransferToolHandler.getServiceAppointments';
import transferAttendees from '@salesforce/apex/AttendeeTransferToolHandler.transferAttendees';

export default class AttendeeTransferTool extends LightningElement {
    numberOfAttendees;
    productId;
    showSpinner = false;
    serviceAppointments;
    newServiceAppointmentId;
    showButton = false;
    errorMessage;
  
    @api recordId;
  
    @wire(getRecord, {recordId: '$recordId', layoutTypes: ['Full']}) serviceAppointment;
  
    handleNumberChange(event){
      this.clearError();
      this.numberOfAttendees = event.target.value;
  
      if(this.numberOfAttendees > 0){
        this.showButton = true;
      }
      else{
        this.showButton = false;
      }
    }
  
    getServiceAppointments(event){
      this.showSpinner = true;
      this.productId = this.serviceAppointment.data.fields.Product__c.value;
      console.log(this.serviceAppointment.data.fields);
  
      getServiceAppointments({numberOfAttendees: this.numberOfAttendees, productId: this.productId, ignoreSAId: this.recordId})
      .then(result => {
        if(result.length > 0){
          this.serviceAppointments = result;
        }
        else{
          this.errorMessage = 'No Service Appointments with ' + this.numberOfAttendees + ' spaces remaining!';
        }
        this.showSpinner = false;
      })
      .catch(error => {
        this.errorMessage = error.body.message;
        this.showSpinner = false;
      })
    }
  
    selectAppointment(event){
      event.preventDefault();
      this.newServiceAppointmentId = event.target.name;
      this.transferAttendees();
    }
  
    transferAttendees(){
      console.log('OLD SA:' + this.recordId);
      console.log('NEW SA:' + this.newServiceAppointmentId);
  
      this.showSpinner = true;
  
      transferAttendees({oldSAId: this.recordId, newSAId: this.newServiceAppointmentId, numberOfAttendees: this.numberOfAttendees})
      .then(result => {
        
        var numberOfAttendeesMoved = result;
  
        const event = new ShowToastEvent({
          title: numberOfAttendeesMoved + ' attendees moved!'
        });
        this.dispatchEvent(event);
        
        this.serviceAppointments = null;
        this.numberOfAttendees = null;
        this.showButton = false;
        
        updateRecord({fields: { Id: this.recordId }});

        this.showSpinner = false;

        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
      })
      .catch(error => {
        console.log(error);
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      });
    }
  
    clearError(){
      this.errorMessage = '';
    }

    resetComponent(){
      this.numberOfAttendees = null;
      this.serviceAppointments = null;
      this.showButton = false;
    }
}