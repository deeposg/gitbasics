import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getValues from "@salesforce/apex/ClassroomCourseCmpApexController.getValues";
import getClassroomValues from "@salesforce/apex/ClassroomCourseCmpApexController.getClassroomValues";
import SaveRecord from "@salesforce/apex/ClassroomCourseCmpApexController.SaveRecord";
import { refreshApex } from "@salesforce/apex";

export default class ClassroomCourse extends LightningElement {
  showClassroomTable = false;
  hasRecords = false;
  hasNoRecords = false;
  showSpinner = false;
  serviceAppointmentOptions = [];
  values;
  selectedQuoteId;
  distanceLearning;
  serviceId;
  serviceApptId;
  wiredResult;
  refreshData = 0;

  @api recordId;
  @wire(getValues, {
    quoteId: "$recordId",
    ProductFamily1: "Courses",
    ProductFamily2: "Evaluations",
    DeliveryMethod: "Classroom",
    refreshData: "$refreshData"
  })
  wiredValues(result) {
    this.showSpinner = true;
    this.wiredResult = result;
    if (result.data) {
      this.values = result.data;
      console.log("values", this.values);
      this.hasRecord = this.values.length === 0;
    } else if (result.error) {
      console.error(result.error);
    }
    this.showSpinner = false;
  }

  handleClick(event) {
    event.preventDefault();
    const quoteLineId = event.target.dataset.id;
    const quoteLineUrl = `/lightning/r/SBQQ__QuoteLine__c/${quoteLineId}/view`;
    window.open(quoteLineUrl, "_blank", "noopener,noreferrer");
  }

  showClassroomTableHandler(event) {
    this.showClassroomTable = true;
    const dataId = event.currentTarget.dataset.id;
    this.selectedQuoteId = event.currentTarget.dataset.label;
    this.distanceLearning = event.currentTarget.dataset.record;
    console.log(
      "Params to get classroom values",
      dataId,
      this.selectedquoteId,
      this.distanceLearning
    );
    getClassroomValues({
      courseprodLine: dataId,
      ProdFamily1: "Courses",
      ProdFamily2: "Evaluations",
      DelMethod: "Classroom",
      DistanceLearning: this.distanceLearning
    })
      .then((result) => {
        this.values = result;
        this.serviceAppointmentOptions = result;
        console.log("Options are:", this.serviceAppointmentOptions);
        console.log("Classroom values", this.values);
        this.hasNoRecord = result.length === 0;
        console.log((this.hasNoRecord = result.length === 0));
      })
      .catch((error) => {
        console.error(error);
      });
  }

  goBackHandler() {
    this.hasNoRecord = false;
    this.showClassroomTable = false;
    this.refreshData++;
    console.log("wired result before refresh:", this.wiredResult);
    refreshApex(this.wiredResult)
      .then(() => {
        console.log("Refreshed");
      })
      .catch((error) => {
        console.error(error);
      });
  }

  saveAptNumber(event) {
    this.showSpinner = true;
    this.serviceId = event.currentTarget.dataset.id;
    console.log(
      "quoteID",
      this.selectedQuoteId,
      "serviceapptID",
      this.serviceId
    );
    SaveRecord({ QuoteId: this.selectedQuoteId, ServiceAppId: this.serviceId })
      .then((result) => {
        console.log("Saves Service Appointment", result);
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Service Appointment selected successfully!",
            variant: "success"
          })
        );

        this.showClassroomTable = false;
        this.refreshData++;
        console.log("wired result before refresh:", this.wiredResult);
        refreshApex(this.wiredResult);
      })
      .catch((error) => {
        this.showSpinner = false;
        console.error("error", error);
      });
  }

  get serviceAppointments() {
    return this.serviceAppointmentOptions;
  }
}
