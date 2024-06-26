require 'yaml'
require 'csv'
require_relative '_PLUGIN_SYSTEM/rmxp/rgss'

# Very basic, not parsing objects, just need something workable

input_dir = File.join(Dir.pwd, "Export", "Data", "")
load_objects = ["Items","Enemies","States","Skills","Weapons","Armors","Animations"]

load_objects.each do |data_name|

  filename = data_name + ".yml"

  yamlfile = File.open( input_dir + filename, "r")
  data = YAML::load( yamlfile )
  printed_header = false

  csv_out = CSV.generate do |csv|
    data['root'].each do |obj|
      next if obj.nil?
      obj_ary = []
      vars = obj.instance_variables
      # Header row
      unless printed_header
        csv << vars
        printed_header = true
      end
      vars.each do |vname|
        ival = obj.instance_variable_get(vname)
        if ival.nil?
          obj_ary << ""
          next
        end
        if [Numeric, String, Enumerable, Symbol, TrueClass, FalseClass].any?{|o| ival.is_a?(o) }
          obj_ary << ival
        elsif ival.is_a?(RPG::AudioFile)
          obj_ary << [ival.volume, ival.name, ival.pitch]
        elsif ival.is_a?(Color)
          obj_ary << [ival.red, ival.green, ival.blue, ival.alpha]
        elsif ival.is_a?(Tone)
          obj_ary << [ival.red, ival.green, ival.blue, ival.grey]
        else
          obj_ary << ival.to_s
        end
      end
      csv << obj_ary
    end
  end

  csvfile = Dir.pwd + "/" + File.basename(filename, ".yml") + ".csv"

  File.write(csvfile, csv_out)

end