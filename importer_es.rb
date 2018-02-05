module AdEngine
  module Elasticsearch
    module Updater
      class ImporterEs
        CORE_COUNT = 2
        DEGREE_OF_PARALLELISM = 32
        BATCH_SIZE = 12_000

        def reset!(suffix = Time.zone.now.to_i)
          indexes = DataFeedIndex.indexes
          DataFeedIndex.create! suffix, alias: false
          new_index = DataFeedIndex.build_index_name(suffix: suffix)
          import(new_index)
          Chewy.client.indices.update_aliases(body: { actions: [
            *indexes.map do |index|
              { remove: { index: index, alias: DataFeedIndex.index_name } }
            end,
            { add: { index: new_index, alias: DataFeedIndex.index_name } }
          ] })
          Chewy.client.indices.delete index: indexes if indexes.present?
        end

        private

        def import(suffix)
          logger = Logger.new(STDOUT)
          ::DataFeedItem.find_in_batches(batch_size: BATCH_SIZE) do |items|
            segments = DEGREE_OF_PARALLELISM * CORE_COUNT
            size = items.count / segments + 1
            start_time = Time.zone.now
            parts = items.each_slice(64).map do |segment|
              chunk = ""
              segment.each do |product|
                data = product.attributes
                chunk << "{ \"index\" :  {\"_index\":\"#{suffix}\",\"_type\":\"data_feed_item\",\"_id\":#{data['id']}} }\n{\"manufacturer\":\"#{data['manufacturer']}\",\"offer_description\":\"#{data['offer_description'].to_s.gsub(/\\'/,"\'").gsub('"', '\\"')}\",\"offer_id\":\"#{data['offer_id']}\",\"offer_title\":\"#{data['offer_title'].gsub('"', '\\"')}\",\"source\":#{data['source']},\"price\":\"#{data['price']}\",\"category\":\"#{data['category']}\",\"sub_category\":\"#{data['sub_category']}\",\"shipping_rate\":\"#{data['shipping_rate']}\",\"merchant\":\"#{data['merchant']}\"}\n"
              end
              chunk
            end

            Chewy.client.bulk(body: parts)
            end_time = Time.zone.now
            logger.fatal "Items processed - #{items.count / (end_time - start_time)}"
          end
        end
      end
    end
  end
end
