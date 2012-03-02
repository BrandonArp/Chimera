EXECUTABLE = chimera-server
OBJS = main.o
CEXT = -Wall -O2 
THRIFT_INC = /usr/include/thrift
INC = -I/usr/include -I/usr/local/include
GEN_INC = -Igen-cpp -I$(THRIFT_INC)
CXXFLAGS += -std=c++0x
COMPILE = $(CXX) $(CXXFLAGS) $(INC) $(GEN_INC)
LIB_DIR = -L /usr/lib
LIBS = -l stdc++ -l thrift 
THRIFT_DEFS = -D HAVE_NETINET_IN_H -D HAVE_INTTYPES_H

install : chimera-server
 
.PHONY : install clean

run : chimera-server
	sudo ./chimera-server -n

chimera-server: lib-chimera.mark chimera_server.o
	$(CXX) $(LDFLAGS) gen-cpp/*.o *.o $(LIB_DIR) $(LIBS) -o $@
	
clean :
	$(RM) -r gen-cpp
	$(RM) -r gen-rb
	$(RM) *.o chimera-server
	$(RM) *.mark

lib-chimera.mark: generated-sources.mark gen-cpp/chimera_types.o gen-cpp/chimera_constants.o gen-cpp/Chimera.o 
	touch lib-chimera.mark

generated-sources.mark : gen-cpp gen-rb
	touch generated-sources.mark

%.o : %.cpp
	$(COMPILE) $(THRIFT_DEFS) -c -o $@ $< 

gen-cpp gen-rb : chimera.thrift
	rm -rf gen-cpp
	rm -rf gen-rb
	thrift --gen cpp --gen rb chimera.thrift

