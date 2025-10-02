/**
 * @description Handles inbound emails to create a Case record in Salesforce.
 * It processes the email's subject and plain text body to populate a new Case.
 * It also handles both binary and text attachments by creating them as Files (ContentVersion)
 * and linking them to the newly created Case via ContentDocumentLink.
 *
 * This class must be configured as the Apex Class for a Salesforce Email Service.
 */
public with sharing class EVAL_EmailProcessorWithAttachments implements Messaging.InboundEmailHandler {

    /**
     * @description Required method for the Messaging.InboundEmailHandler interface.
     * This method is executed when the email service receives an email. It creates a Case from the email's
     * details (subject, body, origin) and attaches any files included in the email.
     * @param email The inbound email object, containing headers, subject, body, and attachments.
     * @param envelope The inbound envelope object, containing the 'from' and 'to' addresses from the SMTP transaction.
     * @return A Messaging.InboundEmailResult object. In this implementation, it always returns a successful result.
     */
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        // Store all this information in the Salesforce database
        System.debug('Email received from name: ' + email.fromName);

        Case newCase = new Case(
            // TODO: Change this to add to the extension object or match what the current development team is using
            Subject = email.subject,
            Description = email.plainTextBody,
            Origin = 'Email'
        );
        insert newCase;

        EmailMessage newEmailMessage = new EmailMessage(
            ParentId    = newCase.Id,
            Subject     = email.subject,
            HtmlBody    = email.htmlBody,
            TextBody    = email.plainTextBody,
            FromAddress = email.fromAddress,
            ToAddress   = email.toAddresses != null ? String.join(email.toAddresses, '; ') : '',
            CcAddress   = email.ccAddresses != null ? String.join(email.ccAddresses, '; ') : '',
            Incoming    = true,
            Status      = '0'
        );
        insert newEmailMessage;
        System.debug('EmailMessage created and linked to Case ' + newCase.Id);

        List<ContentVersion> contentVersions = processAttachments(email);

        if(!contentVersions.isEmpty()){
            insert contentVersions;

            List<ContentVersion> insertedContentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions];

            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            for(ContentVersion cv : insertedContentVersions){
                ContentDocumentLink cdlCase = createContentDocumentLink(cv, newCase.Id);
                cdlList.add(cdlCase);

                ContentDocumentLink cdlEmail = createContentDocumentLink(cv, newEmailMessage.Id);
                cdlList.add(cdlEmail);
            }
            insert cdlList;
            System.debug(contentVersions.size() + ' files attached to Case ' + newCase.Id + ' and EmailMessage ' + newEmailMessage.Id);
        }

        try {
            SPAM_SpamService.analyzeForSpamAndPersist(newCase);
            LANG_LangService.analyzeForLanguageAndPersist(newCase);
        }
        catch (IllegalArgumentException e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing for spam [IllegalArgumentException]: ' + e.getMessage());
        }
        catch (SPAM_SpamService.SPAM_ServiceException e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing for spam [SPAM_ServiceException]: ' + e.getMessage());
        }
        catch (LANG_LangService.LANG_ServiceException e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing for language [LANG_ServiceException]: ' + e.getMessage());
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error during spam/language analysis: ' + e.getMessage());
        }

        return result;
    }

    private static List<ContentVersion> processAttachments(Messaging.InboundEmail email) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
            for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                ContentVersion cv = new ContentVersion();
                cv.VersionData = attachment.body;
                cv.Title = attachment.fileName;
                cv.PathOnClient = attachment.fileName;
                contentVersions.add(cv);
                System.debug('Processing binary attachment: ' + attachment.fileName);
            }
        }

        if (email.textAttachments != null && email.textAttachments.size() > 0) {
            for (Messaging.InboundEmail.TextAttachment attachment : email.textAttachments) {
                ContentVersion cv = new ContentVersion();
                cv.VersionData = Blob.valueOf(attachment.body);
                cv.Title = attachment.fileName;
                cv.PathOnClient = attachment.fileName;
                contentVersions.add(cv);
                System.debug('Processing text attachment: ' + attachment.fileName);
            }
        }

        return contentVersions;
    }

    private static ContentDocumentLink createContentDocumentLink(ContentVersion cv, Id linkedEntityId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = 'V'; // Viewer access
        return cdl;
    }

}