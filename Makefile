CLI53_VERSION=0.7.4
CLI53_BIN=cli53-linux-amd64

all: $(CLI53_BIN)

$(CLI53_BIN):
	wget https://github.com/barnybug/cli53/releases/download/$(CLI53_VERSION)/$(CLI53_BIN)
	chmod a+x $@

clean:
	-rm -r $(CLI53_BIN)
