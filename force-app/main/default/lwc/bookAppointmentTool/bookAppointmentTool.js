import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getResources from '@salesforce/apex/BookAppointmentToolHandler.getResources';
import createWorkOrder from '@salesforce/apex/BookAppointmentToolHandler.createWorkOrder';

export default class BookAppointmentTool extends NavigationMixin(LightningElement) {
    record;
    showSpinner = false;
    errorMessage;
    trainers = [];
    selectedTrainer;
    selectedTime = '08:00:00.000Z';

    @api recordId;
    
    @wire(getRecord, {recordId: '$recordId', layoutTypes: ['Full']}) quoteLine({data, error}){
        if(data){
            console.log(data.fields);
            this.record = data;
            this.clearError();
        }
        else{
            this.errorMessage = 'Error occured getting record! Contact your administrator.';
        }
    };

    @wire(getResources) resources (result){
        this.showSpinner = true;

        if(result.data){
            let values = [];
            result.data.forEach(element => {
                values.push({label: element.Name, value: element.Id});
                this.trainers = values;                                
            });
        }
        else{
            this.errorMessage = 'Error occured getting resources! Contact your administrator.';
        }

        this.showSpinner = false;
    }

    get options(){
        return this.trainers;
    }

    get preferredDate(){
        return this.record.fields.Preferred_Date_and_Time__c.value;
    }

    get trainingAddress(){
        return this.record.fields.Quote_Training_Address1__r.displayValue;
    }

    get workType(){
        return this.record.fields.Work_Type__r.displayValue;
    }

    handleChange(event){
        this.selectedTrainer = event.detail.value;
    }

    handleTimeChange(event){
        this.selectedTime = event.target.value;
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    validateData(){
        this.clearError();

        if(this.record.fields.Work_Type__r.displayValue == null || this.record.fields.Quote_Training_Address1__r.displayValue == null || this.record.fields.Preferred_Date_and_Time__c.value == null){
            this.errorMessage = 'Quote line needs a valid work type, training address and preferred date time!';
        }
        else if(this.selectedTrainer == null){
            this.errorMessage = 'Need to select a trainer!';
        }
        else if(this.record.fields.Classroom_Course__c.value != null){
            this.errorMessage = 'A service appointment already exists!';
        }
        else{
            this.createClassRecord();
        }
    }

    createClassRecord(){
        this.showSpinner = true;
        this.clearError();

        var selectedDateTime = this.record.fields.Preferred_Date_and_Time__c.value.split('T')[0] + 'T' + this.selectedTime + 'Z';

        createWorkOrder({
            quoteLineId : this.recordId, 
            serviceResourceId : this.selectedTrainer,
            trainingAddressId : this.record.fields.Quote_Training_Address1__c.value,
            workTypeId : this.record.fields.Work_Type__c.value,
            startDateTime : selectedDateTime,
            accountId : this.record.fields.Account__c.value
        })
        .then(result => {
            if(!result.includes('CONFLICT')){
                this.closeAction();
                this.showSpinner = false;

                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        actionName: 'view',
                    },
                }).then((url) => {
                    const event = new ShowToastEvent({
                        title: 'Success!',
                        message: '{0} {1}!',
                        messageData: [
                            'Service Appointment created!',
                            {
                                url,
                                label: 'Click here to open',
                            },
                        ],
                    });
                    this.dispatchEvent(event);
                })
                .catch(error => {
                    console.log(error);
                    this.errorMessage = error.body.message;
                });
            }
            else{
                this.showSpinner = false;
                if(result.includes('CONFLICT')){
                    var message = result.split(" - ")[1];
                    this.errorMessage = message;
                }
                else{
                    console.log('NO RESULT');
                    console.log(result);
                    this.errorMessage = 'Error occured during creation! Contact your administrator.';
                }
            }
        })
        .catch(error => {
            console.log('ERROR CREATING WORK ORDER');
            this.showSpinner = false;
            this.errorMessage = error.body.message;
        })
    }

    clearError(){
        this.errorMessage = '';
    }
}