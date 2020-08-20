class SettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    respond_to do |format|
      if current_user.update(settings_params)
        format.html { render :edit, notice: 'Settings updated.' }
        format.json { head :no_content, status: :ok, location: @story }
      else
        format.html { render :edit, notice: 'Update unsuccessful.' }
        format.json { head :no_content, status: :unprocessable_entity }
      end
    end
  end

  private

  def settings_params
    params.require("user").permit(:time_zone, :date_format_yesterday, :date_format_today, :date_format_this_year, :date_format_other_year)
  end

end
