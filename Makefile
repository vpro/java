

docker:
	docker build --build-arg CI_COMMIT_REF_NAME=`git branch --show-current` --build-arg CI_COMMIT_SHA=`git rev-parse HEAD`  -t vpro/java:latest .

dockertest:
	(cd test ; docker build --build-arg CI_COMMIT_REF_NAME=`git branch --show-current` --build-arg CI_COMMIT_SHA=`git rev-parse HEAD`   -t vpro/test:latest . )


run:
	docker run -it --entrypoint /bin/bash vpro/java:latest 

exec:
	docker run -it --entrypoint /bin/bash vpro/java:latest

exectest:
	docker run -it --entrypoint /bin/bash vpro/test:latest
