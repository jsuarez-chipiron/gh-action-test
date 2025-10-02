/**
 * @description Service class for entity analysis functionality.
 * This service analyzes documents attached to cases and extracts entity information
 * to the DOC_ContentDocumentExtension object, while tracking progress metrics in DOM_CaseExtension.
 * 
 * IMPORTANT: This service requires documents to be attached to the case for analysis.
 * Cases without attached documents will cause the service to fail with a clear error message.
 */
public with sharing class ENT_EntityService {
    
    /**
     * @description Analyzes documents for entities in a case and persists the results asynchronously.
     * This method initiates entity analysis and updates the case extension with tracking metrics.
     * 
     * @param caseRecord The case record to analyze (must have Id field populated)
     * @return DOM_CaseExtension__c The case extension record with entity analysis tracking fields updated
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     *   - No documents are found for the case (case must have attached documents for analysis)
     * 
     * @throws ENT_ServiceException When there's an error during:
     *   - Document retrieval from the case
     *   - Case extension update operations
     *   - Queueable job enqueuing
     *   - Any other unexpected error during the analysis process
     */
    public static DOM_CaseExtension__c analyzeForEntitiesAndPersist(Case caseRecord) {
        try {
            validateCaseFields(caseRecord);
            
            List<ContentDocumentLink> documentLinks = DOM_ContentDocumentService.getContentDocumentLinksForCase(caseRecord.Id);
            
            validateDocumentLinks(caseRecord, documentLinks);
            
            Integer totalDocuments = documentLinks.size();
            
            DOM_CaseExtension__c caseExtension = DOM_CaseService.updateDocumentInformation(
                caseRecord, 
                totalDocuments
            );
            
            enqueueEntityAnalysisJobs(documentLinks, caseExtension);
            
            return caseExtension;
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing entities for case: ' + e.getMessage());
            throw new ENT_ServiceException('Failed to analyze entities for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Validates that the case record has all required fields for entity analysis
     * @param caseRecord The case record to validate
     * @throws IllegalArgumentException When required fields are missing or invalid
     */
    private static void validateCaseFields(Case caseRecord) {
        if (caseRecord == null) {
            throw new IllegalArgumentException('Case record cannot be null');
        }
        if (caseRecord.Id == null) {
            throw new IllegalArgumentException('Case Id field is required for entity analysis');
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
                'Case with Id "' + caseRecord.Id + '" must have attached documents for entity analysis. ' +
                'No documents were found for this case.'
            );
        }
    }
    
    /**
     * @description Enqueues individual entity analysis jobs for each document attached to the case
     * @param documentLinks List of document links to analyze
     * @param caseExtension The case extension record to relate the analysis to
     */
    private static void enqueueEntityAnalysisJobs(List<ContentDocumentLink> documentLinks, DOM_CaseExtension__c caseExtension) {
        for (ContentDocumentLink documentLink : documentLinks) {
            analyzeForEntitiesAndPersist(documentLink.ContentDocumentId, caseExtension.Id);
        }
    }
    
    /**
     * @description Enqueues a single entity analysis job for asynchronous processing
     * @param contentDocumentId The ID of the ContentDocument to analyze
     * @param caseExtensionId The ID of the DOM_CaseExtension__c record to relate the analysis to
     */
    private static void analyzeForEntitiesAndPersist(Id contentDocumentId, Id caseExtensionId) {
        ENT_EntityAnalysisQueueable analysisJob = new ENT_EntityAnalysisQueueable(contentDocumentId, caseExtensionId);
        System.enqueueJob(analysisJob);
    }
    
    /**
     * @description Performs entity analysis using Einstein LLM with Prompt Template
     * @param document The ContentDocument to analyze
     * @return EntityAnalysisResult The analysis results
     * @throws ENT_ServiceException When AI analysis fails
     */
    public static EntityAnalysisResult performEntityAnalysis(ContentDocument document) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            
            Map<String, String> fileToAnalyzeMap = new Map<String, String>();
            fileToAnalyzeMap.put('id', document.Id);
            
            ConnectApi.WrappedValue fileToAnalyze = new ConnectApi.WrappedValue();
            fileToAnalyze.value = fileToAnalyzeMap;
            
            // Configurar idioma en español
            Map<String, String> languageMap = new Map<String, String>();
            languageMap.put('language', 'es');
            ConnectApi.WrappedValue languageValue = new ConnectApi.WrappedValue();
            languageValue.value = languageMap;
            
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:document', fileToAnalyze);
            inputParams.put('Input:language', languageValue);
            
            executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            executeTemplateInput.isPreview = false;
            executeTemplateInput.inputParams = inputParams;
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('ENT_EntityAnalysis', executeTemplateInput);
            System.debug(LoggingLevel.INFO, 'LLM Response: ' + generationsOutput);
            if (generationsOutput.generations != null && generationsOutput.generations.size() > 0) {
                String response = generationsOutput.generations[0].text;
                return parseAIResponse(response, document);
            } else {
                throw new ENT_ServiceException(generationsOutput.generationErrors[0].localizedErrorMessage);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error calling PromptBuilder: ' + e.getMessage());
            throw new ENT_ServiceException('Error calling PromptBuilder: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses the AI response to extract entity analysis results
     * @param aiResponse The raw AI response text
     * @param document The original document for fallback information
     * @return EntityAnalysisResult The parsed analysis results
     */
    private static EntityAnalysisResult parseAIResponse(String aiResponse, ContentDocument document) {
        try {
            System.debug(LoggingLevel.INFO, 'ENT_EntityAnalysis response: ' + aiResponse);
            
            // Clean the response and parse JSON
            String cleanedResponse = aiResponse.replaceAll('```', '').replaceAll('json', '').trim();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(cleanedResponse);
            
            // Extract values with proper type casting and validation
            String claimant1 = (String) responseMap.get('claimant1');
            String claimant1Reason = (String) responseMap.get('claimant1Reason');
            String claimant2 = (String) responseMap.get('claimant2');
            String claimant2Reason = (String) responseMap.get('claimant2Reason');
            String representative = (String) responseMap.get('representative');
            String representativeReason = (String) responseMap.get('representativeReason');
            String firm = (String) responseMap.get('firm');
            String firmReason = (String) responseMap.get('firmReason');
            String others = (String) responseMap.get('others');
            String othersReason = (String) responseMap.get('othersReason');
            
            return new EntityAnalysisResult(
                claimant1, claimant1Reason,
                claimant2, claimant2Reason,
                representative, representativeReason,
                firm, firmReason,
                others, othersReason
            );
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing PromptBuilder response: ' + e.getMessage());
            throw new ENT_ServiceException('Error parsing PromptBuilder response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Inner class to hold entity analysis results
     */
    public class EntityAnalysisResult {
        @AuraEnabled public String claimant1 { get; set; }
        @AuraEnabled public String claimant1Reason { get; set; }
        @AuraEnabled public String claimant2 { get; set; }
        @AuraEnabled public String claimant2Reason { get; set; }
        @AuraEnabled public String representative { get; set; }
        @AuraEnabled public String representativeReason { get; set; }
        @AuraEnabled public String firm { get; set; }
        @AuraEnabled public String firmReason { get; set; }
        @AuraEnabled public String others { get; set; }
        @AuraEnabled public String othersReason { get; set; }
        
        public EntityAnalysisResult() {
            this.claimant1 = '';
            this.claimant1Reason = '';
            this.claimant2 = '';
            this.claimant2Reason = '';
            this.representative = '';
            this.representativeReason = '';
            this.firm = '';
            this.firmReason = '';
            this.others = '';
            this.othersReason = '';
        }
        
        public EntityAnalysisResult(
            String claimant1, String claimant1Reason,
            String claimant2, String claimant2Reason,
            String representative, String representativeReason,
            String firm, String firmReason,
            String others, String othersReason
        ) {
            this.claimant1 = claimant1;
            this.claimant1Reason = claimant1Reason;
            this.claimant2 = claimant2;
            this.claimant2Reason = claimant2Reason;
            this.representative = representative;
            this.representativeReason = representativeReason;
            this.firm = firm;
            this.firmReason = firmReason;
            this.others = others;
            this.othersReason = othersReason;
        }
    }
    
    /**
     * @description Analyzes aggregated entities for a case using AI.
     * This method uses a prompt template that internally retrieves and analyzes
     * all document extensions and other related data for the case.
     * 
     * @param caseRecord The case record to analyze
     * @return DOM_CaseExtension__c The updated case extension record with synthesized entity data
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     * 
     * @throws ENT_ServiceException When there's an error during:
     *   - AI analysis via prompt template
     *   - Case extension record update
     */
    public static DOM_CaseExtension__c analyzeAggregatedEntities(Case caseRecord) {
        try {
            validateCaseFields(caseRecord);
            
            AggregatedEntityAnalysisResult analysisResult = performAggregatedEntityAnalysis(caseRecord);
            DOM_CaseExtension__c updatedCaseExtension = DOM_CaseService.updateAggregatedEntityInformation(
                caseRecord,
                analysisResult.claimant1,
                analysisResult.claimant1Reason,
                analysisResult.claimant2,
                analysisResult.claimant2Reason,
                analysisResult.representative,
                analysisResult.representativeReason,
                analysisResult.firm,
                analysisResult.firmReason,
                analysisResult.others,
                analysisResult.othersReason
            );
            
            return updatedCaseExtension;
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing aggregated entities: ' + e.getMessage());
            throw new ENT_ServiceException('Failed to analyze aggregated entities: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Performs aggregated entity analysis using Einstein LLM with Prompt Template
     * @param caseRecord The case record to analyze
     * @return AggregatedEntityAnalysisResult The analysis results
     * @throws ENT_ServiceException When AI analysis fails
     */
    private static AggregatedEntityAnalysisResult performAggregatedEntityAnalysis(Case caseRecord) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            
            Map<String, String> caseToAnalyzeMap = new Map<String, String>();
            caseToAnalyzeMap.put('id', caseRecord.Id);
            
            ConnectApi.WrappedValue caseToAnalyze = new ConnectApi.WrappedValue();
            caseToAnalyze.value = caseToAnalyzeMap;
            
            Map<String, String> languageMap = new Map<String, String>();
            languageMap.put('language', 'es');
            ConnectApi.WrappedValue languageValue = new ConnectApi.WrappedValue();
            languageValue.value = languageMap;
            
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:case', caseToAnalyze);
            inputParams.put('Input:language', languageValue);
            
            executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            executeTemplateInput.isPreview = false;
            executeTemplateInput.inputParams = inputParams;
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('ENT_AggregatedEntityAnalysis', executeTemplateInput);
            System.debug(LoggingLevel.INFO, 'Aggregated Entity Analysis LLM Response: ' + generationsOutput);
            
            if (generationsOutput.generations != null && generationsOutput.generations.size() > 0) {
                String response = generationsOutput.generations[0].text;
                return parseAggregatedAIResponse(response);
            } else {
                throw new ENT_ServiceException(generationsOutput.generationErrors[0].localizedErrorMessage);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error calling Aggregated Entity Analysis PromptBuilder: ' + e.getMessage());
            throw new ENT_ServiceException('Error calling Aggregated Entity Analysis PromptBuilder: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses the AI response to extract aggregated entity analysis results
     * @param aiResponse The raw AI response text
     * @return AggregatedEntityAnalysisResult The parsed analysis results
     */
    private static AggregatedEntityAnalysisResult parseAggregatedAIResponse(String aiResponse) {
        try {
            System.debug(LoggingLevel.INFO, 'ENT_AggregatedEntityAnalysis response: ' + aiResponse);
            
            String cleanedResponse = aiResponse.replaceAll('```', '').replaceAll('json', '').trim();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(cleanedResponse);
            
            String claimant1 = (String) responseMap.get('claimant1');
            String claimant1Reason = (String) responseMap.get('claimant1Reason');
            String claimant2 = (String) responseMap.get('claimant2');
            String claimant2Reason = (String) responseMap.get('claimant2Reason');
            String representative = (String) responseMap.get('representative');
            String representativeReason = (String) responseMap.get('representativeReason');
            String firm = (String) responseMap.get('firm');
            String firmReason = (String) responseMap.get('firmReason');
            String others = (String) responseMap.get('others');
            String othersReason = (String) responseMap.get('othersReason');
            
            return new AggregatedEntityAnalysisResult(
                claimant1, claimant1Reason,
                claimant2, claimant2Reason,
                representative, representativeReason,
                firm, firmReason,
                others, othersReason
            );
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing Aggregated Entity Analysis response: ' + e.getMessage());
            throw new ENT_ServiceException('Error parsing Aggregated Entity Analysis response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Inner class to hold aggregated entity analysis results
     */
    public class AggregatedEntityAnalysisResult {
        @AuraEnabled public String claimant1 { get; set; }
        @AuraEnabled public String claimant1Reason { get; set; }
        @AuraEnabled public String claimant2 { get; set; }
        @AuraEnabled public String claimant2Reason { get; set; }
        @AuraEnabled public String representative { get; set; }
        @AuraEnabled public String representativeReason { get; set; }
        @AuraEnabled public String firm { get; set; }
        @AuraEnabled public String firmReason { get; set; }
        @AuraEnabled public String others { get; set; }
        @AuraEnabled public String othersReason { get; set; }
        
        public AggregatedEntityAnalysisResult() {
            this.claimant1 = '';
            this.claimant1Reason = '';
            this.claimant2 = '';
            this.claimant2Reason = '';
            this.representative = '';
            this.representativeReason = '';
            this.firm = '';
            this.firmReason = '';
            this.others = '';
            this.othersReason = '';
        }
        
        public AggregatedEntityAnalysisResult(
            String claimant1, String claimant1Reason,
            String claimant2, String claimant2Reason,
            String representative, String representativeReason,
            String firm, String firmReason,
            String others, String othersReason
        ) {
            this.claimant1 = claimant1;
            this.claimant1Reason = claimant1Reason;
            this.claimant2 = claimant2;
            this.claimant2Reason = claimant2Reason;
            this.representative = representative;
            this.representativeReason = representativeReason;
            this.firm = firm;
            this.firmReason = firmReason;
            this.others = others;
            this.othersReason = othersReason;
        }
    }
    
    /**
     * @description Custom exception class for ENT_EntityService
     */
    public class ENT_ServiceException extends Exception {}
}
