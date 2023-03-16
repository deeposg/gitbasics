import { api, LightningElement, wire } from "lwc";
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import getOSGCustomSetting from '@salesforce/apex/OSGUtil.getOSGCustomSetting';
import Location_OBJECT from '@salesforce/schema/Location_Address__c';
import Account_Address_Object from '@salesforce/schema/Account_Address__c';
import Address1_FIELD from '@salesforce/schema/Location_Address__c.Address_1__c';
import Address2_FIELD from '@salesforce/schema/Location_Address__c.Address_2__c';
import LocationName_FIELD from '@salesforce/schema/Location_Address__c.Name';
import LocationCity_FIELD from '@salesforce/schema/Location_Address__c.City__c';
import LocationType_FIELD from '@salesforce/schema/Location_Address__c.Location_Type__c';
import LocationPostalcode_FIELD from '@salesforce/schema/Location_Address__c.Postal_Code__c';
import Province_FIELD from '@salesforce/schema/Location_Address__c.Province__c';
import Country_FIELD from '@salesforce/schema/Location_Address__c.Country__c';
import Name_FIELD from '@salesforce/schema/Account_Address__c.Name';
import Account_FIELD from '@salesforce/schema/Account_Address__c.Account__c';
import Location_Address_FIELD from '@salesforce/schema/Account_Address__c.Location_Address__c';
import Type_FIELD from '@salesforce/schema/Account_Address__c.Type__c';
import Primary_FIELD from '@salesforce/schema/Account_Address__c.Primary__c';
import unsetPrimaryAddresses from '@salesforce/apex/AccountTriggerHandler.unsetPrimaryAddresses';

const LOCATION_TYPE = 'Client Address';
const ADDRESS_TYPE_SHIPPING = 'Shipping Address';
const ADDRESS_TYPE_BILLING = 'Billing Address';
const UNITED_STATES = 'United States';
const BASE_URL = "https://ws1.postescanada-canadapost.ca";
const OTHER_PARAMS = "&LastId&SearchFor&Country&LanguagePreference&MaxSuggestions&MaxResults=10&Origin&Bias&Filters&GeoFence";
const RETRIEVE_ADDRESS = "/AddressComplete/Interactive/Retrieve/v2.10/json3.ws";
const ADDRESS_COMPLETE = "/AddressComplete/Interactive/Find/v2.10/json3.ws";

export default class CreateAddressTool extends LightningElement {
	addressType = 'Billing Address';
	usaSelected = false;
	isPrimary = false;
	showSpinner = false;
	options = [];
	stateList = [];
	value = '';
	LocationName = '';
	LocationType = '';
	AddressLine1 = '';
	AddressLine2 = '';
	City = '';
	Province = '';
	Country = '';
	PostalCode = '';
	locationAddressId = '';
	CanadaPostAPIKey = '';
	errorMessage;
	locationAddressRecordTypeId;
	@api recordId;

	connectedCallback() {
		console.log('v2');
	}

	@wire(getOSGCustomSetting) customSetting(result) {
		if (result.data) {
			this.CanadaPostAPIKey = result.data.CanadaPost_Api_Key__c;
		}
	};

	@wire(getObjectInfo, { objectApiName: Location_OBJECT }) objectInfo;

	@wire(getPicklistValues, { recordTypeId: "$objectInfo.data.defaultRecordTypeId", fieldApiName: Province_FIELD })
	wiredStates({ data, error }) {


		if (data) {
			var unitedStatesVal = data.controllerValues['United States'];

			var picklistValues = data.values;
			picklistValues.forEach(picklistEntry => {
				if (picklistEntry.validFor[0] == unitedStatesVal) {
					this.stateList.push(
						{
							value: picklistEntry.label,
							label: picklistEntry.value
						}
					);
				}
			})
			//1. Get the controllerValues array from the response
			//this has the country name and the value/index

			//2. Then get the values array from the response
			//loop through each record, check the validFor field and match it to the country index, 
			//If it's the same index as United States, save it to the stateList
		}

	}

	async getMatchingAddress(searchTerm) {
		const findAddressUingParams = BASE_URL + ADDRESS_COMPLETE + "?Key=" + this.CanadaPostAPIKey + "&SearchTerm=" + searchTerm + OTHER_PARAMS;
		const res = await fetch(findAddressUingParams, {
			Method: "GET",
			Headers: {
				"Content-Type": "application/x-www-form-urlencoded"
			}
		});
		const data = await res.json();
		return data;
	}

	addressLookup(value) {
		this.showSpinner = true;
		const searchTerm = value;
		this.getMatchingAddress(searchTerm).then((data) => {
			if (data) {
				this.showSpinner = false;
				this.options = data.Items.map(objPL => {
					return {
						value: `${objPL.Id}`,
						label: `${objPL.Text} ${objPL.Description}`
					};
				});
			}
		});
	}

	handleChange(event) {
		window.clearTimeout(this.delayTimeout);
		const searchKey = event.target.value;

		this.delayTimeout = setTimeout(() => {
			if (searchKey) {
				this.addressLookup(searchKey);
			}
			else {
				this.options = [];
			}

		}, 250);
	}

	handleEvent(event) {
		this.getExactAddress(event.currentTarget.value);
	}

	async getExactAddress(id) {
		const addressWithParams =
			BASE_URL + RETRIEVE_ADDRESS + "?Key=" + this.CanadaPostAPIKey + "&Id=" + id;
		const res = await fetch(addressWithParams, {
			Method: "GET",
			Headers: {
				"Content-Type": "application/x-www-form-urlencoded"
			}
		});
		const data = await res.json();
		const locationAddress = data.Items[0];
		const address = {
			'Line1': locationAddress.Line1,
			'Line2': locationAddress.Line2,
			'BuildingNumber': locationAddress.BuildingNumber,
			'City': locationAddress.City,
			'CountryName': locationAddress.CountryName,
			'Label': locationAddress.Label,
			'PostalCode': locationAddress.PostalCode,
			'Province': locationAddress.Province,
			'ProvinceName': locationAddress.ProvinceName,
			'Street': locationAddress.Street,
			'SubBuilding': locationAddress.SubBuilding
		}

		if (address.Line1 !== undefined) {
			this.LocationName = this.addressType + ' - ' + address.Line1;
			this.LocationType = LOCATION_TYPE;
			this.AddressLine1 = address.Line1;
			this.AddressLine2 = address.Line2;
			this.City = address.City;
			this.Province = address.ProvinceName;
			this.Country = address.CountryName;
			this.PostalCode = address.PostalCode;
			// this.searchValue = address.Label;
		}
		return address;
	}

	validateData() {
		this.clearErrors();
		this.AddressLine1 = this.template.querySelector('[data-id="AddressLine1"]').value.toString();
		this.AddressLine2 = this.template.querySelector('[data-id="AddressLine2"]').value.toString();
		this.City = this.template.querySelector('[data-id="City"]').value.toString();
		this.PostalCode = this.template.querySelector('[data-id="PostalCode"]').value.toString();
		if (this.AddressLine1 === '' || this.City === '' || this.Province === '' || this.Country === '' || this.PostalCode === '') {
			return false;
		}
		return true;
	}

	createAddress(event) {
		this.showSpinner = true;
		var validData = this.validateData();
		if (validData) {
			if (this.isPrimary) {
				unsetPrimaryAddresses({ accountId: this.recordId, type: this.addressType })
					.then(result => {
					})
					.catch(error => {
						this.showSpinner = false;
						this.errorMessage = error.body.message;
					});
			}

			this.createLocationAddress();
		}
		else {
			this.errorMessage = "Missing required fields in form!";
		}
	}

	createLocationAddress() {
		this.showSpinner = true;
		const fields = {};
		fields[Address1_FIELD.fieldApiName] = this.AddressLine1;
		fields[Address2_FIELD.fieldApiName] = this.AddressLine2;
		fields[LocationName_FIELD.fieldApiName] = this.addressType + ' - ' + this.AddressLine1;
		fields[LocationCity_FIELD.fieldApiName] = this.City;
		fields[LocationType_FIELD.fieldApiName] = LOCATION_TYPE;
		fields[LocationPostalcode_FIELD.fieldApiName] = this.PostalCode;
		fields[Province_FIELD.fieldApiName] = this.Province;
		fields[Country_FIELD.fieldApiName] = this.Country;
		console.log(fields);
		const recordInput = { apiName: Location_OBJECT.objectApiName, fields };
		createRecord(recordInput)
			.then(createdRecord => {
				this.locationAddressId = createdRecord.id;
				this.createAccountAddress();
				/*
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Location Account created',
						variant: 'success',
					}),
				);
				*/
			})
			.catch(error => {
				console.log(error);
				this.showSpinner = false;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error creating record',
						message: error.body.message,
						variant: 'error',
					}),
				);
			});
	}

	createAccountAddress() {
		const fields = {};
		fields[Name_FIELD.fieldApiName] = this.AddressLine1;
		fields[Account_FIELD.fieldApiName] = this.recordId;
		fields[Location_Address_FIELD.fieldApiName] = this.locationAddressId;
		fields[Type_FIELD.fieldApiName] = this.addressType;
		fields[Primary_FIELD.fieldApiName] = this.isPrimary;
		this.showSpinner = true;
		const recordInput = { apiName: Account_Address_Object.objectApiName, fields };
		createRecord(recordInput)
			.then(createdAccountAddress => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Account Address created',
						variant: 'success',
					}),
				);
				this.closeQuickAction();
			})
			.catch(error => {
				this.showSpinner = false;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error creating record',
						message: error.body.output.errors[0].message,
						variant: 'error',
					}),
				);
			});
	}

	disableAddressFields(event) {
		let AddressLine1 = this.template.querySelector('[data-id="AddressLine1"]');
		let AddressLine2 = this.template.querySelector('[data-id="AddressLine2"]');
		let City = this.template.querySelector('[data-id="City"]');
		let Country = this.template.querySelector('[data-id="Country"]');
		let PostalCode = this.template.querySelector('[data-id="PostalCode"]');
		if (event.target.checked === true) {
			this.usaSelected = true;
			AddressLine1.disabled = false;
			AddressLine2.disabled = false;
			City.disabled = false;
			this.Country = UNITED_STATES;
			PostalCode.disabled = false;
		} else {
			this.usaSelected = false;
			AddressLine1.disabled = true;
			AddressLine2.disabled = true;
			City.disabled = true;
			this.Country = '';
			Country.disabled = true;
			PostalCode.disabled = true;
		}

	}

	usStateLists(event) {
		this.Province = event.detail.value.toString();
	}

	setPrimary(event) {
		this.isPrimary = event.target.checked;
	}

	setAddressType(event) {
		if (event.target.checked === true) {
			this.addressType = ADDRESS_TYPE_SHIPPING;
		} else {
			this.addressType = ADDRESS_TYPE_BILLING;
		}
	}

	clearErrors() {
		this.errorMessage = '';
	}

	closeQuickAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}