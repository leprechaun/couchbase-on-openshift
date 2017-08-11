# Couchbase on Openshift

** THIS ISN'T EXACTLY PRODUCTION READY **

But the data seems to survive pod losses on minishift.

This repo contains the basics to get couchbase running on OpenShift (3.5).

There's 2 phase OC manifests

- build-time (from this git repo)
  - BuildConfig => JenkinsPipeline
  - BuildConfig => Dockerfile
  - ImageStream => Destination of the above

- run-time
  - PetSet => 1 replica, couchbase and a bootstrapping script
  - Service

If it all works, you can get something running in openshift with the following

```
oc create -f oc-manifest/build-time/
oc start-build leprechaun-couchbase-os
```

This should kick off the pipeline, building an image, then doing an apply on the project.

Hopefully, you'll get a working service within a few minutes.

The service should survive the death of pods. It's in a petset, and uses persistent volumes, so, fingers crossed.

Enabling the auto failover in couchbase would be a good idea.
