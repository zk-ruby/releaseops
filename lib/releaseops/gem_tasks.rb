module ReleaseOps
  def self.create_gem_package_tasks(gemspec_name)
    namespace :zk do
      namespace :gems do
        task :build do
          require 'tmpdir'

          raise "You must specify a TAG" unless ENV['TAG']

          prefix = gemspec_name.split('.').first

          ReleaseOps.with_tmpdir(:prefix => prefix) do |tmpdir|
            tag = ENV['TAG']

            sh "git clone . #{tmpdir}"

            orig_dir = Dir.getwd

            cd tmpdir do
              sh "git co #{tag} && git reset --hard && git clean -fdx"

              sh "rvm 1.8.7 do gem build #{gemspec_name}"

              mv FileList['*.gem'], orig_dir
            end
          end
        end

        task :push do
          gems = FileList['*.gem']
          raise "No gemfiles to push!" if gems.empty?

          gems.each do |gem|
            sh "gem push #{gem}"
          end
        end

        task :clean do
          rm_rf FileList['*.gem']
        end

        task :all => [:build, :push, :clean]
      end
    end
  end
end
