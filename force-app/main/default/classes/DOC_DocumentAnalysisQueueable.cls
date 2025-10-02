/**
 * @description Queueable class for asynchronous document analysis processing.
 * This class handles individual document analysis and updates the DOC_ContentDocumentExtension
 * object with analysis results, while also updating progress metrics in DOM_CaseExtension.
 */
public class DOC_DocumentAnalysisQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id contentDocumentId;
    private Id caseExtensionId;
    
    /**
     * @description Constructor for the queueable job
     * @param contentDocumentId The ID of the ContentDocument to analyze
     * @param caseExtensionId The ID of the DOM_CaseExtension__c record to relate the analysis to
     */
    public DOC_DocumentAnalysisQueueable(Id contentDocumentId, Id caseExtensionId) {
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
            
            persistAnalysisResult();
            updateProgressMetrics(true);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in document analysis queueable: ' + e.getMessage());
            
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
     * @description Persists analysis results to DOC_ContentDocumentExtension
     */
    private void persistAnalysisResult() {
        ContentDocument document = validateAndRetrieveDocument();
        
        DOC_DocumentService.DocumentAnalysisResult analysisResult = DOC_DocumentService.performDocumentAnalysis(document);
        
        DOC_ContentDocumentExtensionService.createDocumentExtension(
            document.Id,
            analysisResult.documentType,
            analysisResult.reason,
            analysisResult.accuracy,
            analysisResult.summary,
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
        DOC_ContentDocumentExtensionService.createDocumentExtension(
            contentDocumentId,
            'Otros',
            'ERROR: ' + errorMessage,
            100.0,
            '',
            'Error',
            caseExtensionId
        );
    }
    

        
    /**
     * @description Custom exception class for DOC_DocumentAnalysisQueueable
     */
    public class DOC_DocumentAnalysisException extends Exception {}
}