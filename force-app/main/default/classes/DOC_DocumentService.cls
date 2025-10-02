/**
 * @description Service class for document analysis functionality.
 * This service analyzes documents attached to cases and persists the analysis results
 * to the DOC_ContentDocumentExtension object, while tracking progress metrics in DOM_CaseExtension.
 * 
 * IMPORTANT: This service requires documents to be attached to the case for analysis.
 * Cases without attached documents will cause the service to fail with a clear error message.
 */
public with sharing class DOC_DocumentService {
    
    /**
     * @description Analyzes documents for a case and persists the results asynchronously.
     * This method initiates document analysis and updates the case extension with tracking metrics.
     * 
     * @param caseRecord The case record to analyze (must have Id field populated)
     * @return DOM_CaseExtension__c The case extension record with document analysis tracking fields updated
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     *   - No documents are found for the case (case must have attached documents for analysis)
     * 
     * @throws DOC_ServiceException When there's an error during:
     *   - Document retrieval from the case
     *   - Case extension update operations
     *   - Queueable job enqueuing
     *   - Any other unexpected error during the analysis process
     */
    public static DOM_CaseExtension__c analyzeForDocumentsAndPersist(Case caseRecord) {
        try {
            validateCaseFields(caseRecord);
            
            List<ContentDocumentLink> documentLinks = DOM_ContentDocumentService.getContentDocumentLinksForCase(caseRecord.Id);
            
            validateDocumentLinks(caseRecord, documentLinks);
            
            Integer totalDocuments = documentLinks.size();
            
            DOM_CaseExtension__c caseExtension = DOM_CaseService.updateDocumentInformation(
                caseRecord, 
                totalDocuments
            );
            
            enqueueDocumentAnalysisJobs(documentLinks, caseExtension);
            
            return caseExtension;
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing documents for case: ' + e.getMessage());
            throw new DOC_ServiceException('Failed to analyze documents for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Validates that the case record has all required fields for document analysis
     * @param caseRecord The case record to validate
     * @throws IllegalArgumentException When required fields are missing or invalid
     */
    private static void validateCaseFields(Case caseRecord) {
        if (caseRecord == null) {
            throw new IllegalArgumentException('Case record cannot be null');
        }
        if (caseRecord.Id == null) {
            throw new IllegalArgumentException('Case Id field is required for document analysis');
        }
    }
    
    /**
     * @description Validates that the case has attached documents for analysis
     * @param caseRecord The case record to validate
     * @param documentLinks List of document links associated with the case
     * @throws IllegalArgumentException When no documents are found for the case
     */
    private static void validateDocumentLinks(Case caseRecord, List<ContentDocumentLink> documentLinks) {
        if (documentLinks == null || documentLinks.isEmpty()) {
            throw new IllegalArgumentException(
                'Case with Id "' + caseRecord.Id + '" must have attached documents for analysis. ' +
                'No documents were found for this case.'
            );
        }
    }
    
    /**
     * @description Enqueues individual document analysis jobs for each document attached to the case
     * @param documentLinks List of document links to analyze
     * @param caseExtension The case extension record to relate the analysis to
     */
    private static void enqueueDocumentAnalysisJobs(List<ContentDocumentLink> documentLinks, DOM_CaseExtension__c caseExtension) {
        for (ContentDocumentLink documentLink : documentLinks) {
            analyzeForDocumentAndPersist(documentLink.ContentDocumentId, caseExtension.Id);
        }
    }
    
    /**
     * @description Enqueues a single document analysis job for asynchronous processing
     * @param contentDocumentId The ID of the ContentDocument to analyze
     * @param caseExtensionId The ID of the DOM_CaseExtension__c record to relate the analysis to
     */
    private static void analyzeForDocumentAndPersist(Id contentDocumentId, Id caseExtensionId) {
        DOC_DocumentAnalysisQueueable analysisJob = new DOC_DocumentAnalysisQueueable(contentDocumentId, caseExtensionId);
        System.enqueueJob(analysisJob);
    }
    
    /**
     * @description Performs document analysis using Einstein LLM with Prompt Template
     * @param document The ContentDocument to analyze
     * @return DocumentAnalysisResult The analysis results
     * @throws DOC_ServiceException When AI analysis fails
     */
    public static DocumentAnalysisResult performDocumentAnalysis(ContentDocument document) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            
            Map<String, String> fileToAnalyzeMap = new Map<String, String>();
            fileToAnalyzeMap.put('id', document.Id);
            
            ConnectApi.WrappedValue fileToAnalyze = new ConnectApi.WrappedValue();
            fileToAnalyze.value = fileToAnalyzeMap;
            
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:document', fileToAnalyze);
            
            executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            executeTemplateInput.isPreview = false;
            executeTemplateInput.inputParams = inputParams;
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DOC_Analysis', executeTemplateInput);
            System.debug(LoggingLevel.INFO, 'LLM Response: ' + generationsOutput);
            if (generationsOutput.generations != null && generationsOutput.generations.size() > 0) {
                String response = generationsOutput.generations[0].text;
                return parseAIResponse(response, document);
            } else {
                throw new DOC_ServiceException(generationsOutput.generationErrors[0].localizedErrorMessage);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error calling PromptBuilder: ' + e.getMessage());
            throw new DOC_ServiceException('Error calling PromptBuilder: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses the AI response to extract analysis results
     * @param aiResponse The raw AI response text
     * @param document The original document for fallback information
     * @return DocumentAnalysisResult The parsed analysis results
     */
    private static DocumentAnalysisResult parseAIResponse(String aiResponse, ContentDocument document) {
        try {
            System.debug(LoggingLevel.INFO, 'DOC_Analysis response: ' + aiResponse);
            
            // Clean the response and parse JSON
            String cleanedResponse = aiResponse.replaceAll('```', '').replaceAll('json', '').trim();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(cleanedResponse);
            
            // Extract values with proper type casting and validation
            String documentType = (String) responseMap.get('category');
            String reason = (String) responseMap.get('reason');
            Decimal accuracy = (Decimal) responseMap.get('accuracy');
            String summary = (String) responseMap.get('summary');
            
            return new DocumentAnalysisResult(documentType, reason, accuracy, summary);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing PromptBuilder response: ' + e.getMessage());
            throw new DOC_ServiceException('Error parsing PromptBuilder response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Inner class to hold document analysis results
     */
    public class DocumentAnalysisResult {
        @AuraEnabled public String documentType { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public Decimal accuracy { get; set; }
        @AuraEnabled public String summary { get; set; }
        
        public DocumentAnalysisResult() {
            this.documentType = 'Otros';
            this.reason = '';
            this.accuracy = 0.0;
            this.summary = '';
        }
        
        public DocumentAnalysisResult(String documentType, String reason, Decimal accuracy, String summary) {
            this.documentType = documentType;
            this.reason = reason;
            this.accuracy = accuracy;
            this.summary = summary;
        }
    }
    
    /**
     * @description Custom exception class for DOC_DocumentService
     */
    public class DOC_ServiceException extends Exception {}
}
