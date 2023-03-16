import { LightningElement, api } from 'lwc';
import {
  registerListener,
  unregisterListener,
  unregisterAllListeners,
  fireEvent
} from "./pubSub";

const settings = {
  data:{},
  dataSourceInstanceCount:0
};

export default class EmailDataSource extends LightningElement {
  @api templateId;
  @api source;

  get jsonData() {
    const payload = {
      cmp:"EmailDataSource", 
      cmpVer:1.0, 
      //
      data:{
        templateId:this.templateId,
        source:this.source
      }
    };

    settings.data = payload.data;
    fireEvent('update');
      
    return JSON.stringify(payload);
  }

  connectedCallback() {
    settings.dataSourceInstanceCount++;
    fireEvent('update');

    registerListener('update',()=> {
      console.log('emailDataSource::Handle Update', settings.dataSourceInstanceCount);
    }, this);
  }

  disconnectedCallback() {
    unregisterAllListeners(this);

    settings.dataSourceInstanceCount--;
    fireEvent('update');
  }

  
}

export {
  registerListener,
  unregisterListener,
  unregisterAllListeners,
  fireEvent,
  settings
}