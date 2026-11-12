/**
 * Apex controller for the kpiDashboard LWC.
 * Returns aggregated metrics in a single callout to minimize SOQL usage.
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

    // New Leads this calendar month (THIS_MONTH uses the running user's time zone)
    data.newLeadsThisMonth = [
      SELECT COUNT()
      FROM Lead
      WHERE CreatedDate = THIS_MONTH AND IsConverted = FALSE
    ];

    // Open pipeline value (Opportunities not Closed)
    AggregateResult pipeline = [
      SELECT SUM(Amount) total
      FROM Opportunity
      WHERE IsClosed = FALSE
    ];
    data.pipelineValue = (Decimal) pipeline.get('total') ?? 0;

    // Lead conversion rate (converted / total) this month — as a %
    Integer totalLeads = [
      SELECT COUNT()
      FROM Lead
      WHERE CreatedDate = THIS_MONTH
    ];
    Integer convertedLeads = [
      SELECT COUNT()
      FROM Lead
      WHERE CreatedDate = THIS_MONTH AND IsConverted = TRUE
    ];
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
