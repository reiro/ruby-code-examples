class StorageMule
  class << self
    PROVIDER = 'AWS'.freeze

    def get_directory
      connection.directories.get(app_secrets[:directory])
    end

    def get_video_directory
      connection.directories.get(app_secrets[:video_directory])
    end

    def invalidator
      CloudfrontInvalidator.new app_secrets[:access_key_id], app_secrets[:secret_access_key], app_secrets[:cf_distribution_id]
    end

    private

    def app_secrets
      Rails.application.secrets.aws.with_indifferent_access
    end

    def connection
      @connection ||= Fog::Storage.new(
        provider: PROVIDER,
        aws_access_key_id: app_secrets[:access_key_id],
        aws_secret_access_key: app_secrets[:secret_access_key],
        region: app_secrets[:region]
      )
    end
  end
end
