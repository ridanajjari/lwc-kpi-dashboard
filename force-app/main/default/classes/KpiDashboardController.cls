/**
 * Apex controller for the kpiDashboard LWC.
 * Returns all dashboard metrics in one Apex call (one server round trip)
 * built from four SOQL queries: open cases, open pipeline, leads created
 * this month grouped by IsConverted, and won opportunities this month.
 */
public with sharing class KpiDashboardController {
  public class KpiData {
    @AuraEnabled
    public Integer openCases { get; set; }
    @AuraEnabled
    public Integer newLeadsThisMonth { get; set; }
    @AuraEnabled
    public Decimal pipelineValue { get; set; }
    @AuraEnabled
    public Decimal leadConversionRate { get; set; }
    @AuraEnabled
    public Integer closedWonThisMonth { get; set; }
  }

  @AuraEnabled(cacheable=true)
  public static KpiData getKpiData() {
    KpiData data = new KpiData();

    // Open Cases
    data.openCases = [SELECT COUNT() FROM Case WHERE IsClosed = FALSE];

    // Open pipeline value (Opportunities not Closed)
    AggregateResult pipeline = [
      SELECT SUM(Amount) total
      FROM Opportunity
      WHERE IsClosed = FALSE
    ];
    data.pipelineValue = (Decimal) pipeline.get('total') ?? 0;

    // Leads created this month (THIS_MONTH uses the running user's time
    // zone), counted in one aggregate query grouped by IsConverted.
    Integer convertedLeads = 0;
    Integer unconvertedLeads = 0;
    for (AggregateResult row : [
      SELECT IsConverted, COUNT(Id) total
      FROM Lead
      WHERE CreatedDate = THIS_MONTH
      GROUP BY IsConverted
    ]) {
      Integer total = (Integer) row.get('total');
      if ((Boolean) row.get('IsConverted')) {
        convertedLeads = total;
      } else {
        unconvertedLeads = total;
      }
    }
    Integer totalLeads = convertedLeads + unconvertedLeads;

    // New leads this month that are not yet converted
    data.newLeadsThisMonth = unconvertedLeads;
    // Converted / all leads created this month, as a percentage
    data.leadConversionRate = totalLeads > 0
      ? (convertedLeads * 100.0 / totalLeads).setScale(1)
      : 0;

    // Won this month: IsWon covers every won stage, whatever its label
    data.closedWonThisMonth = [
      SELECT COUNT()
      FROM Opportunity
      WHERE IsWon = TRUE AND CloseDate = THIS_MONTH
    ];

    return data;
  }
}
