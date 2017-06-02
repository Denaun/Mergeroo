#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Tue 30 May 2017 
# Description: Java Mergeroo
#

require 'fileutils'
require 'logger'
require 'set'

class Mergeroo
	LOCAL_DIR = "./"

	def initialize( debug_level )
		@log = Logger.new( STDERR, level: debug_level )
	end

	def cleanup_file( filename )
		header = ""
		body = "" 
		# Removing the import lines from the result 
		File.foreach( filename ) do |line| 
			# Excluding only the local imports 
			if line.include?( "import" ) then 
				if line.include?( " java." ) then 
					header += line 
				end 
			else 
				body += line 
			end 
		end 
		body.gsub!( /^package .*/, "" )
		return header, body 
	end

	def include_file( filename )
		# Checking if the file to be imported is correctly parsed or if it
		# exists
		if File.file?( filename ) then
			header, body = cleanup_file( filename )

			body.gsub!( /public (abstract )?(class|enum|interface)/, '\1\2' )

			return header, body
		else
			@log.fatal "Problem with an import file '#{filename}'"
			exit
		end
	end

	def merge( filename )
		# Reading the main file from input
		if filename.nil? then
			@log.error "Need a file to start parsing."
		elsif !File.file?( filename ) then
			@log.error "Can't find the file '#{filename}'"
		else
			filename = File.expand_path filename
			# Looking for import in the file
			header, body = cleanup_file( filename )

			# Adding the file in the same package as the file submitted
			# Since the file is part of only one package, I take the first item from the
			# array given as result of the scan

			# Creating the base_path of the file, adding a reference to the local
			# folder if no reference is given
			base_path = File.dirname( filename )

			# Creating an array containing the imports to do
			to_import = Array.new
			# Self package
			to_import << File.read( filename ).scan( /package (.*);/ )
			# Imports
			to_import << File.read( filename ).scan( /import ((?!java).*)\.(?:\*|[^.]*);/ ) 
			# Transforming info in file paths
			to_import = to_import.flatten.to_set.map{ |x| x.gsub( ".", "/" ) }

			# Taking the real base path knowing from where I am starting using the
			# package information
			base_path = base_path[ 0...base_path.index( to_import[ 0 ] ) ]

			# Reading all local import files, excluding the java ones
			to_import.each do |package|
				@log.debug "Package required '#{package}'"
				import_package = "#{base_path}#{package}/*.java"


				Dir[ import_package ].each do |package_file|
					# Excluding the file received as input to the list of imports
					if package_file != filename then
						h, b = include_file( package_file )
						header += h
						body += b
						@log.debug "Added '#{File.basename( package_file )}'"
					end
				end
			end

			# Output everything to stdout, let the user redirect to file.
			@log.info "Mergoo'd file (๑˃̵ᴗ˂̵)و"
			return header + body
		end
	end
end

if __FILE__ == $PROGRAM_NAME then
	puts Mergeroo.new(:info).merge( ARGV[ 0 ] )
end
