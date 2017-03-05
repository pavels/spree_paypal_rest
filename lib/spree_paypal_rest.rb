require 'byebug' if Rails.env.development?
require 'paypal-sdk-rest'
require 'spree'
require 'spree_core'
require 'spree_auth_devise'

require 'spree_paypal_rest/engine'

module SpreePaypalRest
end
