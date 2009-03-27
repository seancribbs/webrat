require "webrat/core/elements/field"
require "webrat/core_extensions/blank"

require "webrat/core/elements/element"
require "webrat/core/locators/field_named_locator"

module Webrat
  class Form < Element #:nodoc:
    attr_reader :element
    
    def self.xpath_search
      ".//form"
    end

    def fields
      @fields ||= Field.load_all(@session, @element)
    end
    
    def submit
      @session.request_page(form_action, form_method, params)
    end
    
    def field_named(name, *field_types)
      Webrat::Locators::FieldNamedLocator.new(@session, dom, name, *field_types).locate
    end
    
  protected
  
    def dom
      Webrat::XML.xpath_at(@session.dom, path)
    end
    
    def fields_by_type(field_types)
      if field_types.any?
        fields.select { |f| field_types.include?(f.class) }
      else
        fields
      end
    end
    
    def params
      all_params = {}
      
      fields.each do |field|
        next if field.to_param.nil?
        merge_hash_values(all_params, field.to_param)
      end
      
      all_params
    end
    
    def form_method
      Webrat::XML.attribute(@element, "method").blank? ? :get : Webrat::XML.attribute(@element, "method").downcase
    end
    
    def form_action
      Webrat::XML.attribute(@element, "action").blank? ? @session.current_url : Webrat::XML.attribute(@element, "action")
    end
    
    def merge_array_values(a, b)
      value = b.shift
      target = a.last
      if target.is_a?(Hash) && target.keys.all? { |key| !value.key?(key) }
        merge_hash_values(target, value)
      else
        a << value
      end
    end
  
    def merge_hash_values(a, b) # :nodoc:
      a.keys.each do |k|
        if b.has_key?(k)
          case [a[k], b[k]].map{|value| value.class}
          when *hash_classes.zip(hash_classes)
            a[k] = merge_hash_values(a[k], b[k])
            b.delete(k)
          when [Array, Array]
            merge_array_values(a[k], b[k])
            b.delete(k)
          end
        end
      end
      a.merge!(b)
    end
    
    def hash_classes
      klasses = [Hash]
      
      case Webrat.configuration.mode
      when :rails
        klasses << HashWithIndifferentAccess
      when :merb
        klasses << Mash
      end
      
      klasses
    end
    
  end
end
