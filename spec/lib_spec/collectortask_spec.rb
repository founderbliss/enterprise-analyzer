require_relative '../spec_helper.rb'
RSpec.describe CollectorTask do
  before(:all) do
    @dir = "#{Dir.pwd}/spec/fixtures/testdir"
    @config = {
      'TOP_LVL_DIR' => @dir,
      'ORG_NAME' => 'TESTORG',
      'API_KEY' => 'TESTAPIKEY',
      'BLISS_HOST' => 'https://app.founderbliss.com'
    }
    @c = CollectorTask.new(@config)
  end

  context 'given a configuration' do
    it 'has an org_name' do
      expect(@c.instance_variable_get('@org_name')).to eq('TESTORG')
    end

    it 'has an api key' do
      expect(@c.instance_variable_get('@api_key')).to eq('TESTAPIKEY')
    end

    it 'has a top level directory' do
      expect(@c.instance_variable_get('@top_lvl_dir')).to eq(@dir)
    end

    it 'has a bliss host' do
      expect(@c.instance_variable_get('@host')).to eq('https://app.founderbliss.com')
    end

    it 'has some repos' do
      expect(@c.instance_variable_get('@saved_repos').count).to eq(3)
    end
  end

  context 'given a repo' do
    it 'identifies a new repo' do
      expect(@c.new_repo?('notinthefile')).to eq(true)
    end

    it 'identifies an old repo' do
      expect(@c.new_repo?('bliss-test-repo')).to eq(false)
    end

    it 'identifies a repo that has new commits' do
      expect(@c.needs_running?('bliss-test-repo', 3)).to eq(true)
    end

    it 'identifies a repo that doesn\'t have new commits' do
      expect(@c.needs_running?('bliss-test-repo', 1)).to eq(false)
    end
  end
end