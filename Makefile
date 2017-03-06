ERLC=erlc
ERLCFLAGS=-o
SRCDIR=./
LOGDIR=/var/log/mysoftware
CONFDIR=/etc/mysoftware
BEAMDIR=./ebin

all:
	@ mkdir -p $(BEAMDIR);
	@ $(ERLC) $(ERLCFLAGS) $(BEAMDIR) $(SRCDIR)/*.erl;

.PHONY: clean

clean:
	rm -f $(BEAMDIR)/* erl_crash.dump

L_ERL=erl -noshell -pa $(BEAMDIR) -setcookie pass
SYSTEM= system

run:
	$(L_ERL) -s $(SYSTEM) start
