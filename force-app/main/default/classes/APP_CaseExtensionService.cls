public with sharing class APP_CaseExtensionService {
    public static void sendMailWithAImetrics(List<DOM_CaseExtension__c> caseExtensions) {

        if (caseExtensions == null || caseExtensions.isEmpty()) {
            throw new IllegalArgumentException('Case extensions cannot be null or empty');
        }

        // TODO: Evaluate if we need to handle multiple case extensions
        if (caseExtensions.size() > 1) {
            System.debug(LoggingLevel.WARN, 'Expected exactly one case extension, but found: ' + caseExtensions.size());
            return;
        }

        try {
            if ( caseExtensions.get(0).DOM_Status__c == DOM_Config.LAUNCH_RESULT_EXTENSION_STATUS ) {
                // TODO: Evaluate if this query can be cached
                Case associatedCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseExtensions[0].DOM_caseId__c LIMIT 1];
                EVAL_EmailService.sendAIMetrics(associatedCase);
            }
        } catch (EVAL_EmailService.EVAL_EmailServiceException e) {
            System.debug(LoggingLevel.ERROR, 'Error sending email with AI metrics: ' + e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error sending email with AI metrics: ' + e.getMessage());
        }
    }
}