/**
 * @description Queueable class for asynchronous entity analysis processing.
 * This class handles individual document entity analysis and updates the DOC_ContentDocumentExtension
 * object with entity analysis results, while also updating progress metrics in DOM_CaseExtension.
 */
public class ENT_EntityAnalysisQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id contentDocumentId;
    private Id caseExtensionId;
    
    /**
     * @description Constructor for the queueable job
     * @param contentDocumentId The ID of the ContentDocument to analyze
     * @param caseExtensionId The ID of the DOM_CaseExtension__c record to relate the analysis to
     */
    public ENT_EntityAnalysisQueueable(Id contentDocumentId, Id caseExtensionId) {
        this.contentDocumentId = contentDocumentId;
        this.caseExtensionId = caseExtensionId;
    }
    
    /**
     * @description Main execution method for the queueable job
     * @param context The queueable context
     */
    public void execute(QueueableContext context) {
        try {
            validateRequiredParameters();
            
            persistEntityAnalysisResult();
            updateProgressMetrics(true);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in entity analysis queueable: ' + e.getMessage());
            
            if (caseExtensionId != null) {
                updateProgressMetrics(false);
            }
            
            createErrorRecord(e.getMessage());
        }
    }
    
    /**
     * @description Validates that all required parameters are present
     * @throws IllegalArgumentException When required parameters are missing
     */
    private void validateRequiredParameters() {
        if (contentDocumentId == null) {
            throw new IllegalArgumentException('ContentDocument ID cannot be null');
        }
        if (caseExtensionId == null) {
            throw new IllegalArgumentException('Case Extension ID cannot be null');
        }
    }
    
    /**
     * @description Persists entity analysis results to DOC_ContentDocumentExtension
     */
    private void persistEntityAnalysisResult() {
        ContentDocument document = validateAndRetrieveDocument();
        
        ENT_EntityService.EntityAnalysisResult analysisResult = ENT_EntityService.performEntityAnalysis(document);
        
        DOC_ContentDocumentExtensionService.createEntityExtension(
            document.Id,
            analysisResult.claimant1,
            analysisResult.claimant1Reason,
            analysisResult.claimant2,
            analysisResult.claimant2Reason,
            analysisResult.representative,
            analysisResult.representativeReason,
            analysisResult.firm,
            analysisResult.firmReason,
            analysisResult.others,
            analysisResult.othersReason,
            'Processed',
            caseExtensionId
        );
    }
    
    /**
     * @description Validates and retrieves the ContentDocument for analysis
     * @return ContentDocument The validated document for analysis
     * @throws IllegalArgumentException When the document is not found
     */
    private ContentDocument validateAndRetrieveDocument() {
        ContentDocument document = DOM_ContentDocumentService.getContentDocumentById(contentDocumentId);
        
        if (document == null) {
            throw new IllegalArgumentException('ContentDocument not found: ' + contentDocumentId);
        }
        
        return document;
    }
    
    /**
     * @description Updates progress metrics in DOM_CaseExtension
     * @param isSuccess Whether the analysis was successful
     */
    private void updateProgressMetrics(Boolean isSuccess) {
        DOM_CaseExtensionService.updateDocumentInformationProgress(caseExtensionId, isSuccess);
    }
    
    /**
     * @description Creates an error record for failed analysis
     * @param errorMessage The error message to record
     */
    private void createErrorRecord(String errorMessage) {
        // Use the service method to avoid duplicates
        DOC_ContentDocumentExtensionService.createEntityExtension(
            contentDocumentId,
            '',
            'ERROR: ' + errorMessage,
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            'Error',
            caseExtensionId
        );
    }
    
    /**
     * @description Custom exception class for ENT_EntityAnalysisQueueable
     */
    public class ENT_EntityAnalysisException extends Exception {}
}
