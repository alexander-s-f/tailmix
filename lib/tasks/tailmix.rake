namespace :tailmix do
  desc "Generate tailmix_definitions.js for production build"
  task build: :environment do
    Tailmix::ComponentStore.instance.write_to_disk!
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance([ "tailmix:build" ])
end
