namespace :migrations do
  desc "Copies the Budget::Phase summary into description"
  task budget_phases_summary_to_description: :environment do
    Budget::Phase::Translation.find_each do |phase|
      if phase.summary.present?
        phase.description << "<br>"
        phase.description << phase.summary
        phase.update!(summary: nil) if phase.save
      end
    end
  end
end
