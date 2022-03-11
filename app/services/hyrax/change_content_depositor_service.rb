# frozen_string_literal: true
module Hyrax
  # TODO: call this service from the transaction pipeline, instead of from a
  # background job invoked by a listener
  #
  # currently called from ContentDepositorChangeEventJob, app/jobs/content_depositor_change_event_job
  #   which is called in:
  #     app/models/proxy_deposit_request#transfer!,
  #       which is called in:
  # ***     app/controllers/hyrax/transfers_controller
  #     app/actors/hyrax/actors/transfer_request_actor (basically a wrapper for this) -- old behavior,
  #     app/services/hyrax/listeners/proxy_deposit_listener
  #       which listens for object.deposited, which is published by:
  # ***     lib/hyrax/transactions/steps/save.rb
  #         app/services/hyrax/work_uploads_handler.rb -- doesn't look like this
  #           will actually need the proxy depositor stuff so not worried about
  #           moving it.
  #         the after_create_concern callback, which is invoked by:
  #           base_actor.rb -- old behavior
  class ChangeContentDepositorService
    # Set the given `user` as the depositor of the given `work`; If
    # `reset` is true, first remove all previous permissions.
    #
    # @param work [ActiveFedora::Base, Valkyrie::Resource] the work
    #             that is receiving a change of depositor
    # @param user [User] the user that will "become" the depositor of
    #             the given work
    # @param reset [TrueClass, FalseClass] when true, first clear
    #              permissions for the given work and contained file
    #              sets; regardless of true/false make the given user
    #              the depositor of the given work
    def self.call(work, user, reset)
      case work
      when ActiveFedora::Base
        call_af(work, user, reset)
      when Valkyrie::Resource
        call_valkyrie(work, user, reset)
      end
    end

    def self.call_af(work, user, reset)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      work.file_sets.each do |f|
        f.permissions = [] if reset
        f.apply_depositor_metadata(user)
        f.save!
      end
      work.save!
      work
    end
    private_class_method :call_af

    # @todo Should this include some dependency injection regarding
    # the Hyrax.persister and Hyrax.custom_queries?
    def self.call_valkyrie(work, user, reset)
      if reset
        work.permission_manager.acl.permissions = []
        work.permission_manager.acl.save
      end

      work.proxy_depositor = work.depositor
      apply_depositor_metadata(work, user)

      apply_valkyrie_changes_to_file_sets(work: work, user: user, reset: reset)

      Hyrax.persister.save(resource: work)
      work
    end
    private_class_method :call_valkyrie

    def self.apply_depositor_metadata(resource, depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      resource.depositor = depositor_id if resource.respond_to? :depositor=
      Hyrax::AccessControlList.new(resource: resource).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    end
    private_class_method :apply_depositor_metadata

    def self.apply_valkyrie_changes_to_file_sets(work:, user:, reset:)
      Hyrax.custom_queries.find_child_file_sets(resource: work).each do |f|
        if reset
          f.permission_manager.acl.permissions = []
          f.permission_manager.acl.save
        end
        apply_depositor_metadata(f, user)
        Hyrax.persister.save(resource: f)
      end
    end
    private_class_method :apply_valkyrie_changes_to_file_sets
  end
end
