import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";

import checkAttendee from "@salesforce/apex/AttendeeSwapToolHandler.checkAttendee";
import getContactsByString from "@salesforce/apex/AttendeeSwapToolHandler.getContactsByString";
import swapAttendeeContact from "@salesforce/apex/AttendeeSwapToolHandler.swapAttendeeContact";

export default class AttendeeSwapTool extends LightningElement {
  errorMessage;
  attendeeData;
  attendeeDataResult;
  accountId;
  searchQuery;
  currentContactId = "";
  contacts;
  newContactId;
  showInput = false;
  addContact = false;
  showSpinner = false;

  @api recordId;

  @wire(checkAttendee, { attendeeId: "$recordId" })
  checkAttendee(result) {
    this.showSpinner = true;
    this.attendeeData = result.data;
    this.attendeeDataResult = result;

    if (result.data) {
      if (this.attendeeData.length > 0) {
        this.clearError();
        if (this.attendeeData[0].Contact__c) {
          this.currentContactId = this.attendeeData[0].Contact__c;
        }
        this.accountId = this.attendeeData[0].Order_Product__r.Account__c;
        this.showInput = true;
      } else {
        this.errorMessage = "Attendee cannot be swapped!";
      }
    } else {
      this.errorMessage = "Error occured! Contact your administator.";
    }
    this.showSpinner = false;
  }

  getContacts() {
    this.showSpinner = true;
    getContactsByString({
      accId: this.accountId,
      searchQuery: this.searchQuery,
      ignoreContactId: this.currentContactId
    })
      .then((result) => {
        this.contacts = result;
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      });
  }

  handleKeyChange(event) {
    this.clearError();
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;

    this.delayTimeout = setTimeout(() => {
      console.log(searchKey);
      this.searchQuery = searchKey;
      this.getContacts();
    }, 500);
  }

  selectContact(event) {
    event.preventDefault();
    this.newContactId = event.target.name;
    this.swapContact();
  }

  swapContact() {
    this.showSpinner = true;
    swapAttendeeContact({
      attendeeId: this.recordId,
      newContactId: this.newContactId
    })
      .then((result) => {
        if (result == true) {
          const event = new ShowToastEvent({
            title: "Attendee successfully swapped!"
          });
          this.dispatchEvent(event);
          updateRecord({ fields: { Id: this.recordId } });
          refreshApex(this.attendeeDataResult);

          this.showSpinner = false;

          const closeQA = new CustomEvent("close");
          this.dispatchEvent(closeQA);
        }
      })
      .catch((error) => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      });
  }

  showContactForm() {
    this.addContact = true;
    this.showInput = false;
    this.contacts = null;
  }

  hideContactForm() {
    this.addContact = false;
    this.showInput = true;
    this.clearError();
  }

  createContact(event) {
    this.showSpinner = true;
    const fields = event.detail.fields;
    this.template.querySelector("lightning-record-edit-form").submit(fields);
  }

  handleSuccess(event) {
    this.newContactId = event.detail.id;
    this.swapContact();
  }

  handleError(event) {
    this.showSpinner = false;
  }

  clearError() {
    this.errorMessage = "";
  }
}
