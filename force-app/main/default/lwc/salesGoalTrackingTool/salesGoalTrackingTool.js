import { api, LightningElement, wire } from "lwc";
import { updateRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import Id from "@salesforce/user/Id";
import getFiscalQuarterSales from "@salesforce/apex/SalesGoalTrackingTool.getFiscalQuarterSales";
import getPreviousFiscalYearSales from "@salesforce/apex/SalesGoalTrackingTool.getPreviousFiscalYearSales";
import getFiscalMonthlySales from "@salesforce/apex/SalesGoalTrackingTool.getFiscalMonthlySales";
import getAccountInfo from "@salesforce/apex/SalesGoalTrackingTool.getAccountInfo";
import setAccountFiscalPeriods from "@salesforce/apex/SalesGoalTrackingTool.setAccountFiscalPeriods";
import getCurrentFiscalQuarter from "@salesforce/apex/SalesGoalTrackingTool.getCurrentFiscalQuarter";
import getCurrentFiscalYear from "@salesforce/apex/SalesGoalTrackingTool.getCurrentFiscalYear";
import getPendingSalesGoalRequest from "@salesforce/apex/SalesGoalTrackingTool.getPendingSalesGoalRequest";
import setSalesGoalRequest from "@salesforce/apex/SalesGoalTrackingTool.setSalesGoalRequest";
import approveSalesGoalRequest from "@salesforce/apex/SalesGoalTrackingTool.approveSalesGoalRequest";

export default class SalesGoalTrackingTool extends LightningElement {
  adminUserIds = ["00546000000urMDAAY", "00546000000ufVcAAI"];
  showAdminApproval = false;
  //00546000000ufVcAAI
  userId = Id;
  showSpinner = false;
  errorMessage;
  hasGoal = false;
  wireFiscalQuarterAccountId;
  wireFiscalMonthAccountId;
  wireFiscalYearAccountId;
  account;
  accountResult;
  fiscalQuarterlySales;
  previousFiscalYearlySales;

  previousFY1Name;
  previousFY2Name;
  previousFY3Name;
  previousFY1 = 0;
  previousFY2 = 0;
  previousFY3 = 0;

  fq1Goal = 0;
  fq2Goal = 0;
  fq3Goal = 0;
  fq4Goal = 0;
  fyGoal = 0;
  fq1 = 0;
  fq2 = 0;
  fq3 = 0;
  fq4 = 0;
  fy = 0;
  fq1Progress = 0;
  fq2Progress = 0;
  fq3Progress = 0;
  fq4Progress = 0;
  fyProgress = 0;
  fq1RingProgress = 0;
  fq2RingProgress = 0;
  fq3RingProgress = 0;
  fq4RingProgress = 0;
  fyRingProgress = 0;
  fq1RingVariant = "base-autocomplete";
  fq2RingVariant = "base-autocomplete";
  fq3RingVariant = "base-autocomplete";
  fq4RingVariant = "base-autocomplete";
  fyRingVariant = "base-autocomplete";

  m1 = 0;
  m2 = 0;
  m3 = 0;
  m4 = 0;
  m5 = 0;
  m6 = 0;
  m7 = 0;
  m8 = 0;
  m9 = 0;
  m10 = 0;
  m11 = 0;
  m12 = 0;

  cfqM1Name;
  cfqM2Name;
  cfqM3Name;
  cfqName;
  cfqM1Goal = 0;
  cfqM2Goal = 0;
  cfqM3Goal = 0;
  cfqGoal = 0;
  cfqM1 = 0;
  cfqM2 = 0;
  cfqM3 = 0;
  cfq = 0;
  cfqM1Progress = 0;
  cfqM2Progress = 0;
  cfqM3Progress = 0;
  cfqProgress = 0;
  cfqM1RingProgress = 0;
  cfqM2RingProgress = 0;
  cfqM3RingProgress = 0;
  cfqRingProgress = 0;
  cfqM1RingVariant = "base-autocomplete";
  cfqM2RingVariant = "base-autocomplete";
  cfqM3RingVariant = "base-autocomplete";
  cfqRingVariant = "base-autocomplete";

  fiscalQuarter;
  fiscalQuarterLabel;
  fiscalQuarterValue;
  fiscalYear;
  fiscalYearValue;
  fyTimeProgress;
  fyDaysCompleted;
  daysToQuarterEnd;
  daysToYearEnd;

  fqEndDaysThreshold = 21;
  fqEndProgressThreshold = 85;
  showGoalForm = false;
  lastFiscalYearSales = 0;

  requestedSalesGoal = 0;
  pendingRequestedSalesGoal;
  hasPendingGoal = false;

  displayCurrentFQ = false;

  @api recordId;

  @wire(getAccountInfo, { accountId: "$recordId" })
  accountInfo(result) {
    this.showSpinner = true;
    this.account = result.data;
    this.accountResult = result;
    this.wireFiscalMonthAccountId = this.recordId;

    if (result.data) {
      this.clearError();
      if (this.account.Fiscal_Year_Goal__c != null) {
        this.hasGoal = true;

        this.fq1Goal = this.account.Fiscal_Q1_Goal__c;
        this.fq2Goal = this.account.Fiscal_Q2_Goal__c;
        this.fq3Goal = this.account.Fiscal_Q3_Goal__c;
        this.fq4Goal = this.account.Fiscal_Q4_Goal__c;
        this.fyGoal = this.account.Fiscal_Year_Goal__c;
      }

      if (this.account.Last_Fiscal_Year__c != null) {
        //this.lastFiscalYearSales = this.account.Last_Fiscal_Year__c;
        //this.requestedSalesGoal = Math.round(this.account.Last_Fiscal_Year__c * 1.15);
      }
    } else {
      this.errorMessage = "Error occured! Contact your administrator.";
    }
    this.showSpinner = false;
  }

  @wire(getPendingSalesGoalRequest, { accountId: "$recordId" })
  pendingSalesGoalRequest(result) {
    if (result.data) {
      this.pendingRequestedSalesGoal = result.data;
      this.hasPendingGoal = true;
    }
  }

  @wire(getFiscalMonthlySales, { accountId: "$wireFiscalMonthAccountId" })
  fiscalMonthlySales(result) {
    this.showSpinner = true;
    this.wireFiscalQuarterAccountId = this.recordId;

    if (result.data) {
      this.clearError();
      let currentMonth = new Date().getMonth() + 1;

      result.data.forEach((element) => {
        if (element.CM == 1 && element.CM == currentMonth) {
          this.m1 = element.total_sales;
        }
        if (element.CM == 2 && element.CM == currentMonth) {
          this.m2 = element.total_sales;
        }
        if (element.CM == 3 && element.CM == currentMonth) {
          this.m3 = element.total_sales;
        }
        if (element.CM == 4 && element.CM == currentMonth) {
          this.m4 = element.total_sales;
        }
        if (element.CM == 5 && element.CM == currentMonth) {
          this.m5 = element.total_sales;
        }
        if (element.CM == 6 && element.CM == currentMonth) {
          this.m6 = element.total_sales;
        }
        if (element.CM == 7 && element.CM == currentMonth) {
          this.m7 = element.total_sales;
        }
        if (element.CM == 8 && element.CM == currentMonth) {
          this.m8 = element.total_sales;
        }
        if (element.CM == 9 && element.CM == currentMonth) {
          this.m9 = element.total_sales;
        }
        if (element.CM == 10 && element.CM == currentMonth) {
          this.m10 = element.total_sales;
        }
        if (element.CM == 11 && element.CM == currentMonth) {
          this.m11 = element.total_sales;
        }
        if (element.CM == 12 && element.CM == currentMonth) {
          this.m12 = element.total_sales;
        }

        //reset monthly values back to account values
        if (currentMonth != 1) {
          this.m1 = this.account.January_Sales__c;
        }
        if (currentMonth != 2) {
          this.m2 = this.account.February_Sales__c;
        }
        if (currentMonth != 3) {
          this.m3 = this.account.March_Sales__c;
        }
        if (currentMonth != 4) {
          this.m4 = this.account.April_Sales__c;
        }
        if (currentMonth != 5) {
          this.m5 = this.account.May_Sales__c;
        }
        if (currentMonth != 6) {
          this.m6 = this.account.June_Sales__c;
        }
        if (currentMonth != 7) {
          this.m7 = this.account.July_Sales__c;
        }
        if (currentMonth != 8) {
          this.m8 = this.account.August_Sales__c;
        }
        if (currentMonth != 9) {
          this.m9 = this.account.September_Sales__c;
        }
        if (currentMonth != 10) {
          this.m10 = this.account.October_Sales__c;
        }
        if (currentMonth != 11) {
          this.m11 = this.account.November_Sales__c;
        }
        if (currentMonth != 12) {
          this.m12 = this.account.December_Sales__c;
        }
      });

      //set current quarter month values
      if (this.fiscalQuarterValue == 1) {
        this.cfqM1 = this.m9;
        this.cfqM1Name = "September";
        this.cfqM1Goal = this.account.September_Goal__c;

        this.cfqM2 = this.m10;
        this.cfqM2Name = "October";
        this.cfqM2Goal = this.account.October_Goal__c;

        this.cfqM3 = this.m11;
        this.cfqM3Name = "November";
        this.cfqM3Goal = this.account.November_Goal__c;
      } else if (this.fiscalQuarterValue == 2) {
        this.cfqM1 = this.m12;
        this.cfqM1Name = "December";
        this.cfqM1Goal = this.account.December_Goal__c;

        this.cfqM2 = this.m1;
        this.cfqM2Name = "January";
        this.cfqM2Goal = this.account.January_Goal__c;

        this.cfqM3 = this.m2;
        this.cfqM3Name = "February";
        this.cfqM3Goal = this.account.February_Goal__c;
      } else if (this.fiscalQuarterValue == 3) {
        this.cfqM1 = this.m3;
        this.cfqM1Name = "March";
        this.cfqM1Goal = this.account.March_Goal__c;

        this.cfqM2 = this.m4;
        this.cfqM2Name = "April";
        this.cfqM2Goal = this.account.April_Goal__c;

        this.cfqM3 = this.m5;
        this.cfqM3Name = "May";
        this.cfqM3Goal = this.account.May_Goal__c;
      } else if (this.fiscalQuarterValue == 4) {
        this.cfqM1 = this.m6;
        this.cfqM1Name = "June";
        this.cfqM1Goal = this.account.June_Goal__c;

        this.cfqM2 = this.m7;
        this.cfqM2Name = "July";
        this.cfqM2Goal = this.account.July_Goal__c;

        this.cfqM3 = this.m8;
        this.cfqM3Name = "August";
        this.cfqM3Goal = this.account.August_Goal__c;
      }

      this.updateAccountFiscalPeriods();
    } else {
      this.errorMessage = "Error occured! Contact your administrator.";
    }
    this.showSpinner = false;
  }

  @wire(getFiscalQuarterSales, { accountId: "$wireFiscalQuarterAccountId" })
  fiscalQuarterSales(result) {
    this.showSpinner = true;
    this.fiscalQuarterlySales = result.data;
    this.wireFiscalYearAccountId = this.recordId;

    if (result.data) {
      this.clearError();
      result.data.forEach((element) => {
        if (element.FQ == 1 && element.FQ == this.fiscalQuarterValue) {
          this.fq1 = element.total_sales;
        }
        if (element.FQ == 2 && element.FQ == this.fiscalQuarterValue) {
          this.fq2 = element.total_sales;
        }
        if (element.FQ == 3 && element.FQ == this.fiscalQuarterValue) {
          this.fq3 = element.total_sales;
        }
        if (element.FQ == 4 && element.FQ == this.fiscalQuarterValue) {
          this.fq4 = element.total_sales;
        }
      });

      //reset fq values back to account values
      if (this.fiscalQuarterValue != 1) {
        this.fq1 = this.account.Fiscal_Q1_Sales__c;
      }
      if (this.fiscalQuarterValue != 2) {
        this.fq2 = this.account.Fiscal_Q2_Sales__c;
      }
      if (this.fiscalQuarterValue != 3) {
        this.fq3 = this.account.Fiscal_Q3_Sales__c;
      }
      if (this.fiscalQuarterValue != 4) {
        this.fq4 = this.account.Fiscal_Q4_Sales__c;
      }

      //set the current fiscal quarter values + progress
      if (this.fiscalQuarterValue == 1) {
        this.cfq = this.fq1;
        this.cfqName = "Q1";
        this.cfqGoal = this.fq1Goal;
      } else if (this.fiscalQuarterValue == 2) {
        this.cfq = this.fq2;
        this.cfqName = "Q2";
        this.cfqGoal = this.fq2Goal;
      } else if (this.fiscalQuarterValue == 3) {
        this.cfq = this.fq3;
        this.cfqName = "Q3";
        this.cfqGoal = this.fq3Goal;
      } else if (this.fiscalQuarterValue == 4) {
        this.cfq = this.fq4;
        this.cfqName = "Q4";
        this.cfqGoal = this.fq4Goal;
      }

      this.fy = this.fq1 + this.fq2 + this.fq3 + this.fq4;

      this.setRingVariants();
    } else {
      this.errorMessage = "Error occured! Contact your administrator.";
    }
    this.showSpinner = false;
  }

  @wire(getPreviousFiscalYearSales, { accountId: "$wireFiscalYearAccountId" })
  previousFiscalYearSales(result) {
    this.showSpinner = true;
    let i = 0;

    this.previousFY1Name = this.fiscalYearValue - 1;
    this.previousFY2Name = this.fiscalYearValue - 2;
    this.previousFY3Name = this.fiscalYearValue - 3;

    if (result.data) {
      this.previousFiscalYearlySales = result.data;
      result.data.forEach((element) => {
        if (element.FY == this.previousFY1Name) {
          this.previousFY1 = element.total_sales;
        } else if (element.FY == this.previousFY2Name) {
          this.previousFY2 = element.total_sales;
        } else if (element.FY == this.previousFY3Name) {
          this.previousFY3 = element.total_sales;
        }
      });

      this.requestedSalesGoal = Math.round(this.previousFY1 * 1.15);
    } else {
      this.errorMessage = "Error occured! Contact your administrator.";
    }
    this.showSpinner = false;
  }

  normalizeValue(progressValue) {
    progressValue = progressValue * 100;
    if (progressValue > 100) {
      return 100;
    } else {
      return Math.round(progressValue);
    }
  }

  setRingVariants() {
    //process quarterly sales to determine quarterly sales vs goals
    this.fiscalQuarterlySales.forEach((element) => {
      if (element.FQ == 1) {
        if (this.fq1 > 0) {
          this.fq1Progress = Math.round((this.fq1 / this.fq1Goal) * 100);
          this.fq1RingProgress = this.normalizeValue(this.fq1 / this.fq1Goal);
        }
      } else if (element.FQ == 2) {
        if (this.fq2 > 0) {
          this.fq2Progress = Math.round((this.fq2 / this.fq2Goal) * 100);
          this.fq2RingProgress = this.normalizeValue(this.fq2 / this.fq2Goal);
        }
      } else if (element.FQ == 3) {
        if (this.fq3 > 0) {
          this.fq3Progress = Math.round((this.fq3 / this.fq3Goal) * 100);
          this.fq3RingProgress = this.normalizeValue(this.fq3 / this.fq3Goal);
        }
      } else if (element.FQ == 4) {
        if (this.fq4 > 0) {
          this.fq4Progress = Math.round((this.fq4 / this.fq4Goal) * 100);
          this.fq4RingProgress = this.normalizeValue(this.fq4 / this.fq4Goal);
        }
      }
    });

    this.fyProgress = Math.round((this.fy / this.fyGoal) * 100);
    this.fyRingProgress = this.normalizeValue(this.fy / this.fyGoal);

    //set current fiscal quarter months progress
    this.cfqM1Progress = Math.round((this.cfqM1 / this.cfqM1Goal) * 100);
    this.cfqM1RingProgress = this.normalizeValue(this.cfqM1 / this.cfqM1Goal);

    this.cfqM2Progress = Math.round((this.cfqM2 / this.cfqM2Goal) * 100);
    this.cfqM2RingProgress = this.normalizeValue(this.cfqM2 / this.cfqM2Goal);

    this.cfqM3Progress = Math.round((this.cfqM3 / this.cfqM3Goal) * 100);
    this.cfqM3RingProgress = this.normalizeValue(this.cfqM3 / this.cfqM3Goal);

    this.cfqProgress = Math.round((this.cfq / this.cfqGoal) * 100);
    this.cfqRingProgress = this.normalizeValue(this.cfq / this.cfqGoal);

    if (this.cfqRingProgress < 100) {
      this.cfqRingVariant = "active-step";
    }

    let currentMonth = new Date().getMonth() + 1;
    if (
      currentMonth == 9 ||
      currentMonth == 12 ||
      currentMonth == 3 ||
      currentMonth == 6
    ) {
      if (this.cfqM1RingProgress < 100) {
        this.cfqM1RingVariant = "active-step";
      }
    }

    if (
      currentMonth == 10 ||
      currentMonth == 1 ||
      currentMonth == 4 ||
      currentMonth == 7
    ) {
      if (this.cfqM1RingProgress < 100) {
        this.cfqM1RingVariant = "expired";
      }

      if (this.cfqM2RingProgress < 100) {
        this.cfqM2RingVariant = "active-step";
      }
    }

    if (
      currentMonth == 11 ||
      currentMonth == 2 ||
      currentMonth == 5 ||
      currentMonth == 8
    ) {
      if (this.cfqM1RingProgress < 100) {
        this.cfqM1RingVariant = "expired";
      }
      if (this.cfqM2RingProgress < 100) {
        this.cfqM2RingVariant = "expired";
      }

      if (this.cfqM3RingProgress < 100) {
        this.cfqM3RingVariant = "active-step";
      }
    }

    //set ring variants
    if (this.fiscalQuarterValue == 1) {
      if (this.fq1RingProgress < 100) {
        this.fq1RingVariant = "active-step";
      }

      if (
        this.daysToQuarterEnd < this.fqEndDaysThreshold &&
        this.fq1RingProgress < this.fqEndProgressThreshold
      ) {
        this.fq1RingVariant = "warning";
      }
    } else if (this.fiscalQuarterValue == 2) {
      if (this.fq1RingProgress < 100) {
        this.fq1RingVariant = "expired";
      }

      if (this.fq2RingProgress < 100) {
        this.fq2RingVariant = "active-step";
      }

      if (
        this.daysToQuarterEnd < this.fqEndDaysThreshold &&
        this.fq2RingProgress < this.fqEndProgressThreshold
      ) {
        this.fq2RingVariant = "warning";
      }
    } else if (this.fiscalQuarterValue == 3) {
      if (this.fq2RingProgress < 100) {
        this.fq2RingVariant = "expired";
      }
      if (this.fq1RingProgress < 100) {
        this.fq1RingVariant = "expired";
      }

      if (this.fq3RingProgress < 100) {
        this.fq3RingVariant = "active-step";
      }

      if (
        this.daysToQuarterEnd < this.fqEndDaysThreshold &&
        this.fq3RingProgress < this.fqEndProgressThreshold
      ) {
        this.fq3RingVariant = "warning";
      }
    } else if (this.fiscalQuarterValue == 4) {
      if (this.fq3RingProgress < 100) {
        this.fq3RingVariant = "expired";
      }
      if (this.fq2RingProgress < 100) {
        this.fq2RingVariant = "expired";
      }
      if (this.fq1RingProgress < 100) {
        this.fq1RingVariant = "expired";
      }

      if (this.fq4RingProgress < 100) {
        this.fq4RingVariant = "active-step";
      }

      if (
        this.daysToQuarterEnd < this.fqEndDaysThreshold &&
        this.fq4RingProgress < this.fqEndProgressThreshold
      ) {
        this.fq4RingVariant = "warning";
      }
    }

    if (
      this.fiscalQuarterValue == 4 &&
      this.daysToQuarterEnd < this.fqEndDaysThreshold &&
      this.fyRingProgress < this.fqEndProgressThreshold
    ) {
      this.fyRingVariant = "warning";
    }
  }

  updateAccountFiscalPeriods() {
    this.showSpinner = true;

    setAccountFiscalPeriods({
      accountId: this.recordId,
      m1: this.m1,
      m2: this.m2,
      m3: this.m3,
      m4: this.m4,
      m5: this.m5,
      m6: this.m6,
      m7: this.m7,
      m8: this.m8,
      m9: this.m9,
      m10: this.m10,
      m11: this.m11,
      m12: this.m12
    })
      .then((result) => {
        if (result == true) {
          refreshApex(this.accountResult);

          updateRecord({ fields: { Id: this.recordId } });
          this.showSpinner = false;
        }
      })
      .catch((error) => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      });
  }

  toggleGoalForm() {
    this.showGoalForm = !this.showGoalForm;
    this.clearError();
  }

  handleGoalChange(event) {
    this.requestedSalesGoal = event.target.value;
  }

  approveGoal() {
    this.showSpinner = true;
    this.clearError();

    approveSalesGoalRequest({ accountId: this.recordId })
      .then((result) => {
        if (result == true) {
          refreshApex(this.accountResult);

          const event = new ShowToastEvent({
            title: "Sales Goal Request successfully approved!"
          });
          this.dispatchEvent(event);

          updateRecord({ fields: { Id: this.recordId } });
          eval("$A.get('e.force:refreshView').fire();");

          this.showSpinner = false;
        }
      })
      .catch((error) => {
        this.showSpinner = false;
        this.errorMessage = error.body.message;
      });
  }

  setSalesGoal() {
    this.showSpinner = true;
    this.clearError();
    let isAdmin = false;

    if (this.adminUserIds.includes(this.userId)) {
      isAdmin = true;
    }

    if (this.requestedSalesGoal < this.fy && !isAdmin) {
      this.errorMessage = "Goal cannot be less than current fiscal revenue!";
      this.showSpinner = false;
    } else {
      setSalesGoalRequest({
        accountId: this.recordId,
        goal: this.requestedSalesGoal
      })
        .then((result) => {
          if (result == true) {
            refreshApex(this.accountResult);

            const event = new ShowToastEvent({
              title: "Sales Goal Request successfully submitted!"
            });
            this.dispatchEvent(event);

            updateRecord({ fields: { Id: this.recordId } });
            eval("$A.get('e.force:refreshView').fire();");

            this.showGoalForm = !this.showGoalForm;
            this.pendingRequestedSalesGoal = this.requestedSalesGoal;
            this.hasPendingGoal = true;

            this.showSpinner = false;
          }
        })
        .catch((error) => {
          this.showSpinner = false;
          this.errorMessage = error.body.message;
        });
    }
  }

  handleToggleChange(event) {
    this.displayCurrentFQ = !this.displayCurrentFQ;
  }

  clearError() {
    this.errorMessage = "";
  }

  get getCardLabel() {
    // <div style="margin-left: 25px;line-height: 19px;margin-top: -2px;">Quarter: {daysToQuarterEnd} days left<br>Year: {daysToYearEnd} days left</div>

    if (this.fiscalQuarterLabel) {
      return (
        "Sales Goal Tracker - " +
        this.fiscalQuarter.FiscalYearSettings.Name +
        " (Q" +
        this.fiscalQuarter.Number +
        ": " +
        this.daysToQuarterEnd +
        "d left)" +
        " Year: " +
        this.daysToYearEnd +
        "d left"
      );
    } else {
      return "Sales Goal Tracker";
    }
  }

  get getYearName() {
    if (this.fiscalQuarter && this.fiscalQuarter.FiscalYearSettings) {
      return this.fiscalQuarter.FiscalYearSettings.Name;
    } else {
      return "";
    }
  }

  connectedCallback() {
    console.log("v1.0.1");
    //check if admin tools should be rendered
    if (this.adminUserIds.includes(this.userId)) {
      this.showAdminApproval = true;
    }

    getCurrentFiscalQuarter()
      .then((result) => {
        this.fiscalQuarter = result;
        this.fiscalQuarterLabel =
          this.fiscalQuarter.FiscalYearSettings.Name +
          " (Q" +
          this.fiscalQuarter.Number +
          ")";
        this.fiscalQuarterValue = this.fiscalQuarter.Number;

        //get days to quarter end
        let today = new Date();
        let quarterEnd = new Date(this.fiscalQuarter.EndDate + "T19:00:00Z");

        let difference_In_Time = quarterEnd.getTime() - today.getTime();
        this.daysToQuarterEnd = Math.round(
          difference_In_Time / (1000 * 3600 * 24)
        );

        getCurrentFiscalYear()
          .then((result) => {
            this.fiscalYear = result;
            let yearStart = new Date(this.fiscalYear.StartDate + "T19:00:00Z");
            this.fiscalYearValue = this.fiscalYear.FiscalYearSettings.Name;

            difference_In_Time = today.getTime() - yearStart.getTime();
            this.fyDaysCompleted = Math.round(
              difference_In_Time / (1000 * 3600 * 24)
            );
            this.daysToYearEnd = 365 - this.fyDaysCompleted;
            this.fyTimeProgress = Math.round(
              (this.fyDaysCompleted / 365) * 100
            );
          })
          .catch((error) => {
            this.errorMessage = error.body.message;
          });
      })
      .catch((error) => {
        this.errorMessage = error.body.message;
      });
  }
}
