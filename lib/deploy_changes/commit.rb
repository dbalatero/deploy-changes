module DeployChanges
  class Commit
    attr_reader :repo

    def initialize(repo)
      @repo = repo
    end

    def write_head!(sha1 = nil)
      system("mkdir -p #{dir}")

      sha1 ||= repo.head.target_id

      File.write(last_deploy_commit_file, sha1)
    end

    def last_commit
      File.read(last_deploy_commit_file).strip
    end

    private

    def dir
      ".deploy_changes"
    end

    def last_deploy_commit_file
      "#{dir}/last-deploy-commit"
    end
  end
end
