module CassandraObject
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      def remove(key)
        ActiveSupport::Notifications.instrument("remove.cassandra_object", column_family: column_family, key: key) do
          dynamo_table.items[key.to_s].delete
        end
      end

      def delete_all
        ActiveSupport::Notifications.instrument("truncate.cassandra_object", column_family: column_family) do
          dynamo_table.items.select do |data|
            data.item.delete
          end
        end
      end

      def create(attributes = {})
        new(attributes).tap do |object|
          object.save
        end
      end

      def instantiate(key, attributes)
        allocate.tap do |object|
          object.instance_variable_set("@key", parse_key(key)) if key
          object.instance_variable_set("@new_record", false)
          object.instance_variable_set("@destroyed", false)
          object.instance_variable_set("@attributes", typecast_attributes(object, attributes))
        end
      end

      def typecast_attributes(object, attributes)
        attributes = attributes.symbolize_keys
        Hash[attribute_definitions.map { |k, attribute_definition| [k.to_s, attribute_definition.instantiate(object, attributes[k])] }]
      end
    end

    def new_record?
      @new_record
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    def save(*)
      begin
        create_or_update
      rescue CassandraObject::RecordInvalid
        false
      end
    end

    def save!
      create_or_update || raise(RecordNotSaved)
    end

    def destroy
      self.class.remove(key)
      @destroyed = true
      freeze
    end

    def update_attribute(name, value)
      name = name.to_s
      send("#{name}=", value)
      save(:validate => false)
    end

    def update_attributes(attributes)
      self.attributes = attributes
      save
    end

    def update_attributes!(attributes)
      self.attributes = attributes
      save!
    end

    def reload
      @attributes.update(self.class.find(self.id).instance_variable_get('@attributes'))
    end

    private
      def create_or_update
        result = new_record? ? create : update
        result != false
      end

      def create
        write
        @new_record = false
        key
      end
    
      def update
        dynamo_db_item = self.class.dynamo_table.items[id]
        
        dynamo_db_item.attributes.update do |u|
          changed.each do |attr|
            value = read_attribute(attr)
            encoded = self.class.coder_for(attr).encode(value)

            if encoded.blank?
              u.delete(attr)
            else
              u.set(attr => encoded)
            end
          end
        end
      end

      def write
        encoded_attributes = {self.class.primary_key => id}
        attributes.except!(self.class.primary_key).each do |k, v|
          next if v.nil?

          if (value = self.class.coder_for(k).encode(v)).present?
            encoded_attributes[k] = value
          end
        end
        self.class.dynamo_table.items.create(encoded_attributes)
      end
  end
end
