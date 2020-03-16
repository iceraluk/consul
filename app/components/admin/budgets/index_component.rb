class Admin::Budgets::IndexComponent < ApplicationComponent
  attr_reader :budgets

  def initialize(budgets)
    @budgets = budgets
  end

  private

    def phase_progress_text(budget)
      t("admin.budgets.index.table_phase_progress",
        current_phase_number: current_enabled_phase_number(budget),
        total_phases: budget.phases.enabled.count)
    end

    def current_enabled_phase_number(budget)
      budget.phases.enabled.order(:id).pluck(:kind).index(budget.phase) + 1
    end

    def start_date(budget)
      l(budget.phases.first.starts_at, format: :long) if budget.phases.first.starts_at.present?
    end

    def end_date(budget)
      l(budget.phases.last.ends_at, format: :long) if budget.phases.last.ends_at.present?
    end
end
