/**
 * @description Controller for ContentDocumentExtension LWC component
 */
public with sharing class EVAL_ContentDocumentExtensionController {
    
    /**
     * @description Retrieves ContentDocumentExtension data for a given ContentDocument ID
     * @param contentDocumentId The ID of the ContentDocument
     * @return DOC_ContentDocumentExtension__c The ContentDocumentExtension record or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static DOC_ContentDocumentExtension__c getContentDocumentExtension(Id contentDocumentId) {
        if (contentDocumentId == null) {
            return null;
        }
        
        try {
            return DOM_ContentDocumentService.getContentDocumentExtension(contentDocumentId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving ContentDocumentExtension: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Updates the evaluation fields for a ContentDocumentExtension
     * @param recordId The ID of the ContentDocumentExtension record
     * @param evaluationStatus The status of the evaluation
     * @param feedback The feedback for incorrect categorization
     * @return String Success or error message
     */
    @AuraEnabled
    public static String updateEvaluation(Id recordId, String evaluationStatus, String feedback) {
        try {
            DOC_ContentDocumentExtension__c record = new DOC_ContentDocumentExtension__c();
            record.Id = recordId;
            record.EVAL_status__c = evaluationStatus;
            record.EVAL_CategorizationKOFeedback__c = feedback;
            
            update record;
            return 'success';
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating evaluation: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
}
