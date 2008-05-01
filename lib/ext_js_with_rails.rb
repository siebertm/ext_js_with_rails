module ExtJsWithRails
  class Config
    @@defaults = {
      :main_file => "main.js",
      :src_dir => "src"
    }
    
    def self.config
      @@config ||= YAML.load_file("#{RAILS_ROOT}/config/ext_js_with_rails.yml").symbolize_keys
    end
    
    def self.[](k)
      Config.config[k.to_sym] || @@defaults[k.to_sym] || ""
    end
    
    def self.main_file
      Config[:main_file]
    end

    def self.app_name
      Config[:app_name]
    end

    def self.app_file_name
      "#{Config.app_name}.js"
    end

    def self.app_min_file_name
      "#{Config.app_name}-min.js"
    end

    def self.app_root
      File.expand_path(File.join(RAILS_ROOT, Config[:root_dir]))
    end

    def self.app_src_dir
      File.join(Config.app_root, Config[:src_dir])
    end

    def self.app_dist_dir
      Config.app_root
    end
  end
end