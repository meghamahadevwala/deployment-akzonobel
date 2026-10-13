/**
 * Local (subscriber-org) copy of celsrm ContentWorkspaceBatch.
 * The package class ContentWorkspaceBatch is public (not global) and its helper
 * GOGEmailMapper.insertContentWorkspaceDoc is also public (not global), so neither
 * can be referenced via the celsrm namespace from the subscriber org.
 * The self-contained ContentWorkspaceDoc logic is therefore inlined here.
 * ContentWorkspaceDoc is a standard object, so no namespace prefix is required.
 */
public class cContentWorkspaceBatch implements Database.Batchable<String> {
    private List<String> allIds;
    private Id targetLibraryId;

    public cContentWorkspaceBatch(List<String> ids, Id libId) {
        this.allIds = ids;
        this.targetLibraryId = libId;
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return allIds; // Passes the list of IDs to the execute method in chunks
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        insertContentWorkspaceDoc(scope, targetLibraryId);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing for ContentWorkspaceDoc complete.');
    }

    // Inlined from celsrm GOGEmailMapper.insertContentWorkspaceDoc (public, not global)
    public static void insertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId) {
        System.debug('Attempting to insert ContentWorkspaceDocs');
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc>();
        for (ContentWorkspaceDoc contentWorkspaceDocObj : [SELECT Id, ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(contentWorkspaceDocObj.ContentDocumentId);
            if (documentIdsIndex > -1) {
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            if (contenctWorkspaceDocList.size() > 0) {
                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
            }
        } catch (Exception e) {
            System.debug('Error in insertContentWorkspaceDoc:' + e);
            reInsertContentWorkspaceDoc(documentIds, contentWorkspaceId);
        }
    }

    @future(callout=true)
    public static void reInsertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId) {
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc>();
        for (ContentWorkspaceDoc contentWorkspaceDocObj : [SELECT Id, ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(contentWorkspaceDocObj.ContentDocumentId);
            if (documentIdsIndex > -1) {
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            System.debug('Attempt-1 to re-insert ContentWorkspaceDocs');
            Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
        } catch (Exception ex1) {
            System.debug('Error in attempt-1 inserting ContentWorkspaceDocs:' + ex1);
            try {
                System.debug('Attempt-2 to re-insert ContentWorkspaceDocs');
                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
            } catch (Exception ex2) {
                System.debug('Error in attempt-2 inserting ContentWorkspaceDocs:' + ex2);
                try {
                    System.debug('Attempt-3 to re-insert ContentWorkspaceDocs');
                    Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                } catch (Exception ex3) {
                    System.debug('Error in attempt-3 inserting ContentWorkspaceDocs:' + ex3);
                    try {
                        System.debug('Attempt-4 to re-insert ContentWorkspaceDocs');
                        Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                    } catch (Exception ex4) {
                        System.debug('Error in attempt-4 inserting ContentWorkspaceDocs:' + ex4);
                        try {
                            System.debug('Attempt-5 to re-insert ContentWorkspaceDocs');
                            Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                        } catch (Exception ex5) {
                            System.debug('Error in attempt-5 inserting ContentWorkspaceDocs:' + ex5);
                            try {
                                System.debug('finale Attempt to re-insert ContentWorkspaceDocs');
                                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                            } catch (Exception ex6) {
                                System.debug('The final attempt failed inserting ContentWorkspaceDocs:' + ex6);
                                throw new cContentWorkspaceBatchException('The final attempt failed inserting ContentWorkspaceDocs: ' + ex6.getMessage());
                            }
                        }
                    }
                }
            }
        }
    }

    public class cContentWorkspaceBatchException extends Exception {}
}