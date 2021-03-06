#
#
#CC = gcc
#RL_FLAG = -lreadline
#FLAGS = -Wall
#OUTFILE = slash
#
#OFILES = build/aliases.o build/bg.o build/builtin.o  \
#         build/environ.o build/error.o build/eval.o  \
#         build/globbing.o build/help.o build/init.o  \
#         build/input.o build/options.o build/parser.o \
#         build/prompt.o build/redir.o build/slash.o
#
#all: build/ slash
#
#slash:	$(OFILES)
#	$(CC) $(RL_FLAG) $(FLAGS) $(OFILES) -o $(OUTFILE)
#
#build/:
#	mkdir build/
#
#build/%.o: src/%.c
#	$(CC) -c -o $@ $(FLAGS) $<
#
#clean:
#	-rm -rf build/
#
# Working on Ruby version.

vars :RL_FLAG => "-lreadline", :FLAGS => "-Wall", :OUTFILE => "slash",
     :OFILES => Dir['src/*.c'].collect { |f| 
        "build/" + f.split('/').last.rpartition('.').first + '.o' 
     }
# better way than that block?

rule :all, :depends => ["build/", "slash"]

rule :slash, :depends => :OFILES do
    compile :RL_FLAG, :output => :OUTFILE
end

rule "build/" do
    command "mkdir build/"
end

rule "build/%.o", :d => "src/%.c" do
    # needs some work with special macros
    compile :to_obj, "$<", :output => "$@"
end

clean "-rf build/"
