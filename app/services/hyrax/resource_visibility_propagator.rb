# frozen_string_literal: true

module Hyrax
  ##
  # Propagates visibility from a valkyrie Work to its FileSets
  class ResourceVisibilityPropagator
    ##
    # @!attribute [rw] source
    #   @return [#visibility]
    attr_accessor :source

    ##
    # @!attribute [r] embargo_manager
    #   @return [Hyrax::EmbargoManager]
    # @!attribute [r] persister
    #   @return [#save]
    # @!attribute [r] queries
    #   @returrn [Valkyrie::Persistence::CustomQueryContainer]
    attr_reader :embargo_manager, :persister, :queries

    ##
    # @param source [#visibility] the object to propogate visibility from
    def initialize(source:,
                   embargo_manager: Hyrax::EmbargoManager,
                   persister:       Hyrax.persister,
                   queries:         Hyrax.query_service.custom_queries)
      @persister       = persister
      @queries         = queries
      self.source      = source
      @embargo_manager = embargo_manager.new(resource: source)
    end

    ##
    # @return [void]
    #
    # @raise [RuntimeError] if visibility propogation fails
    def propagate
      queries.find_child_filesets(resource: source).each do |file_set|
        file_set.visibility = source.visibility
        propagate_embargo(target: file_set) if embargo_manager.under_embargo?
        persister.save(resource: file_set)
      end
    end

    private

      def propagate_embargo(target:)
        new_embargo = embargo_manager.clone_embargo
        new_embargo = persister.save(resource: new_embargo)

        target.embargo_id = new_embargo.id
        Hyrax::EmbargoManager.apply_embargo_for(resource: target)
      end
  end
end
