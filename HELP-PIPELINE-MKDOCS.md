Pipeline for CD
## install
```
pip install mkdocs-material
```

## Serve
```
mkdocs serve
```

## build
```
mkdocs build
```

## Docker Build
````
docker build -t codemonstersteam/website:0.0.1-RC36 .
````

## check
```
docker run --name web-book -p 8082:80 codemonstersteam/web-book:0.0.1-RC5

curl http://localhost:8082 

```

## push
````
docker push codemonstersteam/website:0.0.1-RC36
kubectl apply -f k8s-deployment.yaml
````
## GitLab CI/CD
```
docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
```
## Kaniko
https://docs.gitlab.com/ee/ci/docker/using_kaniko.html

```
echo "{\"auths\":{\"${CI_REGISTRY}\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}"

```