/**
 * @description Service class for case derivation functionality using business rules.
 * This service analyzes cases and applies derivation rules to determine if a case
 * should be derived to another system, process, or workflow based on content analysis.
 */
public with sharing class DRV_CaseDerivationService {
    
    /**
     * @description Analyzes a case for derivation and applies business rules to determine
     * if the case should be derived to another system or process.
     * This method evaluates the case content and metadata to determine derivation decisions
     * based on GenAI analysis of case and email content.
     * 
     * IMPORTANT: This service requires email messages to be associated with the case for analysis.
     * Cases without email messages will cause the service to fail with a clear error message.
     * 
     * @param caseRecord The case record to analyze (must have Id, Subject, and Description fields populated)
     * @return DOM_CaseExtension__c The case extension record with derivation results
     * 
     * @throws IllegalArgumentException When:
     *   - caseRecord is null
     *   - caseRecord.Id is null
     *   - caseRecord.Subject is null or empty
     *   - caseRecord.Description is null or empty
     *   - No email messages are found for the case (case must have associated emails for derivation analysis)
     * 
     * @throws DRV_ServiceException When there's an error during:
     *   - GenAI Prompt Template invocation (propagated from performCaseDerivation)
     *   - JSON parsing of the AI response (propagated from performCaseDerivation)
     *   - Persistence to DOM_CaseExtension object
     *   - Any other unexpected error during the derivation process
     */
    public static DOM_CaseExtension__c analyzeForDerivationAndPersist(Case caseRecord) {
        try {
            validateCaseFields(caseRecord);
            
            List<EmailMessage> emails = DOM_CaseService.getEmailsForCase(caseRecord);
            
            validateEmailMessages(caseRecord, emails);
            
            DerivationResult derivationResult = performCaseDerivation(caseRecord, emails[0]);
            
            return DOM_CaseService.updateDerivationInformation(
                caseRecord, 
                derivationResult.isDerivated, 
                derivationResult.derivatedTo, 
                derivationResult.reason,
                derivationResult.accuracy
            );
            
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error deriving case: ' + e.getMessage());
            throw new DRV_ServiceException('Failed to derive case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Validates that the case record has all required fields for derivation analysis
     * @param caseRecord The case record to validate
     * @throws IllegalArgumentException When required fields are missing or invalid
     */
    private static void validateCaseFields(Case caseRecord) {
        if (caseRecord == null) {
            throw new IllegalArgumentException('Case record cannot be null');
        }
        if (caseRecord.Id == null) {
            throw new IllegalArgumentException('Case Id field is required for derivation analysis');
        }
        if (caseRecord.Subject == null || caseRecord.Subject.trim() == '') {
            throw new IllegalArgumentException('Case Subject field is required for derivation analysis');
        }
        if (caseRecord.Description == null || caseRecord.Description.trim() == '') {
            throw new IllegalArgumentException('Case Description field is required for derivation analysis');
        }
    }
    
    /**
     * @description Validates that the case has associated email messages for derivation analysis
     * @param caseRecord The case record to validate
     * @param emailMessages List of email messages associated with the case
     * @throws IllegalArgumentException When no email messages are found for the case
     */
    private static void validateEmailMessages(Case caseRecord, List<EmailMessage> emailMessages) {
        if (emailMessages == null || emailMessages.isEmpty()) {
            throw new IllegalArgumentException(
                'Case with Id "' + caseRecord.Id + '" must have associated email messages for derivation analysis. ' +
                'No email messages were found for this case.'
            );
        }
    }
    
    /**
     * @description Performs case derivation analysis using GenAI Prompt Template.
     * This method is synchronous and will throw exceptions if the analysis fails.
     * 
     * @param caseRecord The case record to analyze
     * @param emailRecord The email message associated with the case
     * @return DerivationResult The result of the derivation analysis
     * @throws DRV_ServiceException When there's an error during GenAI Prompt Template invocation or JSON parsing
     */
    private static DerivationResult performCaseDerivation(Case caseRecord, EmailMessage emailRecord) {
        if (Test.isRunningTest()) {
            return performMockDerivationAnalysis(caseRecord, emailRecord);
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
            'DRV_Analysis',
            executeTemplateInput
        );

        System.debug(LoggingLevel.INFO, 'DRV_Analysis response: ' + generationsOutput);
        
        String responseText = generationsOutput.generations[0].text;
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseText.replaceAll('```', '').replaceAll('json', ''));
        
        DerivationResult result = new DerivationResult();
        result.isDerivated = (Boolean) responseMap.get('isDerivated');
        result.derivatedTo = (String) responseMap.get('derivatedTo');
        result.reason = (String) responseMap.get('reason');
        result.accuracy = (Decimal) responseMap.get('accuracy');
        
        return result;
    }
    
    /**
     * @description Performs mock derivation analysis for testing purposes
     * @param caseRecord The case record to analyze
     * @param emailRecord The email message associated with the case
     * @return DerivationResult The mock result of the derivation analysis
     */
    private static DerivationResult performMockDerivationAnalysis(Case caseRecord, EmailMessage emailRecord) {
        DerivationResult result = new DerivationResult();
        
        result.isDerivated = false;
        result.derivatedTo = '';
        result.reason = 'Mock test: Derivation analysis completed successfully';
        result.accuracy = 0.85;
        
        return result;
    }
    

    
    /**
     * @description Inner class to hold derivation analysis results
     */
    public class DerivationResult {
        public Boolean isDerivated { get; set; }
        public String derivatedTo { get; set; }
        public String reason { get; set; }
        public Decimal accuracy { get; set; }
        
        public DerivationResult() {
            this.isDerivated = false;
            this.derivatedTo = '';
            this.reason = '';
            this.accuracy = 0.0;
        }
    }
    
    /**
     * @description Custom exception class for DRV service errors
     */
    public class DRV_ServiceException extends Exception {}
}