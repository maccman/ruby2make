require 'singleton'

# Classes

class Rule
    attr_reader :name, :dependencies, :compilations, :commands
    def initialize(name)
        @name = name
        @dependencies = []
        @compilations = []
        @commands = []
    end
    def depend(arg)
        @dependencies << arg
    end
    def compile(params={})
        # Why are there nils in @dependencies?
        deps = @dependencies.find_all { |d| d.split('.').last != 'h' unless d.nil? }
        params[:input] = deps if params[:input].nil?
        # Make it a list again and then flatten it in case it was just one string,
        # instead of a list
        params[:input] = [params[:input]].flatten.join " "
        if params[:output].nil?
            params[:output] = ""
        else
            params[:output] = "-o #{params[:output]}"
        end
        params[:flags] = params[:flags].join " "
        @compilations << params
    end
    def command(arg)
        @commands << arg
    end
end

class Makefile
    include Singleton
    attr_accessor :variables, :rules, :current_rule
    def initialize
        @variables = { :CC => "gcc", :FLAGS => "" }
        @rules = []
        @current_rule = nil
    end
    def render
        fp = File.new("Makefile", "w")
        fp.write "# Generated by Ruby2Make\n\n"
        @variables.each_pair { |k, v| fp.write "#{k} = #{v}\n" }
        @rules.each do |r| 
            fp.write "\n"
            fp.write "#{r.name}: #{r.dependencies.join ' '}\n"
            r.compilations.each do |d|
                fp.write "\t$(CC) $(FLAGS) #{d[:flags]} #{d[:input]} #{d[:output]}\n"
            end
            r.commands.each do |cmd|
                fp.write "\t#{cmd}\n"
            end
        end
        fp.close
    end
end

# DSL Methods

def vars var_dict
    var_dict.each_pair { |k, v| Makefile.instance.variables[k] = v }
end

def rule(name, params={}, &block)
    r = Rule.new name
    Makefile.instance.rules << r
    Makefile.instance.current_rule = r
    # Combine dependency hashes so either key can be used
    deps = [params[:depend], params[:depends]].flatten
    deps.each { |dep| depend dep }
    # Cede control to the user's block
    yield if block_given?
    Makefile.instance.current_rule = nil
end

def depend(*args)
    args.each do |arg|
        if arg.class == Symbol
            arg = "$(#{arg})"
        end    
        Makefile.instance.current_rule.depend arg
    end
end

# compilation method, will use val of :CC
def compile(*args)
    params = { :flags => [] }
    args.each do |arg|
        if arg.class == Hash
            arg.each_pair do |k, v| 
                if v.class == Symbol
                    v = "$(#{v})"
                end
                params[k] = v
            end
        elsif [String, Symbol].include? arg.class
            case arg
            when :to_obj, "-c"
                params[:flags] << "-c"
            when
                if arg.class == Symbol
                    params[:flags] << "$(#{arg})"
                end    
            end
        end
    end
    Makefile.instance.current_rule.compile params
end

# shell command
def command(*args)
    args.each { |arg| Makefile.instance.current_rule.command arg }
end

def echo message
    command "@echo '#{message}'"
end

# Shortcut to create a 'clean: ' rule => clean "*o ~" or clean "*o", "~"
def clean(*cmds)
    if cmds.respond_to? :join
        tmp_cmds = cmds.collect do |c|
            if c.class == Symbol
                "$(#{c})"
            else
                c
            end
        end    
        cmds = tmp_cmds.join " "
    end
    rule "clean" do
        command "-rm #{cmds}"
    end
end

# Load and test a file
if ARGV.length == 0
    load 'file1.rb'
else
    load ARGV[0]
end
Makefile.instance.render
