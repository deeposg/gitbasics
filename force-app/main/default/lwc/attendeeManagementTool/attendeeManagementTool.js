import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getContactsByString from "@salesforce/apex/AttendeeMangementCmpApexClass.getContactsByString";
import getAttLst from "@salesforce/apex/AttendeeMangementCmpApexClass.getAttLst";
import reviseAttendee from "@salesforce/apex/AttendeeMangementCmpApexClass.reviseAttendee";

export default class attendeeManagementTool extends LightningElement {
  errorMessage;
  accountId;
  selectedAttdId;
  quoteId;
  searchQuery;
  currentContactId = "";
  contacts;
  newContactId;
  attendeeDataResult;
  _options = [];
  _attendeeList = [];
  showSpinner = false;

  @api recordId;
  @wire(getRecord, { recordId: "$recordId", layoutTypes: ["Full"] })
  quoteLine({ data, error, result }) {
    this.showSpinner = true;
    this.attendeeDataResult = result;
    console.log("result", this.attendeeDataResult);
    if (data) {
      this.clearError();
      console.log("data is", data);
      this.record = data;
      this.accountId = data.fields.SBQQ__Account__c.value;
      this.quoteId = data.id;
      console.log("Acc ID: ", data.fields.SBQQ__Account__c.value);
      getAttLst({ RecordId: this.recordId })
        .then((result) => {
          console.log(result, "new result");
          // Grouping the Attendees based on Quote Line
          const groupAtt = [];
          let group = [];
          let current = result[0].Quote_Line__c;
          for (const att of result) {
            if (att.Quote_Line__c == current) {
              if (group.length != 0) {
                delete att.Quote_Line__c;
                group.push(att);
              } else {
                group.push(att);
              }
            } else {
              current = att.Quote_Line__c;
              groupAtt.push(group);
              group = [];
              if (group.length != 0) {
                delete att.Quote_Line__c;
                group.push(att);
              } else {
                group.push(att);
              }
            }
          }
          groupAtt.push(group);
          this._attendeeList = groupAtt;
          console.log("Grouped Att list:", groupAtt);
        })
        .catch((exception) => {
          console.log("first api error", exception);
        });
    }
    this.showSpinner = false;
  }

  getAttLstData() {
    getAttLst({ accId: this.accountId })
      .then((result) => {
        console.log("Result based on search query ", result);
      })
      .catch((error) => {
        console.log("The error is ", error);
      });
  }

  getContacts(searchKeyValue) {
    console.log(
      "Account id is:",
      this.accountId,
      "search query:",
      searchKeyValue
    );
    this.getAttLstData();
    getContactsByString({
      accId: this.accountId,
      searchQuery: searchKeyValue,
      ignoreContactId: this.currentContactId
    })
      .then((result) => {
        this.contacts = result;
        console.log("The result is ", result);
        this._options = result.map((item) => {
          return { label: `${item.Name}`, value: `${item.Id}` };
        });
        console.log("Options are:", this._options);
      })
      .catch((error) => {
        this.errorMessage = error.body.message;
      });
  }

  handleKeyChange(event) {
    this.selectedAttdId = event.target.dataset.id;
    this.clearError();
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    console.log("searchkey from handle change", searchKey);
    this.delayTimeout = setTimeout(() => {
      if (searchKey) {
        this.getContacts(searchKey);
      } else {
        this._options = [];
      }
    }, 250);
  }

  async handleClick(event) {
    try {
      const contactId = event.currentTarget.value;
      console.log("Current selection:", event.currentTarget.value);
      console.log("Quote ID is: ", this.recordId);
      if (contactId) {
        this.showSpinner = true;
        const result = await reviseAttendee({
          attendeeId: this.selectedAttdId,
          newContactId: contactId
        });
        if (result == true) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Attendee updated",
              variant: "success"
            })
          );
        }
        await updateRecord({ fields: { Id: this.recordId } });
        await refreshApex(this.attendeeDataResult);
        this.showSpinner = false;
        console.log("Attendee updated", result);
      }
    } catch (exception) {
      this.showSpinner = false;
    }
  }

  handleError(event) {
    this.showSpinner = false;
  }

  clearError() {
    this.errorMessage = "";
  }

  get tempAttendees() {
    return this._attendeeList || {};
  }
}
