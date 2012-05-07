module ReleaseOps
  module Mohel
    module GitUtils
      include FileUtils

      DEFAULT_REMOTE = 'origin'.freeze

      # inits and updates submodules in cwd
      def git_update_submodules
        sh "git submodule init; git submodule update"
      end

      def git_make_working_copy_pristine
        sh 'git reset --hard HEAD && git clean -fdx'
      end

      def git_fetch(remote=DEFAULT_REMOTE)
        sh "git fetch '#{remote}' && git fetch --tags '#{remote}'"
      end

      # creates an archive (exports) current repo at +tag_name+ to dest.
      # dest should not already exist.
      #--
      # the implementation of this is dicey, as we use the git archive --prefix option,
      # I'm not sure all the edge cases are covered here, so "heads up" - slyphon
      #
      def git_archive_tag(tag_name, dest)
        treeish = File.join('refs/tags', tag_name)
        mkdir_p dest

        sh "git archive --format=tar '#{treeish}'|#{gnu_tar_path} -C #{dest} -xf-"
      end

      # If tagname is +nil+, returns a list of tags. If tagname is given, 
      # then will call 'git tag -am "#{tagname}" #{tagname}' and return nil
      # if +tag_name+ is given, then +treeish+ is an optional argument for what
      # should be tagged (defaults to HEAD)
      # 
      def git_tag(tag_name=nil, treeish=nil)
        if tag_name
          cmd = ["git tag -am '#{tag_name}' #{tag_name}"]
          cmd << treeish if treeish
          sh(cmd.join(' '))
          nil
        else
          bt_lines('git tag')
        end
      end

      # perform a git push. opts are:
      #
      # * <tt>:tags</tt>: if true, push tags to the remote repo
      # * <tt>:remote</tt>: if non-nil, should be a String containing the name of
      #   a configured remote for this repo. If nil, DEFAULT_REMOTE will be used.
      def git_push(opts={})
        cmd = %w[git push]
        cmd << '--tags' if opts[:tags]
        cmd << opts.fetch(:remote, DEFAULT_REMOTE)

        sh(cmd.join(' '))
      end

      def git_checkout(tag, opts={})
        cmd = %W[git checkout]
        cmd += "-f" if opts[:force]
        cmd += %Q['#{tag}']

        sh(cmd.join(' '))
      end

      # @private
      GNUTAR_PATHS = {
        'Darwin' => '/usr/bin/tar',
        'SunOS' => '/usr/sfw/bin/gtar',
      }

      # Path to the gnu tar binary on the current operating system.
      # Raises GnuTarNotFoundError if we don't know where gnu tar is on this
      # system.
      #
      # @private
      def gnu_tar_path
        @gnu_tar_path ||= GNUTAR_PATHS.fetch(bt('uname -s').strip) { raise GnuTarNotFoundError }
      end
    end

    class GnuTarNotFoundError < MohelError
      def initialize
        super("don't know where GNU tar is on this system")
      end
    end
  end
end

