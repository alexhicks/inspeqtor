NAME=inspeqtor
VERSION=0.0.1
ARCH=amd64

# when fixing packaging bugs but not changing the binary, we increment this number
ITERATION=1

# Include the secret API key which is needed to upload releases to bintray
-include .local.sh

all: clean package

test:
	go test ./...

build: test
	GOOS=linux GOARCH=$(ARCH) go build -o $(NAME) cmd/main.go

clean:
	rm -f main $(NAME)
	rm -rf output
	mkdir output

package: build
	fpm -f -s dir -t deb -n $(NAME) -v $(VERSION) -p output \
		--deb-priority optional --category admin \
		--deb-compression bzip2 --after-install packaging/postinst.sh \
	 	--before-remove packaging/prerm.sh --after-remove packaging/postrm.sh \
		--url http://contribsys.com/inspeqtor --description "Modern service monitoring" \
		-m "Mike Perham <mike@contribsys.com>" --iteration $(ITERATION) --license "GPL 3.0" \
		--vendor "Contributed Systems" -d "runit" -a $(ARCH) $(NAME)

upload: clean package
	curl \
		-T output/$(NAME)_$(VERSION)_$(ARCH).deb \
		-umperham:${BINTRAY_API_KEY} \
		"https://api.bintray.com/content/contribsys/releases/$(NAME)/${VERSION}/$(NAME)_$(VERSION)_$(ARCH).deb;publish=1"

.PHONY: all clean test build package upload