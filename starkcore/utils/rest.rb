# frozen_string_literal: true

require_relative('request')
require_relative('api')

module StarkCore
  module Utils
    module Rest
      def self.get_page(resource_name:, resource_maker:, user: nil, **query)
        json = StarkCore::Utils::Request.fetch(
          method: 'GET',
          path: StarkCore::Utils::API.endpoint(resource_name),
          query: query,
          user: user
        ).json
        entities = []
        json[StarkCore::Utils::API.last_name_plural(resource_name)].each do |entity_json|
          entities << StarkCore::Utils::API.from_api_json(resource_maker, entity_json)
        end
        return entities, json['cursor']
      end

      def self.get_stream(resource_name:, resource_maker:, user: nil, **query)
        limit = query[:limit]
        query[:limit] = limit.nil? ? limit : [limit, 100].min

        Enumerator.new do |enum|
          loop do
            json = StarkCore::Utils::Request.fetch(
              method: 'GET',
              path: StarkCore::Utils::API.endpoint(resource_name),
              query: query,
              user: user
            ).json
            entities = json[StarkCore::Utils::API.last_name_plural(resource_name)]

            entities.each do |entity|
              enum << StarkCore::Utils::API.from_api_json(resource_maker, entity)
            end

            unless limit.nil?
              limit -= 100
              query[:limit] = [limit, 100].min
            end

            cursor = json['cursor']
            query['cursor'] = cursor
            break if cursor.nil? || cursor.empty? || (!limit.nil? && limit <= 0)
          end
        end
      end

      def self.get_id(resource_name:, resource_maker:, id:, user: nil)
        json = StarkCore::Utils::Request.fetch(
          method: 'GET',
          path: "#{StarkCore::Utils::API.endpoint(resource_name)}/#{id}",
          user: user
        ).json
        entity = json[StarkCore::Utils::API.last_name(resource_name)]
        StarkCore::Utils::API.from_api_json(resource_maker, entity)
      end

      def self.get_content(resource_name:, resource_maker:, sub_resource_name:, id:, user: nil, **query)
        StarkCore::Utils::Request.fetch(
          method: 'GET',
          path: "#{StarkCore::Utils::API.endpoint(resource_name)}/#{id}/#{sub_resource_name}",
          query: StarkCore::Utils::API.cast_json_to_api_format(query),
          user: user
        ).content
      end

      def self.post(resource_name:, resource_maker:, entities:, user: nil)
        jsons = []
        entities.each do |entity|
          jsons << StarkCore::Utils::API.api_json(entity)
        end
        payload = { StarkCore::Utils::API.last_name_plural(resource_name) => jsons }
        json = StarkCore::Utils::Request.fetch(
          method: 'POST',
          path: StarkCore::Utils::API.endpoint(resource_name),
          payload: payload,
          user: user
        ).json
        returned_jsons = json[StarkCore::Utils::API.last_name_plural(resource_name)]
        entities = []
        returned_jsons.each do |returned_json|
          entities << StarkCore::Utils::API.from_api_json(resource_maker, returned_json)
        end
        entities
      end

      def self.post_single(resource_name:, resource_maker:, entity:, user: nil)
        json = StarkCore::Utils::Request.fetch(
          method: 'POST',
          path: StarkCore::Utils::API.endpoint(resource_name),
          payload: StarkCore::Utils::API.api_json(entity),
          user: user
        ).json
        entity_json = json[StarkCore::Utils::API.last_name(resource_name)]
        StarkCore::Utils::API.from_api_json(resource_maker, entity_json)
      end

      def self.delete_id(resource_name:, resource_maker:, id:, user: nil)
        json = StarkCore::Utils::Request.fetch(
          method: 'DELETE',
          path: "#{StarkCore::Utils::API.endpoint(resource_name)}/#{id}",
          user: user
        ).json
        entity = json[StarkCore::Utils::API.last_name(resource_name)]
        StarkCore::Utils::API.from_api_json(resource_maker, entity)
      end

      def self.patch_id(resource_name:, resource_maker:, id:, user: nil, **payload)
        json = StarkCore::Utils::Request.fetch(
          method: 'PATCH',
          path: "#{StarkCore::Utils::API.endpoint(resource_name)}/#{id}",
          user: user,
          payload: StarkCore::Utils::API.cast_json_to_api_format(payload)
        ).json
        entity = json[StarkCore::Utils::API.last_name(resource_name)]
        StarkCore::Utils::API.from_api_json(resource_maker, entity)
      end

      def self.get_sub_resource(resource_name:, sub_resource_maker:, sub_resource_name:, id:, user: nil, **query)
        json = StarkCore::Utils::Request.fetch(
          method: 'GET',
          path: "#{StarkCore::Utils::API.endpoint(resource_name)}/#{id}/#{StarkCore::Utils::API.endpoint(sub_resource_name)}",
          user: user,
          query: StarkCore::Utils::API.cast_json_to_api_format(query)
        ).json
        entity = json[StarkCore::Utils::API.last_name(sub_resource_name)]
        StarkCore::Utils::API.from_api_json(sub_resource_maker, entity)
      end
    end
  end
end
