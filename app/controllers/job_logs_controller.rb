class JobLogsController < ApplicationController
  # HTTP Basic Authentication (same credentials as OpenOrders)
  http_basic_authenticate_with name: ENV.fetch("ADMIN_USERNAME", "admin"),
                                password: ENV.fetch("ADMIN_PASSWORD", "password")

  def index
    @job_logs = JobLog.order(created_at: :desc).page(params[:page]).per(25)
  end

  def show
    @job_log = JobLog.find(params[:id])
    @job_log_details = @job_log.job_log_details
  rescue ActiveRecord::RecordNotFound
    redirect_to job_logs_path, alert: "Job log not found."
  end
end
