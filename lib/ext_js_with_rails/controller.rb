module ExtJsWithRails
  module Controller
    
    def self.included(base) 
      base.extend ClassMethods 
      base.send(:include, InstanceMethods)
    end 
    
    module InstanceMethods
      # takes an AR.errors object and transforms it into an ext-compatible
      # form:
      # { "field" => "error message", ... }
      def format_errors_for_ext(errors)
        if errors.respond_to?(:errors)
          errors = errors.errors
        end
    
        e = {}
        errors.each do |att, msg|
          e[att] = msg
        end
    
        e
      end
  
      # renders json response to ext submit actions
      def ext_status(status, object=nil, use_send_data=false)
        obj = case status
          when :success, true: { :success => true, :object => object.nil? ? nil : (object.respond_to?(:to_ext_hash) ? object.to_ext_hash : object) }
          when :failure, false: { :success => false, :errors => format_errors_for_ext(object.nil? ? [] : object) }
          else raise ArgumentError, "status must be :success or :failure (or true or false)"
        end

        if use_send_data
          send_data(obj.to_json, :disposition => "inline", :type => "text/html")
        else
          render :text => obj.to_json
        end
      end
  
      def ext_collection(collection, use_send_data=false)
        if use_send_data
          send_data({:data => collection.map(&:to_ext_hash)}.to_json, :disposition => "inline", :type => "text/html")
        else
          render :text => {:data => collection.map(&:to_ext_hash)}.to_json
        end
      end
  
      def ext_member(member)
        render :text => member.to_ext_hash.to_json
      end
    end
  
    module ClassMethods
      # calls make_resourceful with good defaults for building an ExtJS JSON store
      # block is yielded to the make_resourceful call
      def make_ext_resourceful(&block)
        make_resourceful(:include => block) do
          actions :index, :show, :create, :update, :delete

          response_for :index do |format|
            format.json  { ext_collection(current_objects) }
          end

          response_for :show do |format|
            format.json  { ext_member(current_object) }
          end

          response_for :create_fails, :update_fails, :destroy_fails do |format|
            format.json  { ext_status(:failure, current_object, true) }
          end

          response_for :create, :update, :destroy do |format|
            format.json  { ext_status(:success, current_object, true) }
          end
        end

      end

    end
  end
end