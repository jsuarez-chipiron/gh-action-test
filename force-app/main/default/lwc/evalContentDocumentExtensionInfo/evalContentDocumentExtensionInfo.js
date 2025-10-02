import { LightningElement, api, wire, track } from 'lwc';
import getContentDocumentExtension from '@salesforce/apex/EVAL_ContentDocumentExtensionController.getContentDocumentExtension';
import updateEvaluation from '@salesforce/apex/EVAL_ContentDocumentExtensionController.updateEvaluation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class EvalContentDocumentExtensionInfo extends LightningElement {
    @api recordId;
    @track isEditing = false;
    @track docSectionExpanded = true;
    @track entSectionExpanded = false;
    @track evaluationData = {
        status: 'Pendiente de evaluación',
        feedback: ''
    };
    
    wiredContentDocumentExtension;
    
    @wire(getContentDocumentExtension, { contentDocumentId: '$recordId' })
    contentDocumentExtension(result) {
        this.wiredContentDocumentExtension = result;
    }
    
    get hasExtension() {
        return this.wiredContentDocumentExtension && this.wiredContentDocumentExtension.data !== null && this.wiredContentDocumentExtension.data !== undefined;
    }
    
    get extensionData() {
        return this.wiredContentDocumentExtension ? this.wiredContentDocumentExtension.data : null;
    }
    
    get isLoading() {
        return this.wiredContentDocumentExtension ? this.wiredContentDocumentExtension.loading : false;
    }
    
    get hasError() {
        return this.wiredContentDocumentExtension ? this.wiredContentDocumentExtension.error : null;
    }
    
    get formattedAccuracy() {
        if (this.extensionData && this.extensionData.DOC_accuracy__c !== null) {
            return `${this.extensionData.DOC_accuracy__c}%`;
        }
        return 'N/A';
    }
    
    get formattedDate() {
        if (this.extensionData && this.extensionData.CreatedDate) {
            return new Date(this.extensionData.CreatedDate).toLocaleDateString();
        }
        return 'N/A';
    }
    
    get evaluationStatus() {
        if (this.extensionData && this.extensionData.EVAL_status__c) {
            return this.extensionData.EVAL_status__c;
        }
        return 'Pendiente de evaluación';
    }
    
    get evaluationOptions() {
        return [
            { label: 'Pendiente de evaluación', value: 'Pendiente de evaluación' },
            { label: 'Evaluación correcta', value: 'Evaluación correcta' },
            { label: 'Evaluación incorrecta', value: 'Evaluación incorrecta' }
        ];
    }

    get hasEntityData() {
        if (!this.extensionData) return false;
        return this.extensionData.ENT_claimant1__c || 
               this.extensionData.ENT_claimant2__c || 
               this.extensionData.ENT_representative__c || 
               this.extensionData.ENT_firm__c || 
               this.extensionData.ENT_others__c;
    }

    get docSectionClass() {
        return this.docSectionExpanded ? 'slds-is-open' : '';
    }

    get entSectionClass() {
        return this.entSectionExpanded ? 'slds-is-open' : '';
    }
    
    handleEdit() {
        this.isEditing = true;
        this.evaluationData = {
            status: this.extensionData?.EVAL_status__c || 'Pendiente de evaluación',
            feedback: this.extensionData?.EVAL_CategorizationKOFeedback__c || ''
        };
    }
    
    handleCancel() {
        this.isEditing = false;
    }
    
    handleStatusChange(event) {
        this.evaluationData.status = event.target.value;
    }
    
    handleFeedbackChange(event) {
        this.evaluationData.feedback = event.target.value;
    }

    toggleDocSection() {
        this.docSectionExpanded = !this.docSectionExpanded;
    }

    toggleEntSection() {
        this.entSectionExpanded = !this.entSectionExpanded;
    }
    
    async handleSave() {
        try {
            const result = await updateEvaluation({
                recordId: this.extensionData.Id,
                evaluationStatus: this.evaluationData.status,
                feedback: this.evaluationData.feedback
            });
            
            if (result === 'success') {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Evaluación actualizada correctamente',
                    variant: 'success'
                }));
                this.isEditing = false;
                // Refresh the data
                this.refreshData();
            } else {
                throw new Error(result);
            }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.message,
                variant: 'error'
            }));
        }
    }
    
    async refreshData() {
        // Force refresh of wired data using refreshApex
        await refreshApex(this.wiredContentDocumentExtension);
    }
}
