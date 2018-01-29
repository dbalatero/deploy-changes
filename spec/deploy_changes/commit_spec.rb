RSpec.describe DeployChanges::Commit do
  let(:repo) { double }

  describe '#last_commit' do
    it "should not blow up if there is not a last commit set" do
      commit = DeployChanges::Commit.new(repo)

      expect(commit.last_commit).to be_nil
    end
  end
end
