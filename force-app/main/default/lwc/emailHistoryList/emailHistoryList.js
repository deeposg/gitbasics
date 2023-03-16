import { LightningElement, api } from 'lwc';
import generateData from './generateData';

export default class EmailHistoryList extends LightningElement {
    @api recordId;
    @api objectApiName;
    // @api flexipageRegionWidth;

    selectedState = 'strict';
    sortedBy = 'send_date';
    sortedDirection = 'desc';

    busy = true;

    email = 'Loading...';

    searchTerm = '';

    searchInputClass = 'slds-form-element slds-m-right_small';

    data = [];
    columns = [
        { label: 'Sender', fieldName: 'from',  sortable:true, fixedWidth:150, hideDefaultActions:true,wrapText:true  },
        { label: 'Recipient', fieldName: 'recipient', sortable:true, fixedWidth:200, hideDefaultActions:true,wrapText:true },
        { label: 'Subject', fieldName: 'subject' , sortable:true, hideDefaultActions:true,wrapText:false ,
            cellAttributes: {
                iconName: {fieldName:'attachment_icon'},
            },
        },
        { label: 'Status', fieldName: 'delivery_result', sortable:true,  type:'text', fixedWidth:90, hideDefaultActions:true,wrapText:false,
            cellAttributes: {
                class: {fieldName:'status_class'},
            }
        },
        { label: 'Date', fieldName: 'send_date', sortable:true,  type: 'text' , fixedWidth:100, hideDefaultActions:true,wrapText:false },
        
        {
            type:'button-icon',
            fixedWidth:45,
            typeAttributes: { iconName:'utility:email', title:"Preview" }
        }
    ];

    loadData() {
        if (this.busy) {
            return;
        }
        
        this.busy = true;
        fetch('https://mail.osg.ca/api/get_results.php', {
            method: 'POST',
            body: JSON.stringify({
                recordId:this.recordId,
                objectApiName:this.objectApiName,
                selectedState:this.selectedState,
                sortedBy:this.sortedBy,
                sortedDirection:this.sortedDirection,
                searchTerm:this.searchTerm
            })
          })
            .then(response => response.json())
            .then(payload => {
                console.log(payload)
                this.data = payload.data;

                const meta = payload.meta;
                this.email = meta.email;

                this.busy = false;
            });
    }

    connectedCallback() {
        // const data = generateData({ amountOfRecords: 50 });
        // this.data = data;
        
        this.loadData();
    }

    updateSearchTerm(term) {
        if (term != this.searchTerm) {
            this.searchTerm = term;
            this.loadData();
        }
    }

    handleInputFocus(event) {
        this.searchInputClass = 'slds-form-element slds-m-right_small focused';
    }

    handleInputBlur(event) {
        this.searchInputClass = 'slds-form-element slds-m-right_small';

        this.updateSearchTerm(event.target.value);
    }

    handleInputChange(event) {
        // console.log('handleInputChange', event.target.value);
    }

    handleKeyUp(event) {
        // console.log('keyup', event.keyCode, event.target.value);
        const isEnterKey = event.keyCode === 13;
        const isEscapeKey = event.keyCode === 27;

        if (isEscapeKey) {
            event.target.blur();
        } else if (isEnterKey) {
            event.target.blur();
        }
        // if (isEnterKey) {
        //     this.queryTerm = event.target.value;
        // }
    }

    get strictState() {
        return this.selectedState === 'strict';
    }

    get fuzzyState() {
        return this.selectedState === 'fuzzy';
    }

    get domainState() {
        return this.selectedState === 'domain';
    }

    get allState() {
        return this.selectedState === 'all';
    }

    setSelectedState(newState) {
        if (this.selectedState != newState) {
            this.selectedState = newState;
            this.loadData();
        }
    }

    handleStrictButtonClick() {
        this.setSelectedState('strict');
    }

    handleFuzzyButtonClick() {
        this.setSelectedState('fuzzy');
    }

    handleDomainButtonClick() {
        this.setSelectedState('domain');
    }

    handleAllButtonClick() {
        this.setSelectedState('all');
    }

    handleRowAction(event) {
        console.log('handleRowAction', event.detail.row.id);
    }

    updateColumnSorting(event) {
        console.log('sort', JSON.stringify(event.detail));
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;

        // // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        // this.data = this.sortData(fieldName, sortDirection);

        this.loadData();
   }
}