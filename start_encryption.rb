#encoding: utf-8
require 'zlib'

module CP
	
	EXTENSIONS = {}
	EXTENSIONS['rxdata'] = 'atd'
	EXTENSIONS['gif'] = 'atj'
	EXTENSIONS['png'] = 'atg'
	EXTENSIONS['jpg'] = 'atg'
	
	def self.encrypt_folder(source)
		Dir.foreach(source) {|name|
			if name != '.' && name != '..' && !EXTENSIONS.values.any? {|ext| name.clone.downcase.gsub!(".#{ext}") {}}
				filename = "#{source}/#{name}"
				if FileTest.directory?(filename)
					CP.encrypt_folder(filename)
				elsif FileTest.file?(filename)
					puts "Encrypting #{filename}"
					fragments = name.split('.')
					extension = fragments.pop
					file = fragments.join('.')
					new_filename = "#{source}/#{file}.#{EXTENSIONS[extension.downcase]}"
					File.delete(new_filename) if FileTest.exist?(new_filename)
					CP.encrypt_file(filename, new_filename)
					File.delete(filename)
				end
			end
		}
	end
	
	def self.encrypt_file(filename, new_filename)
		file = File.open(filename, 'rb')
		data = file.read
		file.close
		rawdata = Zlib::Deflate.deflate(data, 9)
		first = nil
		rawdata.each_byte {|byte|
			first = byte
			break
		}
		rawdata[0] = ((first + 128) % 256).chr
		file = File.open(new_filename, 'wb')
		file.write(rawdata)
		file.close
	end
	
end

begin
	['./_EncWorking/Data', './_EncWorking/Graphics'].each {|name| CP.encrypt_folder(name)}
	puts 'Press ENTER to continue.'
	gets
end