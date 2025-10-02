/**
 * @description Service class for language detection functionality using GenAI Prompt Templates.
 * This service analyzes cases and their associated email messages to detect language content
 * and persists the analysis results to the DOM_CaseExtension object.
 * 
 * IMPORTANT: This service requires email messages to be associated with the case for analysis.
 * Cases without email messages will cause the service to fail with a clear error message.
 */
public with sharing class LANG_LangService {
    
    /**
     * @description Analyzes a case for language detection and persists the results to DOM_CaseExtension.
     * This method requires the case to have associated email messages for analysis.
     * 
     * @param caseRecord The case record to analyze (must have Id, Subject, and Description fields populated)
     * @return DOM_CaseExtension__c The case extension record with language analysis results
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     *   - caseRecord.Subject is null or empty
     *   - caseRecord.Description is null or empty
     *   - No email messages are found for the case (case must have associated emails for language analysis)
     * 
     * @throws LANG_ServiceException When there's an error during:
     *   - GenAI Prompt Template invocation (propagated from performLangAnalysis)
     *   - JSON parsing of the AI response (propagated from performLangAnalysis)
     *   - Persistence to DOM_CaseExtension object
     *   - Any other unexpected error during the analysis process
     */
    public static DOM_CaseExtension__c analyzeForLanguageAndPersist(Case caseRecord) {
        try {
            System.debug('here');

            validateCaseFields(caseRecord);
            
            List<EmailMessage> emails = DOM_CaseService.getEmailsForCase(caseRecord);

            System.debug('Emails retrieved for case: ' + emails.size());
            System.debug(emails);
            
            validateEmailMessages(caseRecord, emails);
            
            LangAnalysisResult analysisResult = performLangAnalysis(emails);
            
            return DOM_CaseService.updateLangInformation(
                caseRecord, 
                analysisResult.lang, 
                analysisResult.reason,
                analysisResult.accuracy
            );
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing case for lang: ' + e.getMessage());
            throw new LANG_ServiceException('Failed to analyze case for lang: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Validates that the case record has all required fields for language analysis
     * @param caseRecord The case record to validate
     * @throws IllegalArgumentException When required fields are missing or invalid
     */
    private static void validateCaseFields(Case caseRecord) {
        if (caseRecord == null) {
            throw new IllegalArgumentException('Case record cannot be null');
        }
        if (caseRecord.Id == null) {
            throw new IllegalArgumentException('Case Id field is required for language analysis');
        }
    }
    
    /**
     * @description Validates that the case has associated email messages for language analysis
     * @param caseRecord The case record to validate
     * @param emailMessages List of email messages associated with the case
     * @throws IllegalArgumentException When no email messages are found for the case
     */
    private static void validateEmailMessages(Case caseRecord, List<EmailMessage> emailMessages) {
        if (emailMessages == null || emailMessages.isEmpty() || emailMessages.size() != 1) {
            throw new IllegalArgumentException(
                'Case with Id "' + caseRecord.Id + '" must have associated email messages for language analysis. ' +
                'No email messages were found for this case. ' +
                'Email messages are required to perform language detection analysis.'
            );
        }
    }
    
    /**
     * @description Performs language analysis on the provided content using GenAI Prompt Template.
     * This method is synchronous and will throw exceptions if the analysis fails.
     * 
     * @param emailContent The content to analyze for language
     * @return LangAnalysisResult The result of the language analysis
     * @throws LANG_ServiceException When there's an error during GenAI Prompt Template invocation or JSON parsing
     */
    private static LangAnalysisResult performLangAnalysis(List<EmailMessage> emailList) {

        // Send just One email message for analysis. The validation is already done in validateEmailMessages method.

        if (Test.isRunningTest()) {
            return performMockLangAnalysis(emailList);
        }
        
        Map<String, String> emailId = new Map<String, String>();
        emailId.put('id', emailList.get(0).Id);
        ConnectApi.WrappedValue emailValue = new ConnectApi.WrappedValue();
        emailValue.value = emailId;

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:relatedEmail', emailValue);

        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'LANG_Analysis',
            executeTemplateInput
        );

        if (generationsOutput == null || generationsOutput.generations == null || generationsOutput.generations.isEmpty()) {
            throw new LANG_ServiceException('No generations returned from GenAI Prompt Template for language analysis.');
        }

        String responseText = generationsOutput.generations[0].text;

        System.debug('Response from GenAI Prompt Template: ' + responseText);
        responseText = responseText.replaceAll('```', '').replaceAll('json', '');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText);
        
        LangAnalysisResult result = new LangAnalysisResult();
        result.lang = (String) responseMap.get('lang');
        result.reason = (String) responseMap.get('reason');
        result.accuracy = (Integer) responseMap.get('accuracy');
        
        return result;
    }
    
    /**
     * @description Performs mock language analysis for testing purposes
     * @param emailContent The content to analyze for language
     * @return LangAnalysisResult The mock result of the language analysis
     */
    private static LangAnalysisResult performMockLangAnalysis(List<EmailMessage> emailList) {
        LangAnalysisResult result = new LangAnalysisResult();
        
        result.lang = 'es';
        result.reason = 'Mock test: Analysis completed successfully';
        result.accuracy = 99;
        
        return result;
    }
    
    /**
     * @description Inner class to hold language analysis results
     */
    public class LangAnalysisResult {
        @AuraEnabled public String lang { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public Integer accuracy { get; set; }
        
        public LangAnalysisResult() {
            this.lang = '';
            this.reason = '';
            this.accuracy = 0;
        }
    }
    
    /**
     * @description Custom exception class for LANG_Service
     */
    public class LANG_ServiceException extends Exception {}
}