import { LightningElement, api } from 'lwc';
import {getParams} from "c/emailComponentContainer";

export default class EmailFooter extends LightningElement {
  @api variation;

  get params() {
    return getParams(this);
  }
}