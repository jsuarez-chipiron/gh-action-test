/**
 * @description Service class for spam detection functionality using GenAI Prompt Templates.
 * This service analyzes cases and their associated email messages to detect spam content
 * and persists the analysis results to the DOM_CaseExtension object.
 * 
 * IMPORTANT: This service requires email messages to be associated with the case for analysis.
 * Cases without email messages will cause the service to fail with a clear error message.
 */
public with sharing class SPAM_SpamService {
    
    /**
     * @description Analyzes a case for spam detection and persists the results to DOM_CaseExtension.
     * This method requires the case to have associated email messages for analysis.
     * 
     * @param caseRecord The case record to analyze (must have Id, Subject, and Description fields populated)
     * @return DOM_CaseExtension__c The case extension record with spam analysis results
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     *   - caseRecord.Subject is null or empty
     *   - caseRecord.Description is null or empty
     *   - No email messages are found for the case (case must have associated emails for spam analysis)
     * 
     * @throws SPAM_ServiceException When there's an error during:
     *   - GenAI Prompt Template invocation (propagated from performSpamAnalysis)
     *   - JSON parsing of the AI response (propagated from performSpamAnalysis)
     *   - Persistence to DOM_CaseExtension object
     *   - Any other unexpected error during the analysis process
     */
    public static DOM_CaseExtension__c analyzeForSpamAndPersist(Case caseRecord) {
        try {
            validateCaseFields(caseRecord);
            
            List<EmailMessage> emails = DOM_CaseService.getEmailsForCase(caseRecord);
            
            validateEmailMessages(caseRecord, emails);

            //TODO: Change to use the email record, not the 0 index
            SpamAnalysisResult analysisResult = performSpamAnalysis(caseRecord,emails[0]);
            
            return DOM_CaseService.updateSpamInformation(
                caseRecord, 
                analysisResult.isSpam, 
                analysisResult.reason, 
                analysisResult.accuracy
            );
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing case for spam: ' + e.getMessage());
            throw new SPAM_ServiceException('Failed to analyze case for spam: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Validates that the case record has all required fields for spam analysis
     * @param caseRecord The case record to validate
     * @throws IllegalArgumentException When required fields are missing or invalid
     */
    private static void validateCaseFields(Case caseRecord) {
        if (caseRecord == null) {
            throw new IllegalArgumentException('Case record cannot be null');
        }
        if (caseRecord.Id == null) {
            throw new IllegalArgumentException('Case Id field is required for spam analysis');
        }
        if (caseRecord.Subject == null) {
            throw new IllegalArgumentException('Case Subject field is required for spam analysis');
        }
        if (caseRecord.Description == null) {
            throw new IllegalArgumentException('Case Description field is required for spam analysis');
        }
    }
    
    /**
     * @description Validates that the case has associated email messages for spam analysis
     * @param caseRecord The case record to validate
     * @param emailMessages List of email messages associated with the case
     * @throws IllegalArgumentException When no email messages are found for the case
     */
    private static void validateEmailMessages(Case caseRecord, List<EmailMessage> emailMessages) {
        if (emailMessages == null || emailMessages.isEmpty()) {
            throw new IllegalArgumentException(
                'Case with Id "' + caseRecord.Id + '" must have associated email messages for spam analysis. ' +
                'No email messages were found for this case.'
            );
        }
    }
    
    /**
     * @description Performs spam analysis on the provided content using GenAI Prompt Template.
     * This method is synchronous and will throw exceptions if the analysis fails.
     * 
     * @param emailContent The content to analyze for spam
     * @return SpamAnalysisResult The result of the spam analysis
     * @throws SPAM_ServiceException When there's an error during GenAI Prompt Template invocation or JSON parsing
     */
    private static SpamAnalysisResult performSpamAnalysis(Case caseRecord, EmailMessage emailRecord) {
        if (Test.isRunningTest()) {
            return performMockSpamAnalysis(caseRecord,emailRecord);
        }
        Map<String, String> csId = new Map<String, String>();
        csId.put('id', caseRecord.Id);
        ConnectApi.WrappedValue csValue = new ConnectApi.WrappedValue();
        csValue.value = csId;
        
        Map<String, String> emailId = new Map<String, String>();
        emailId.put('id', emailRecord.Id);
        ConnectApi.WrappedValue emailValue = new ConnectApi.WrappedValue();
        emailValue.value = emailId;

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:case', csValue);
        inputParams.put('Input:email', emailValue);

        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'SPAM_Analysis',
            executeTemplateInput
        );

        System.debug(LoggingLevel.INFO, 'SPAM_Analysis response: ' + generationsOutput);
        
        String responseText = generationsOutput.generations[0].text;
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText.replaceAll('```', '').replaceAll('json', ''));
        
        SpamAnalysisResult result = new SpamAnalysisResult();
        result.isSpam = (Boolean) responseMap.get('isSpam');
        result.reason = (String) responseMap.get('reason');
        result.accuracy = (Decimal) responseMap.get('accuracy');
        
        return result;
    }
    
    /**
     * @description Performs mock spam analysis for testing purposes
     * @param emailContent The content to analyze for spam
     * @return SpamAnalysisResult The mock result of the spam analysis
     */
    private static SpamAnalysisResult performMockSpamAnalysis(Case caseRecord, EmailMessage emailRecord) {
        SpamAnalysisResult result = new SpamAnalysisResult();
        
        result.isSpam = false;
        result.reason = 'Mock test: Analysis completed successfully';
        result.accuracy = 0.25;
        
        return result;
    }
    
    /**
     * @description Inner class to hold spam analysis results
     */
    public class SpamAnalysisResult {
        @AuraEnabled public Boolean isSpam { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public Decimal accuracy { get; set; }
        
        public SpamAnalysisResult() {
            this.isSpam = false;
            this.reason = '';
            this.accuracy = 0.0;
        }
    }
    
    /**
     * @description Custom exception class for SPAM_Service
     */
    public class SPAM_ServiceException extends Exception {}
}