import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getKpiData from "@salesforce/apex/KpiDashboardController.getKpiData";

export default class KpiDashboard extends LightningElement {
  @track kpiData = null;
  @track isLoading = true;
  @track errorMessage = "";
  @track lastUpdated = "";

  connectedCallback() {
    this.fetchKpis();
  }

  fetchKpis() {
    this.isLoading = true;
    this.errorMessage = "";

    getKpiData()
      .then((data) => {
        this.kpiData = data;
        this.lastUpdated = new Date().toLocaleTimeString();
      })
      .catch((error) => {
        this.errorMessage =
          error?.body?.message ?? "Unknown error loading KPI data.";
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error loading KPIs",
            message: this.errorMessage,
            variant: "error"
          })
        );
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleRefresh() {
    this.fetchKpis();
  }

  get hasData() {
    return !this.isLoading && !this.errorMessage && this.kpiData !== null;
  }

  get hasError() {
    return !this.isLoading && !!this.errorMessage;
  }

  get pipelineFormatted() {
    if (!this.kpiData) return "$0";
    const value = this.kpiData.pipelineValue ?? 0;
    if (value >= 1_000_000) return "$" + (value / 1_000_000).toFixed(1) + "M";
    if (value >= 1_000) return "$" + (value / 1_000).toFixed(0) + "K";
    return "$" + value;
  }
}
