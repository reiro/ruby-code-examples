module Analytics
  class Fetcher
    REDUCE_CLICKS_BY = 0.65

    def initialize(records, date_range = nil, source = nil)
      @records = records
      @ids = records.ids
      @klass = records.table_name
      if date_range
        @date_from = date_range[:date_from].presence
        @date_to = date_range[:date_to].presence
      end
      @source = source
    end

    def fetch
      if @ids.present?
        response = Analytics::Client.new.get("/#{@klass}", query)
        return [] unless response.success?
        data = reduce_clicks(response.body[:data])
        @records.to_a.each do |record|
          record.analytics = get_record_analytics(record, data)
        end
      else
        []
      end
    end

    def simple_fetch(path)
      response = Analytics::Client.new.get(path, query)
      response.success? ? reduce_clicks(response.body[:data]) : []
    end

    private

    def reduce_clicks(data)
      data.each do |data|
        data[:clicks] = (data[:clicks] * REDUCE_CLICKS_BY).to_i
      end
    end

    def query
      { ids: @ids }.tap do |hash|
        hash[:date_from] = @date_from if @date_from
        hash[:date_to] = @date_to if @date_to
        hash[:source] = @source
      end
    end

    def get_record_analytics(record, parsed_hash)
      parsed_hash.to_a.each_with_object({}) do |item, record_analytics|
        if item[:id] == record.id
          record_analytics.merge!(item)
        end
      end
    end
  end
end
