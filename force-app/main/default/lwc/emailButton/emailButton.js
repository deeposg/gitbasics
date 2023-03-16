import { LightningElement, api } from "lwc";

import {getParams} from "c/emailComponentContainer";

export default class EmailButton extends LightningElement {
  @api label;
  @api url;
  @api styleType;
  @api alignment;

  get params() {
    return getParams(this);
  }
}