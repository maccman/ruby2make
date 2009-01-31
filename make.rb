#!/usr/bin/env ruby

require 'singleton'


# ~~~  Built-in Extensions  ~~~

#   * to_macro converts a Symbol to Make's macro form - $(...)
#   * is_in is the opposite of [].include?

class Symbol
    def to_macro;   "$(#{inspect.rpartition(':').last})"; end
    def is_in(lst); lst.include? self; end
end

class String
    def to_macro;   to_s; end
    def is_in(lst); lst.include? self; end
    # Used to check if a filename has a header (.h) suffix
    def has_suffix(str)
        if self.index(str) and (self.index(str) + str.length == self.length)
            return true
        end
        false
    end
end


# ~~~  Classes  ~~~

class Rule
    attr_reader :name, :comments, :dependencies, :compilations, :shells
    def initialize(name)
        @name = name
        @comments     = []  # list of strings
        @dependencies = []  # list of strings
        @compilations = []  # list of hashes
        @shells       = []  # list of strings
    end
    def comment(arg);       @comments.push arg;        end
    def depend(arg);        @dependencies.push arg;    end
    def shell(arg);         @shells.push arg;          end
    def compile(params={}); @compilations.push params; end
end

class Makefile
    include Singleton
    attr_accessor :comments, :variables, :suffixes, :rules, :current_rule
    def initialize
        @comments     = []
        @variables    = { :CC => "gcc", :FLAGS => "" }
        @suffixes     = []
        @rules        = []
        @current_rule = nil
    end
    def render
        fp = File.new("Makefile", "w")
        @comments.each do |com|
            fp.write "# #{com}\n"
        end
        fp.write "\n"
        @variables.each_pair do |k, v|
            v = v.collect { |i| i.to_macro }.join " " if v.respond_to? :join
            fp.write "#{k} = #{v}\n"
        end
        @suffixes.each do |s|
            fp.write "\n"
            fp.write ".SUFFIXES: #{s[0]} #{s[1]}\n"
        end    
        @rules.each do |r| 
            fp.write "\n"
            r.comments.each { |c| fp.write "# #{c}\n" }
            fp.write "#{r.name}: #{r.dependencies.join ' '}\n"
            r.compilations.each do |d|
                fp.write "\t#{d[:c]} $(FLAGS) #{d[:flags]}"
                fp.write " #{d[:i]} #{d[:o]}\n"
            end
            r.shells.each do |cmd|
                fp.write "\t#{cmd}\n"
            end
        end
        fp.write "\n# Generated by Ruby2Make\n"
        fp.close
    end
end
# Shortcut functions
def mf;  Makefile.instance;              end
def mfr; Makefile.instance.current_rule; end


# ~~~  DSL Functions  ~~~

def vars var_dict
    var_dict.each_pair { |k, v| mf.variables[k] = v }
end

def rule(name, params={}, &block)
    r = Rule.new name
    Makefile.instance.rules.push r
    Makefile.instance.current_rule = r
    # Combine dependency hashes so different keys can be used
    deps = [params[:depend], params[:depends], params[:d]].flatten
    deps.each { |dep| depend dep }
    # Give control to the user's block
    yield if block_given?
    Makefile.instance.current_rule = nil
end

def comment(*args)
    args.each do |c|
        if   mfr.nil? then mf.comments.push c
        else mfr.comment c
        end
    end
end

# Add a dependency (or list of them) to the rule
def depend(*args)
    args.each { |arg| mfr.depend(arg.to_macro) unless arg.nil? }
end

# Compilation method, uses val of :CC and :FLAGS
def compile(*args)
    # List of user-added flags
    params = { :flags => [], :o => "", :c => "$(CC)" }
    args.each do |arg|
        if arg.class == Hash then arg.each_pair do |k, v|
               if k.is_in [:input,    :i, "input"   ] then params[:i] = v.to_macro
            elsif k.is_in [:output,   :o, "output"  ] then params[:o] = v.to_macro
            elsif k.is_in [:compiler, :c, "compiler"] then params[:c] = v.to_macro
            end
        end
        else
            case arg
            when :to_obj, :obj, "-c" then params[:flags].push "-c"
            when :to_asm, :asm, "-S" then params[:flags].push "-S"
            when :debug, "-g";       then params[:flags].push "-g"
            when :out, :o, :$@, "$@" then params[:o] = "$@"
            else                      params[:flags].push arg.to_macro
            end
        end
    end
    if params[:i].nil?
        # Add the rule's dependencies as inputs
        params[:i] = mfr.dependencies.find_all { |d| not d.has_suffix(".h") }
    else
        # Turn an individual string into a list
        params[:i] = [params[:i]].flatten.join " "
    end
    params[:o] = "-o #{params[:o]}" unless params[:o] == ""
    params[:flags] = params[:flags].join " "
    mfr.compile params
end

# Add shell commands
def shell(*args)
    buf = ""
    args.each do |arg|
        case arg
        when :silent   then buf = "@" + buf
        when :suppress then buf = "-" + buf
        else                buf += arg
        end
    end
    mfr.shell buf
end
# Shortcut for 'echo' command
def echo *message
    msg = message.collect { |m| m.to_macro }.join " "
    shell "@echo '#{msg}'"
end

# Shortcut to create a 'clean: ' rule => clean "*o ~" or clean "*o", "~"
def clean(*cmds)
    rule "clean" do
        cmds.each { |c| shell "-rm -rf #{c.to_macro}" }
    end
end

# Add a suffix rule (.SUFFIXES)
def suffix ext1, ext2, cmd
    mf.suffixes.push [ext1, ext2]
    rule "#{ext2}#{ext1}" do
        shell cmd
    end
end


# ~~~  Run  ~~~

if ARGV.length == 0
    if mfile = Dir['*'].grep(/makefile.rb/i)[0]
        load mfile
    else
        puts '** no Makefile.rb found'
    end    
else
    ARGV.each do |arg|
        case arg
        when "-v", "-version", "--version" then puts "ruby2make version 0.1.1"
        when "-h", "-help", "--help" then puts "rbmake [ -v | -h | filename ]"
        when /.*/ then load arg
        end    
    end
end

mf.render
