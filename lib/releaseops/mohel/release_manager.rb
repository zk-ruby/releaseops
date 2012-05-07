module ReleaseOps
  module Mohel
    class ReleaseManager
      include FileUtils
      include GitUtils

      attr_accessor :release_tag_prefix

      # testing only
      attr_writer :latest_version, :latest_release_tag  #:nodoc:

      # tags that we use for creating gems are under this tag subdir
      #
      # example: "release/0.3.2" has the tag prefix 'release'
      #   
      DEFAULT_RELEASE_TAG_PREFIX = 'release'.freeze

      VALID_RELEASE_TYPES = [:major, :minor, :patch].freeze

      def initialize(opts={})
        @release_tag_prefix = DEFAULT_RELEASE_TAG_PREFIX

        opts.each { |k,v| __send__("#{k}=", v) }
      end

      # the latest release tag with prefix
      #
      # if +refresh+ is true, parses the output of git again
      #
      # example: 'release/0.3.2'
      #
      def latest_release_tag
        # this Enumerable#sort_by is necessary because git sorts the output in
        # lexicographical order (eg. ['1.2.1', '1.2.11', '1.2.2']), whereas we
        # want it to sort in numerical order ['1.2.1', '1.2.2', ... , '1.2.11']
        #
        # Mohel::Version is Comparable, so we convert to that, let sort_by do the
        # work and take the last one.
        @latest_release_tag ||= git_tag.grep(%r[^#{rx(release_tag_prefix)}/]).sort_by { |t| Version.parse(File.basename(t)) }.last
      end

      # returns a Version object representing the current release version
      def latest_version
        @latest_version ||= Version.parse(latest_release_tag ? File.basename(latest_release_tag) : nil)
      end

      # tags the current working copy as the next release and pushes the tag to origin
      #
      # release_type should be :major, :minor, or :patch depending on how the
      # latest version should be bumped to create the new tag
      #
      # after the operation is complete, the +latest_version+ and
      # +latest_release_tag+ will be updated to reflect the current values
      #
      def tag_release!(release_type)
        raise ArgumentError, "release_type #{release_type.inspect} is not valid" unless VALID_RELEASE_TYPES.include?(release_type)

        new_vers = latest_version.__send__("bump_#{release_type}")
        new_release_tag = File.join(release_tag_prefix, new_vers.to_s)

        git_tag new_release_tag
        git_push :tags => true

        @latest_version, @latest_release_tag = new_vers, new_release_tag
        true
      end

      # refreshes latest_version and latest_release_tag values so that latest values from
      # the git repo are used.
      #
      # Returns self.
      #
      # example:
      #   >> release_manager.latest_release_tag
      #   # => 'release/0.3.0'
      #
      #   >> git_fetch    # now we fetch latest changes and let's say there was a tag 'release/0.4.0' pulled down
      #   # => nil
      #
      #   >> release_manager.latest_release_tag   # we still have the old cached value
      #   # => 'release/0.3.0'
      #
      #   >> release_manager.refresh.latest_release_tag   # so we refresh and now we have the latest
      #   # => 'release/0.4.0'
      #
      def refresh
        @latest_release_tag = @latest_version = nil
        self
      end

      private
        def rx(str)
          Regexp.escape(str)
        end
    end
  end
end

