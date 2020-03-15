all:
	pkill -9 perl 2>/dev/null || true

	perl Server.pl 9000
	perl Client.pl -h localhost -p 9000

server:
	perl Server.pl 9000

client:
	perl Client.pl -h localhost -p 9000 -v

stop:
	pkill -9 perl 2>/dev/null || true