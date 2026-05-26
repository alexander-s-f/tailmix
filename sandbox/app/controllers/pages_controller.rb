# frozen_string_literal: true

class PagesController < ApplicationController
  def dashboard
    @kpis = [
      Struct.new(:title, :value, :status, :change).new("ERP Deal Value", "$124,500", "completed", "+14.2%"),
      Struct.new(:title, :value, :status, :change).new("Calls in Queue", "18 agents", "ringing", "High"),
      Struct.new(:title, :value, :status, :change).new("Pending Approval", "42 leads", "pending", "Needs Attention"),
      Struct.new(:title, :value, :status, :change).new("Invalid Numbers", "12 leads", "wrong_number", "-4.1%")
    ]

    @system_stats = {
      cpu: "42%",
      memory: "1.2 GB / 2.0 GB",
      status: "active"
    }

    @activities = [
      Struct.new(:user, :action, :time, :status).new("Alexander F.", "installed tailmix-ui gem", "2 mins ago", "active"),
      Struct.new(:user, :action, :time, :status).new("John D.", "updated lead status to Completed", "15 mins ago", "completed"),
      Struct.new(:user, :action, :time, :status).new("System", "booted stdio MCP server", "1 hour ago", "auto"),
      Struct.new(:user, :action, :time, :status).new("Sarah M.", "rejected estimate", "3 hours ago", "rejected")
    ]
  end

  def leads
    # Rich lead CRM/ERP list showcasing diverse status color mapping
    @leads = [
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        101, "Constantine Constantinople", "+1 (555) 111-2233", "konstantin@spark.com", "active", "marketing", Time.now - 5.minutes
      ),
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        102, "Catherine the Great", "+1 (555) 222-3344", "catherine@mail.com", "completed", "residential", Time.now - 1.hour
      ),
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        103, "Dmitry Donskoy", "+1 (555) 333-4455", "dmitry@mail.com", "pending", "inbound", Time.now - 4.hours
      ),
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        104, "Alex N.", "+1 (555) 444-5566", "alex@mail.com", "failed", "outbound", Time.now - 1.day
      ),
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        105, "Mary S.", "+1 (555) 555-6677", "mary@mail.com", "wrong_number", "commercial", Time.now - 3.days
      ),
      Struct.new(:id, :name, :phone, :email, :status, :source, :created_at).new(
        106, "Unknown Lead", "+1 (555) 000-0000", "unknown@mail.com", "unset", "manager", Time.now - 5.days
      )
    ]
  end
end
