module ExtJsWithRails
  module Model
    def self.included(base) 
      base.extend ActMethods 
    end 
    
    module ActMethods
      # calling acts_as_extjs_model adds the to_ext_hash method to the calling class.
      #
      # Options: 
      # *  <tt>:include</tt> - additional methods to include in to_ext_hash.
      # *  <tt>:exclude</tt> - attributes to exclude from the default attributes
      #
      # Examples:
      #   class User < ActiveRecord::Base
      #     acts_as_extjs_model :include => :full_name, :exclude => :salt
      #   end
      # 
      #  class Author < ActiveRecord::Base
      #    has_many :books
      #    acts_as_extjs_model :include => [:books, :age]
      #  end
      def acts_as_extjs_model(options = {})
        options[:include] ||= [] 
        options[:exclude] ||= []
        
        options[:include] = [options[:include]].flatten
        options[:exclude] = [options[:exclude]].flatten
        
        unless included_modules.include? InstanceMethods 
          class_inheritable_accessor :options
          extend ClassMethods 
          include InstanceMethods 
        end
        
        self.options = options
      end
    end
    
    module ClassMethods
    end
    
    module InstanceMethods
      # generate an ext-compatible hash from the model.
      # by default, it just uses the #attributes hash.
      # configure :include and :exclude via acts_as_extjs_model
      def to_ext_hash
        h = self.attributes

        options[:exclude].each { |m| h.delete(m.to_sym); h.delete(m.to_s) }
        options[:include].each do |m|
          x = self.send(m)
          h[m] = x.respond_to?(:to_ext_hash) ? x.to_ext_hash : x
        end

        h
      end
    end
  end
end