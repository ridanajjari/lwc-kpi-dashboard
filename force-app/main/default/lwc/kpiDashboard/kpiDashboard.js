import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getKpiData from "@salesforce/apex/KpiDashboardController.getKpiData";

export default class KpiDashboard extends LightningElement {
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
      error?.body?.message ??
      error?.message ??
      "Unknown error loading KPI data.";
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error loading KPIs",
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

  get pipelineFormatted() {
    if (!this.kpiData) return "$0";
    const value = this.kpiData.pipelineValue ?? 0;
    if (value >= 1_000_000) return "$" + (value / 1_000_000).toFixed(1) + "M";
    if (value >= 1_000) return "$" + (value / 1_000).toFixed(0) + "K";
    return "$" + value;
  }
}
