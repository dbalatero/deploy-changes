require 'rugged'

module DeployChanges
  class Path
    attr_reader :repo, :last_sha1

    def initialize(repo, last_sha1)
      @repo = repo
      @last_sha1 = last_sha1
    end

    def changed?(path)
      return true if last_sha1.nil?

      diff = repo.index.diff(last_commit)

      diff.each_delta do |delta|
        files = [delta.old_file[:path], delta.new_file[:path]]
        return true if files.any? { |diff_path| diff_path =~ /^#{path}/ }
      end

      false
    end

    private

    def last_commit
      repo.lookup(last_sha1)
    end
  end
end
