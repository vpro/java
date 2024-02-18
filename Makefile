

docker:
	docker build --build-arg CI_COMMIT_REF_NAME=`git branch --show-current` --build-arg CI_COMMIT_SHA=`git rev-parse HEAD`  --build-arg PROJECT_VERSION=1.0 -t vpro/java:dev .

dockertest:
	(cd test ; docker build --build-arg CI_COMMIT_REF_NAME=`git branch --show-current` --build-arg CI_COMMIT_SHA=`git rev-parse HEAD`  PROJECT_VERSION=1.0  -t vpro/test:dev . )


run:
	docker run -it --entrypoint /bin/bash vpro/java:dev 

exec:
	docker run -it --entrypoint /bin/bash vpro/java:dev

exectest:
	docker run -it --entrypoint /bin/bash vpro/test:dev
