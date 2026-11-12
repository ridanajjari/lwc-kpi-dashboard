import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import USER_CURRENCY from "@salesforce/i18n/currency";
import getKpiData from "@salesforce/apex/KpiDashboardController.getKpiData";
import titleLabel from "@salesforce/label/c.KpiDashboard_Title";
import loadingLabel from "@salesforce/label/c.KpiDashboard_Loading";
import openCasesLabel from "@salesforce/label/c.KpiDashboard_OpenCases";
import openPipelineLabel from "@salesforce/label/c.KpiDashboard_OpenPipeline";
import newLeadsLabel from "@salesforce/label/c.KpiDashboard_NewLeads";
import conversionRateLabel from "@salesforce/label/c.KpiDashboard_ConversionRate";
import closedWonLabel from "@salesforce/label/c.KpiDashboard_ClosedWon";
import refreshLabel from "@salesforce/label/c.KpiDashboard_Refresh";
import lastUpdatedLabel from "@salesforce/label/c.KpiDashboard_LastUpdated";
import errorTitleLabel from "@salesforce/label/c.KpiDashboard_ErrorTitle";
import unknownErrorLabel from "@salesforce/label/c.KpiDashboard_UnknownError";

export default class KpiDashboard extends LightningElement {
  labels = {
    title: titleLabel,
    loading: loadingLabel,
    openCases: openCasesLabel,
    openPipeline: openPipelineLabel,
    newLeads: newLeadsLabel,
    conversionRate: conversionRateLabel,
    closedWon: closedWonLabel,
    refresh: refreshLabel,
    lastUpdated: lastUpdatedLabel,
    errorTitle: errorTitleLabel,
    unknownError: unknownErrorLabel
  };

  // ISO code of the running user's currency, used to format the pipeline.
  currencyCode = USER_CURRENCY;
  kpiData;
  errorMessage;
  isRefreshing = false;

  // Full wire result (data + error), kept so refreshApex can re-run the wire.
  wiredKpiResult;

  @wire(getKpiData)
  wiredKpis(result) {
    this.wiredKpiResult = result;
    const { data, error } = result;
    if (data) {
      this.kpiData = data;
      this.errorMessage = undefined;
    } else if (error) {
      this.kpiData = undefined;
      this.showError(error);
    }
  }

  // refreshApex bypasses the client-side cache of the cacheable method and
  // re-queries the server; the wire handler above receives the new value.
  async handleRefresh() {
    this.isRefreshing = true;
    try {
      await refreshApex(this.wiredKpiResult);
    } catch (error) {
      this.showError(error);
    } finally {
      this.isRefreshing = false;
    }
  }

  showError(error) {
    this.errorMessage =
      error?.body?.message ?? error?.message ?? this.labels.unknownError;
    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.errorTitle,
        message: this.errorMessage,
        variant: "error"
      })
    );
  }

  get isInitialLoad() {
    return !this.kpiData && !this.errorMessage;
  }

  get showSpinner() {
    return this.isInitialLoad || this.isRefreshing;
  }

  get hasData() {
    return !!this.kpiData && !this.errorMessage;
  }

  get hasError() {
    return !!this.errorMessage;
  }

  // Server time at which the displayed values were computed (see
  // KpiDashboardController.KpiData.generatedAt). A cached response keeps
  // its original timestamp, which is the truthful "last updated" value.
  get generatedAt() {
    return this.kpiData?.generatedAt;
  }

  // lightning-formatted-number style="percent" expects a ratio (0.063),
  // the server returns a percentage (6.3).
  get conversionRatio() {
    return (this.kpiData?.leadConversionRate ?? 0) / 100;
  }
}
