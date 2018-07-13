require 'rails_jwt_auth/jwt_manager'

module RailsJwtAuth
  class SessionsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(RailsJwtAuth.auth_field_name =>
        session_create_params[RailsJwtAuth.auth_field_name].to_s.downcase).first

      if !user
        render_422 session: [{error: :invalid_session}]
      elsif user.respond_to?('confirmed?') && !user.confirmed?
        render_422 session: [{error: :unconfirmed}]
      elsif user.authenticate(session_create_params[:password])
        render_session get_jwt(user), user
      else
        render_422 session: [{error: :invalid_session}]
      end
    end

    def destroy
      authenticate!
      payload = JwtManager.decode_from_request(request)&.first
      current_user.destroy_auth_token payload['auth_token']
      render_204
    end

    private

    def get_jwt(user)
      JwtManager.encode(user.to_token_payload(request))
    end
  end
end
