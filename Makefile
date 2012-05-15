compile: fmt
	./version.sh
	./make.sh

fmt:
	go fmt ./...

clean:
	git clean -xdf

########### local build:

LOCAL_GOPATH=${PWD}/local_go_path
DOOZERD_GO_PATH=$(LOCAL_GOPATH)/src/github.com/soundcloud/doozerd

unexport GIT_DIR

build: fmt $(LOCAL_GOPATH)/src/github.com/soundcloud/doozer package bump_package_release
	echo ".git" > .pkgignore
	find . -mindepth 1 -maxdepth 1 | grep -v "\.deb" | sed 's/\.\///g' >> .pkgignore

$(LOCAL_GOPATH)/src:
	mkdir -p $(LOCAL_GOPATH)/src

$(LOCAL_GOPATH)/src/github.com/soundcloud/doozer: $(LOCAL_GOPATH)/src
	GOPATH=$(LOCAL_GOPATH) go get github.com/soundcloud/doozer

local_build:
	test -e $(DOOZERD_GO_PATH) || ln -sf $${PWD} $(DOOZERD_GO_PATH)
	-GOPATH=$(LOCAL_GOPATH) go get .
	-GOPATH=$(LOCAL_GOPATH) ./make.sh
	 GOPATH=$(LOCAL_GOPATH) go build


########## packaging
FPM_EXECUTABLE:=$$(dirname $$(dirname $$(gem which fpm)))/bin/fpm
FPM_ARGS=-t deb -m 'Visor authors (see page), Daniel Bornkessel <daniel@soundcloud.com> (packaging)' --url http://github.com/soundcloud/doozerd -s dir
FAKEROOT=fakeroot
RELEASE=$$(cat .release 2>/dev/null || echo "0")

package: local_build
	rm -rf $(FAKEROOT)
	mkdir -p $(FAKEROOT)/usr/bin
	cp doozerd $(FAKEROOT)/usr/bin
	rm *.deb

	$(FPM_EXECUTABLE) -n "doozerd" \
		-C $(FAKEROOT) \
		--description "doozerd" \
		$(FPM_ARGS) -t deb -v $$(cat VERSION) --iteration $(RELEASE) .;


bump_package_release:
		echo $$(( $(RELEASE) + 1 )) > .release
