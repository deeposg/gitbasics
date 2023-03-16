import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import returnEndTime from '@salesforce/apex/BookAppointmentToolHandler.returnEndTime';
import adjustSAScheduledTime from '@salesforce/apex/BookAppointmentToolHandler.adjustSAScheduledTime';

export default class ChangeAppointmentTimeTool extends LightningElement {
    record;
    showSpinner = false;
    errorMessage;
    selectedStartDatetime;
    selectedEndDatetime;
    disableEndDatetime = true;
    allowTimeChange = false;

    @api recordId;

    @wire(getRecord, {recordId: '$recordId', layoutTypes: ['Full']}) serviceAppointment({data, error}){
        if(data){
            this.record = data;
            this.clearError();

            this.allowTimeChange = data.fields.Allow_Scheduled_Time_Override__c.value;

            this.selectedStartDatetime = data.fields.SchedStartTime.value;
            this.selectedEndDatetime = data.fields.SchedEndTime.value;
        }
        else{
            this.errorMessage = 'Error occured getting record! Contact your administrator.';
        }
    };


    clearError(){
        this.errorMessage = '';
    }

    handleOverrideToggle(event){
        this.disableEndDatetime = !this.disableEndDatetime;
    }

    handleStartDateTimeChange(event){
        this.selectedStartDatetime = event.target.value;
        this.calculateEndDateTime();
    }

    handleEndDateTimeChange(event){
        this.selectedEndDatetime = event.target.value;
    }

    calculateEndDateTime(){
        this.showSpinner = true;
        
        returnEndTime({startDatetimeGMT: this.selectedStartDatetime, saId: this.recordId})
        .then(result => {
            this.selectedEndDatetime = result;
            this.showSpinner = false;
        })
        .catch(error => {
            this.errorMessage = error.body.message;
            this.showSpinner = false;
        })
    }

    validateData(){
        this.showSpinner = true;

        adjustSAScheduledTime({saId: this.recordId, newStartDatetimeGMT: this.selectedStartDatetime, newEndDatetimeGMT: this.selectedEndDatetime})
        .then(result => {
            this.showSpinner = false;

            if(result == true){
                const event = new ShowToastEvent({
                    title: 'Scheduled Time updated!'
                  });
                  this.dispatchEvent(event);

                updateRecord({fields: { Id: this.recordId }});

                const closeQA = new CustomEvent('close');
                this.dispatchEvent(closeQA);
            }
            else{
                this.errorMessage = 'Error occured while updating time of Service Appointment!';
            }
        })
        .catch(error => {
            console.log(error);
            this.errorMessage = error.body.message;
            this.showSpinner = false;
        })
    }
}