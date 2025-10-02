trigger APP_CaseExtensionTrigger on DOM_CaseExtension__c (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete,
    after undelete
) {
    // Before Insert
    if (Trigger.isBefore && Trigger.isInsert) {
        // Call service method
    }

    // After Insert
    if (Trigger.isAfter && Trigger.isInsert) {
        APP_CaseExtensionService.sendMailWithAImetrics(Trigger.new);
    }

    // Before Update
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Call service method
    }

    // After Update
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Call service method
        APP_CaseExtensionService.sendMailWithAImetrics(Trigger.new);
    }

    // Before Delete
    if (Trigger.isBefore && Trigger.isDelete) {
        // Call service method
    }

    // After Delete
    if (Trigger.isAfter && Trigger.isDelete) {
        // Call service method
    }

    // After Undelete
    if (Trigger.isAfter && Trigger.isUndelete) {
        // Call service method
    }
}
