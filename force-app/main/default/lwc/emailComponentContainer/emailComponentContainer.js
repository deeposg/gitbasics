import { LightningElement, api, wire } from "lwc";
import { registerListener, settings } from 'c/emailDataSource';

export default class EmailComponentContainer extends LightningElement {
    @api params;
    
    iframeRef;

    get previewURL() {
        return "https://mail.osg.ca/api/render_component.php";
    }

    connectedCallback() {
        registerListener('update',()=> {
        console.log('EmailComponentContainer::Handle Update');
        //   this.source = settings.data.source;
        }, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    renderedCallback() {
        if (!this.iframeRef) {
            this.iframeRef = this.template.querySelector('iframe');
            console.log('this.iframeRef', this.iframeRef);

            if (this.iframeRef) {
                setTimeout(() => {
                    console.log('this.iframeRef.style', this.iframeRef.style);
                    
                    console.log('this.iframeRef.contentWindow', this.iframeRef.contentWindow);
                    console.log('this.iframeRef.contentWindow.document', this.iframeRef.contentWindow.document);
                    console.log('this.iframeRef.contentWindow.document.body', this.iframeRef.contentWindow.document.body);

                    this.iframeRef.style.height  = this.iframeRef.contentWindow.document.body.scrollHeight+'px';
                    
                    // console.log('this.iframeRef.style.height', this.iframeRef.style.height);
                }, 1000);

                
            }
        }
        //     this.attachmentPoint = this.template.querySelector('div[ishtmlcontainer=true]');
        //     this.attachmentPoint.innerHTML = this.htmlValue;
        // }
    }
}

function getParams(ref) {
    const p = {
        cmp: ref.constructor.name,
    }
      
    for (const property in ref) {
        let val = null;
        
        try {
            val = ref[property];
        } catch (e) {
            console.log('error', e);
            continue;
        }
        

        if (typeof val === 'function') {
            continue;
        } else if (typeof val === 'object') {
            continue;
        } else if (typeof val === 'array') {
            continue;
        } else if (property === 'isConnected') {
            continue;
        } else if (property === 'accessKey') {
            continue;
        } else if (property === 'dir') {
            continue;
        } else if (property === 'draggable') {
            continue;
        } else if (property === 'hidden') {
            continue;
        } else if (property === 'id') {
            continue;
        } else if (property === 'lang') {
            continue;
        } else if (property === 'spellcheck') {
            continue;
        } else if (property === 'tabIndex') {
            continue;
        } else if (property === 'title') {
            continue;
        }


        p[property] = val;
    }
    
    
    return JSON.stringify(p);
}

export {getParams}