module Initializer
  include Common
  include Gitbase

  def initialize_bliss_repository(dir_name, org_name, subdirectory = nil)
    name = extract_name_from_git_url(dir_name)
    puts "Working on: #{name}...".blue
    repo_details = save_repository_to_bliss(dir_name, org_name, name, subdirectory)
    puts "\tCreated repo ##{repo_details['id']} - #{repo_details['full_name']}".green
    repo_details
  end

  def save_repository_to_bliss(dir_name, org_name, name, subdirectory)
    git_base = git_url(dir_name)
    git_base = "#{org_name}/#{name}" if git_base.empty?
    dir_to_sense = subdirectory.nil? ? dir_name : File.join(dir_name, subdirectory)
    @logger.info("\tSaving repository details to database...")
    params = { name: name, full_name: "#{org_name}/#{name}",
               git_url: git_base, languages: sense_project_type(dir_to_sense).to_json }
    params[:branch] = configure_branch(dir_name)
    params[:subdirectory] = subdirectory if subdirectory
    repo_return = http_post("#{@host}/api/repo.json", params)
    if repo_return.nil?
      @logger.error('Could not connect to Bliss. Please contact us at hello@bliss.ai for support.')
      exit
    end
    repo_return
  end
end
