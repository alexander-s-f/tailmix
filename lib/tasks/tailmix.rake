namespace :tailmix do
  desc "Compile Tailmix definitions to JSON for JS bundler"
  task compile: :environment do
    Tailmix::Manifest.compile!
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance(["tailmix:compile"])
end