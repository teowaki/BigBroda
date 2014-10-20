module GoogleBigquery
  class Auth

    attr_accessor :api, :client
    cattr_accessor :api, :client

    def initialize
      @config = GoogleBigquery::Config
      @key = Google::APIClient::KeyUtils.load_from_pkcs12(@config.key_file, @config.pass_phrase)
      @asserter = Google::APIClient::JWTAsserter.new( @config.email, @config.scope, @key)
    end

    def authorize
      @client = Google::APIClient.new(application_name: "BigBroda", application_version: GoogleBigquery::VERSION )
      @client.retries = @config.retries.to_i if @config.retries.to_i > 1
      client_authorize
      @api = @client.discovered_api('bigquery', 'v2')
      self.class.api = @api
      self.class.client = @client
    end

    def self.authorized?
      client.present?
    end

    private
    def client_authorize
      retries = @client.retries || 1
      begin
        @client.authorization = @asserter.authorize
      rescue Signet::AuthorizationError
        retries -= 1
        retry unless retries == 0
      end
    end

  end
end

