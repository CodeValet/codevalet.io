#
# Ruby service
#

CONTAINER_IMAGE=rtyler/codevalet-ruby-service
CONTAINER_TAG=latest

all: check container

# Packaging tasks
#######################################
container: depends

container: Dockerfile
	docker build -t $(CONTAINER_IMAGE) .
#######################################

# Verification tasks
#######################################
check: spec features analyze check-container
###
analyze: depends
	./scripts/ruby bundle exec rubocop

check-container: container
	docker run --rm $(CONTAINER_IMAGE):$(CONTAINER_TAG) \
		bundle exec puma --version

features: depends cucumber.yml
	./scripts/ruby bundle exec cucumber

spec: depends .rspec
	./scripts/ruby bundle exec rspec
#######################################

# Miscellaneous tasks
#######################################
depends: Gemfile
	./scripts/ruby bundle install

documentation: depends
	./scripts/ruby bundle exec yard

run: depends
	./scripts/ruby bundle exec puma

#######################################


# Cleanup tasks
#######################################
clean:
	rm -rf vendor/
	docker rmi $$(docker images -qf reference=$(CONTAINER_IMAGE))

#######################################


.PHONY: all check check-container clean \
			container run \
			depends spec features analyze
