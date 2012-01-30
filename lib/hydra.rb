require "blacklight"
# Hydra libraries
module Hydra
  extend Blacklight::Configurable
  extend ActiveSupport::Autoload
  autoload :AccessControlsEvaluation
  autoload :AccessControlsEnforcement
  autoload :Assets
  autoload :Catalog
  autoload :Configurable, 'blacklight/configurable'
  autoload :Controller
  autoload :FileAssets
  autoload :GenericContent
  autoload :GenericImage
  autoload :GenericUserAttributes
  autoload :ModelMixins
  autoload :ModsGenericContent
  autoload :ModsImage
  autoload :SubmissionWorkflow
  autoload :SuperuserAttributes
  autoload :User
  autoload :UI
  autoload :Workflow
end


require 'mediashelf/active_fedora_helper'

require 'hydra/repository_controller'
require 'hydra/assets_controller_helper'
require 'hydra/file_assets_helper'

require 'hydra/rights_metadata'
require 'hydra/common_mods_index_methods'
require 'hydra/mods_article'
require 'hydra/model_methods'
require 'hydra/models/file_asset'


