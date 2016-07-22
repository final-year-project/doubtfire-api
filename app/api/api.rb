require 'grape'
require 'grape-swagger'

module Api
  class Root < Grape::API
    helpers AuthorisationHelpers
    helpers LogHelper
    helpers AuthHelpers

    prefix 'api'
    format :json
    formatter :json, Grape::Formatter::ActiveModelSerializers
    # rescue_from :all

    #
    # Mount the api modules
    #
    mount Api::Auth
    mount Api::GroupSets
    mount Api::Projects
    mount Api::Students
    mount Api::Tasks
    mount Api::TaskComments
    mount Api::TaskDefinitions
    mount Api::Tutorials
    mount Api::UnitRoles
    mount Api::Units
    mount Api::Users
    mount Api::LearningOutcomes
    mount Api::LearningAlignment
    mount Api::Submission::Generate
    mount Api::Submission::PortfolioApi
    mount Api::Submission::PortfolioEvidenceApi
    mount Api::Submission::BatchTask
    mount Api::Helpdesk::Ticket
    mount Api::Helpdesk::Session

    #
    # Add auth details to all end points
    #
    AuthHelpers.add_auth_to Api::GroupSets
    AuthHelpers.add_auth_to Api::Units
    AuthHelpers.add_auth_to Api::Projects
    AuthHelpers.add_auth_to Api::Students
    AuthHelpers.add_auth_to Api::Tasks
    AuthHelpers.add_auth_to Api::TaskComments
    AuthHelpers.add_auth_to Api::TaskDefinitions
    AuthHelpers.add_auth_to Api::Tutorials
    AuthHelpers.add_auth_to Api::Users
    AuthHelpers.add_auth_to Api::UnitRoles
    AuthHelpers.add_auth_to Api::LearningOutcomes
    AuthHelpers.add_auth_to Api::LearningAlignment
    AuthHelpers.add_auth_to Api::Submission::PortfolioApi
    AuthHelpers.add_auth_to Api::Submission::PortfolioEvidenceApi
    AuthHelpers.add_auth_to Api::Submission::BatchTask
    AuthHelpers.add_auth_to Api::Helpdesk::Ticket
    AuthHelpers.add_auth_to Api::Helpdesk::Session

    add_swagger_documentation \
      base_path: nil,
      add_version: false,
      hide_documentation_path: true,
      info: {
        title: "Doubtfire API Documentaion",
        description: "Doubtfire is a modern, lightweight learning management system.",
        license: "AGPL v3.0",
        license_url: "https://github.com/doubtfire-lms/doubtfire-api/blob/master/LICENSE"
      }
  end
end
