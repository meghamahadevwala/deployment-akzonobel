public with sharing class SLAAssignedDaysService {

    // ─── Entry point from trigger ────────────────────────────────────────────

    public static void assignSLADays(
        List<celsrm__Dispute__c> newList,
        Map<Id, celsrm__Dispute__c> oldMap
    ) {
        for (celsrm__Dispute__c dispute : newList) {
            if (!hasRelevantChange(dispute, oldMap)) continue;

            Integer sladays = resolveSLADays(dispute);
            if (sladays != null) {
                dispute.Dispute_SLA_Days__c = sladays;
            }
        }
    }

    // ─── Only run when relevant fields changed ───────────────────────────────

    private static Boolean hasRelevantChange(
        celsrm__Dispute__c dispute,
        Map<Id, celsrm__Dispute__c> oldMap
    ) {
        if (oldMap == null) return true; // insert

        celsrm__Dispute__c old = oldMap.get(dispute.Id);
        return dispute.Business_Unit__c          != old.Business_Unit__c
            || dispute.celsrm__Dispute_Type__c   != old.celsrm__Dispute_Type__c
            || dispute.celsrm__Reason_Code__c    != old.celsrm__Reason_Code__c;
    }

    // ─── Main router by BU ───────────────────────────────────────────────────

    private static Integer resolveSLADays(celsrm__Dispute__c d) {
        String bu   = d.Business_Unit__c;
        String type = d.celsrm__Dispute_Type__c;
        String rc   = d.celsrm__Reason_Code__c;

        if (bu == null) return null;

        switch on bu {
            when 'BU ASC'     { return slaASC(type, rc); }
            when 'BU MPY'     { return slaMPY(type, rc); }
            when 'BU ICO'     { return slaICO(type, rc); }
            when 'BU Powder'  { return slaPowder(type, rc); }
            when 'DP EMEA'    { return slaEMEA(type, rc); }
            when 'DP SESA'    { return slaSESA(type, rc); }
            when 'DP CNA'     { return slaCNA(type, rc); }
            when 'DP SAM'     { return 19; }
            when else         { return null; }
        }
    }

    // ─── BU ASC ──────────────────────────────────────────────────────────────

    private static Integer slaASC(String type, String rc) {
        if (typeIn(type, new Set<String>{ '100 Financial & Invoicing', '400 Marketing', '500 Contact & Service' }))
            return 5;
        if (rcIn(rc, new Set<String>{ '602 Color Documentation', '603 Color From Measurement', '604 Gloss' }))
            return 10;
        if (rcIn(rc, new Set<String>{ '202 Equipment/Tools(non-paint)' }))
            return 20;
        if (typeIn(type, new Set<String>{ '300 Order Delivery' }))
            return 30;
        if (rcIn(rc, new Set<String>{ '201 During Application' }))
            return 50;
        return null;
    }

    // ─── BU MPY ──────────────────────────────────────────────────────────────

    private static Integer slaMPY(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '101 Cash Discount Deduction', '102 Deducted Vendor Invoice',
                                      '103 Incorrect Invoice Masterdata', '104 Invoice not Received' })
            || typeIn(type, new Set<String>{ '400 Marketing' }))
            return 5;
        if (rcIn(rc, new Set<String>{ '105 Payment In Transit', '106 Pricing Error',
                                      '107 Rebates', '108 Short Payment' })
            || typeIn(type, new Set<String>{ '500 Contact & Service' }))
            return 10;
        if (typeIn(type, new Set<String>{ '300 Order Delivery' }))
            return 30;
        if (typeIn(type, new Set<String>{ '400 Marketing' }))
            return 40;
        if (typeIn(type, new Set<String>{ '200 Product Quality' }))
            return 60;
        return null;
    }

    // ─── BU ICO ──────────────────────────────────────────────────────────────

    private static Integer slaICO(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '101 Cash Discount Deduction', '102 Deducted Vendor Invoice',
                                      '103 Incorrect Invoice Masterdata', '104 Invoice not Received' }))
            return 5;
        if (rcIn(rc, new Set<String>{ '105 Payment In Transit', '106 Pricing Error',
                                      '107 Rebates', '108 Short Payment' })
            || typeIn(type, new Set<String>{ '400 Marketing', '500 Contact & Service' }))
            return 10;
        if (typeIn(type, new Set<String>{ '300 Order Delivery' }))
            return 30;
        if (typeIn(type, new Set<String>{ '200 Product Quality', '600 Color' }))
            return 60;
        return null;
    }

    // ─── BU Powder ───────────────────────────────────────────────────────────

    private static Integer slaPowder(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '101 Cash Discount Deduction', '102 Deducted Vendor Invoice',
                                      '103 Incorrect Invoice Masterdata', '104 Invoice not Received' })
            || typeIn(type, new Set<String>{ '400 Marketing', '500 Contact & Service' }))
            return 5;
        if (rcIn(rc, new Set<String>{ '105 Payment In Transit', '106 Pricing Error', '107 Rebates',
                                      '108 Short Payment', '202 Equipment/Tools(non-paint)',
                                      '206 Product Documentation' })
            || typeIn(type, new Set<String>{ '600 Color' }))
            return 10;
        if (rcIn(rc, new Set<String>{ '302 Delivery Documentation & Information' }))
            return 25;
        if (rcIn(rc, new Set<String>{ '203 Packaging & Labeling', '303 Delivery Quantity' }))
            return 30;
        if (rcIn(rc, new Set<String>{ '201 During Application', '204 Post Application',
                                      '205 Pre Application', '207 Software', '208 Trial Batch',
                                      '301 Delivery Damaged', '304 Delivery Timing', '305 Wrong Product' }))
            return 35;
        return null;
    }

    // ─── DP EMEA ─────────────────────────────────────────────────────────────

    private static Integer slaEMEA(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '302 Delivery Documentation & Information', '501 Advice & Support',
                                      '503 Stores', '504 Website / e-commerce' })
            || typeIn(type, new Set<String>{ '100 Financial & Invoicing', '400 Marketing' }))
            return 5;
        if (rcIn(rc, new Set<String>{ '301 Delivery Damaged', '303 Delivery Quantity', '304 Delivery Timing' }))
            return 7;
        if (typeIn(type, new Set<String>{ '200 Product Quality', '600 Color' }))
            return 10;
        if (rcIn(rc, new Set<String>{ '205 Pre Application', '305 Wrong Product' }))
            return 12;
        if (rcIn(rc, new Set<String>{ '502 AkzoNobel Certified Painters' }))
            return 20;
        return null;
    }

    // ─── DP SESA ─────────────────────────────────────────────────────────────

    private static Integer slaSESA(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '202 Equipment/Tools(non-paint)', '203 Packaging & Labeling',
                                      '206 Product Documentation' })
            || typeIn(type, new Set<String>{ '100 Financial & Invoicing', '300 Order Delivery', '400 Marketing' }))
            return 5;
        if (typeIn(type, new Set<String>{ '500 Contact & Service', '600 Color' })
            || rcIn(rc, new Set<String>{ '207 Software', '208 Trial Batch' }))
            return 10;
        if (rcIn(rc, new Set<String>{ '201 During Application', '204 Post Application', '205 Pre Application' }))
            return 30;
        return null;
    }

    // ─── DP CNA ──────────────────────────────────────────────────────────────

    private static Integer slaCNA(String type, String rc) {
        if (rcIn(rc, new Set<String>{ '206 Product Documentation' })
            || typeIn(type, new Set<String>{ '100 Financial & Invoicing', '300 Order Delivery',
                                             '400 Marketing', '500 Contact & Service' }))
            return 5;
        if (typeIn(type, new Set<String>{ '500 Contact & Service', '600 Color' }))
            return 10;
        return null;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static Boolean typeIn(String type, Set<String> values) {
        return type != null && values.contains(type);
    }

    private static Boolean rcIn(String rc, Set<String> values) {
        return rc != null && values.contains(rc);
    }
}