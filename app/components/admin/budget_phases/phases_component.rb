class Admin::BudgetPhases::PhasesComponent < ApplicationComponent
  attr_reader :budget

  def initialize(budget)
    @budget = budget
  end

  private

    def phases
      budget.phases
    end

    def start_date(phase)
      l(phase.starts_at, format: :long) if phase.starts_at.present?
    end

    def end_date(phase)
      l(phase.ends_at, format: :long) if phase.ends_at.present?
    end
end
