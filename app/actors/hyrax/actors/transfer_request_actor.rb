# frozen_string_literal: true
module Hyrax
  module Actors
    ##
    # @deprecated transfer requests are now carried out in response to published
    # 'object.deposited' events.
    #
    # Notify the provided owner that their proxy wants to make a
    # deposit on their behalf
    class TransferRequestActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        Deprecation.warn('Use Hyrax::Listeners::ProxyDepositListener instead.')
        next_actor.create(env) && create_proxy_deposit_request(env)
      end

      private

      def create_proxy_deposit_request(env)
        proxy = env.curation_concern.on_behalf_of
        return true if proxy.blank?
        ContentDepositorChangeEventJob.perform_later(env.curation_concern,
                                                     ::User.find_by_user_key(proxy))
        true
      end
    end
  end
end
