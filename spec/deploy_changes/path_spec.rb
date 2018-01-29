require 'fileutils'
require 'rugged'

RSpec.describe DeployChanges::Path do
  describe '#changed?' do
    let(:repo_path) do
      File.expand_path(
        File.dirname(__FILE__) + "/../../tmp/test_repo"
      )
    end

    let(:repo) do
      Rugged::Repository.new(repo_path).tap do |r|
        r.checkout 'refs/heads/master'
      end
    end

    around(:each) do |example|
      system("rm -rf #{repo_path}")

      begin
        system <<~SH
          (mkdir #{repo_path} && \
            cd #{repo_path} && \
            git init . && \
            (echo first > README.md) && \
            git add README.md && \
            git commit -m "Add readme") 2>&1 >/dev/null
        SH

        example.run
      ensure
        system("rm -rf #{repo_path}")
      end
    end

    it "should return true if the file has changed between SHA1s" do
      file = "README.md"

      append_to!(file)
      commit1 = commit_file!(file, "Message 1")

      append_to!(file, text: "more text")
      commit2 = commit_file!(file, "Message 2")

      append_to!(file, text: "more text 2")
      commit3 = commit_file!(file, "Message 3")

      path = described_class.new(repo, commit1)
      expect(path.changed?("README.md")).to eq(true)
    end

    it "should return false if the file hasn't changed" do
      append_to!("one.txt", text: "ok")
      commit1 = commit_file!("one.txt", "one")

      append_to!("two.txt", text: "yes")
      commit2 = commit_file!("two.txt", "two")

      path = described_class.new(repo, commit1)

      expect(path.changed?("README.md")).to eq(false)
      expect(path.changed?("one.txt")).to eq(false)
      expect(path.changed?("two.txt")).to eq(true)
    end

    it "should work with subdirectories" do
      system("mkdir -p #{repo_path}/mydir")

      file = "mydir/README.md"

      append_to!(file)
      commit1 = commit_file!(file, "Message 1")

      append_to!(file, text: "more text")
      commit2 = commit_file!(file, "Message 2")

      append_to!(file, text: "more text 2")
      commit3 = commit_file!(file, "Message 3")

      path = described_class.new(repo, commit1)
      expect(path.changed?("mydir")).to eq(true)
    end

    def append_to!(file, text: "test test test")
      File.open("#{repo_path}/#{file}", "a") do |fp|
        fp.write(text)
      end
    end

    def commit_file!(file, msg)
      index = repo.index
      index.add(file)

      options = {
        tree: index.write_tree(repo),
        author: { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now },
        committer: { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now },
        message: msg,
        parents: repo.empty? ? [] : [ repo.head.target ].compact,
        update_ref: 'HEAD'
      }

      Rugged::Commit.create(repo, options)
    end
  end
end
