public class EVAL_EmailService {

    /**
     * @description Sends an email with AI metrics for a given Case.
     * @param aCase The Case record to process.
     */
    public static void sendAIMetrics(Case aCase) {
        if (aCase == null || aCase.Id == null) {
            System.debug(LoggingLevel.ERROR, 'EVAL_EmailService.sendAIMetrics was called with a null Case or Case Id.');
            return;
        }

        String toAddress = 'jsuarez@salesforce.com';
        String subject = 'Métricas de IA procesadas para el Caso: ' + aCase.CaseNumber;

        try {
            // Retrieve AI metrics from the related Case Extension object
            DOM_CaseExtension__c caseExtension = DOM_CaseExtensionService.retrieveAIMetricsByCase(aCase);

            // Generate the email body using the template
            String body = generateMailBody(aCase, caseExtension);

            // Create and send the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ toAddress });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Correo enviado exitosamente a: ' + toAddress);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error al enviar el correo: ' + e.getMessage());
            throw new EVAL_EmailServiceException('Error al enviar el correo de métricas de IA: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Generates the email body using a template and data from the Case and its extension.
     * @param aCase The parent Case record.
     * @param caseExtension The related Case Extension record containing AI metrics.
     * @return A formatted string for the email body.
     */
    private static String generateMailBody(Case aCase, DOM_CaseExtension__c caseExtension) {
        String caseNumber = aCase.CaseNumber;
        
        // Default values if the extension or its fields are null
        String isSpam = 'No disponible';
        String spamAccuracy = 'No disponible';
        String spamReason = 'No disponible';
        String langLang = 'No disponible';
        String langReason = 'No disponible';
        String langAccuracy = 'No disponible';

        if (caseExtension != null) {
            isSpam = String.valueOf(caseExtension.SPAM_isSpam__c);
            spamAccuracy = caseExtension.SPAM_Accuracy__c != null ? String.valueOf(caseExtension.SPAM_Accuracy__c) : '0';
            spamReason = String.isNotBlank(caseExtension.SPAM_Reason__c) ? caseExtension.SPAM_Reason__c : 'Sin motivo especificado.';
            langLang = String.isNotBlank(caseExtension.LANG_lang__c) ? caseExtension.LANG_lang__c : 'No disponible';
            langReason = String.isNotBlank(caseExtension.LANG_Reason__c) ? caseExtension.LANG_Reason__c : 'Sin motivo especificado.';
            langAccuracy = caseExtension.LANG_accuracy__c != null ? String.valueOf(caseExtension.LANG_accuracy__c) : '0';
        }

        // Format the final string using the template
        List<String> bodyArgs = new List<String>{
            caseNumber,
            isSpam,
            spamAccuracy,
            spamReason,
            langLang,
            langReason,
            langAccuracy
        };
        
        return String.format(EVAL_Config.AI_METRICS_EMAIL_BODY_TEMPLATE, bodyArgs);
    }

    /**
     * @description Custom exception class for EVAL_EmailService
     */
    public class EVAL_EmailServiceException extends Exception {}
}