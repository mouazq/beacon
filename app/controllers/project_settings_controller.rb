# frozen_string_literal: true

class ProjectSettingsController < ApplicationController
  before_action :authenticate_account!
  before_action :scope_project_and_settings
  before_action :enforce_permissions

  def edit
  end

  def update
    @settings.update_attributes(settings_params)
    if @settings.save
      redirect_to project_path(@project)
    else
      flash[:error] = @settings.errors.full_messages
      render :edit
    end
  end

  def toggle_pause
    @settings.toggle_pause
    redirect_to @project
  end

  private

  def enforce_permissions
    render(status: :forbidden, plain: nil) && return unless @project.account_can_manage?(current_account)
  end

  def scope_project_and_settings
    @project = Project.find_by(slug: params[:project_slug])
    @settings = @project.project_setting
  end

  def settings_params
    params.require(:project_setting).permit(
      :rate_per_day,
      :require_3rd_party_auth,
      :minimum_3rd_party_auth_age_in_days,
      :allow_anonymous_issues,
      :publish_stats,
      :include_in_directory
    )
  end
end
