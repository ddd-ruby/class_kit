module ClassKit
  class Helper

    def initialize
      @hash_helper = HashKit::Helper.new
      @attribute_helper = ClassKit::AttributeHelper.new
      @value_helper = ClassKit::ValueHelper.new
    end

    def is_class_kit?(klass)
      klass.is_a?(ClassKit)
    end

    def validate_class_kit(klass)
      is_class_kit?(klass) || raise(ClassKit::Exceptions::InvalidClassError,
                                    "Class: #{klass} does not implement ClassKit.")
    end

    #This method is called to convert a ClassKit object into a Hash.
    def to_hash(object)
      validate_class_kit(object.class)

      @hash_helper.to_hash(object)
    end

    #This method is called to convert a Hash into a ClassKit object.
    def from_hash(hash:, klass:)
      validate_class_kit(klass)

      @hash_helper.indifferent!(hash)
      entity = klass.new
      attributes = @attribute_helper.get_attributes(klass)
      attributes.each do |attribute|
        key = attribute[:name]
        type = attribute[:type]

        #if the hash value is nil skip it
        next if hash[key].nil?

        value = if is_class_kit?(type)
                  from_hash(hash: hash[key], klass: type)
                elsif type == Array
                  hash[key].map do |array_element|
                    if attribute[:collection_type].nil?
                      array_element
                    else
                      if is_class_kit?(attribute[:collection_type])
                        from_hash(hash: array_element, klass: attribute[:collection_type])
                      else
                        @value_helper.parse(type: attribute[:collection_type], value: array_element)
                      end
                    end
                  end
                else
                  hash[key]
                end

        entity.public_send(:"#{key}=", value)
      end

      entity
    end

    #This method is called to convert a ClassKit object into JSON.
    def to_json(object)
      hash = @hash_helper.to_hash(object)
      JSON.dump(hash)
    end

    #This method is called to convert JSON into a ClassKit object.
    def from_json(json:, klass:)
      hash = JSON.load(json)
      from_hash(hash: hash, klass: klass)
    end
  end
end
