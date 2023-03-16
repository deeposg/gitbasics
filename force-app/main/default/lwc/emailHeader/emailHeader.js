import { LightningElement, api } from 'lwc';

export default class EmailHeader extends LightningElement {
  @api variation;

  attachmentPoint;
  htmlValue = "<b>Header HTML</b>";

  get jsonData() {
    const payload = JSON.stringify({
      cmp:"EmailHeader", 
      cmpVer:1.0, 
      //
      data:{
        variation:this.variation
      }
    });

    return payload;
  }

  // renderedCallback() {
  //     this.attachmentPoint = this.template.querySelector('div[ishtmlcontainer=true]');
  //     this.attachmentPoint.innerHTML = this.htmlValue;
  // }
}