## Introduction

A Docker image which uses for MySQL Back-up cronjob inside K8S Cluser.

This repo only contains the Dockerfile, init script for the Docker image, 
all the variables & volume are configured by helm chart repo

## Environment Variables & Volume Mount

The init script of this image requires some variables & credentials to run:

- AWS Credential for S3/ S3-compatible services, it should be a file that is mounted to /root/.aws/credentials
- MySQL hostname, username, password & database name variables
- S3 endpoint, region, bucket name variables

A preview for helm chart configuration of this cronjob:

```
              volumeMounts:
                - name: s3-bucket-secret
                  mountPath: /root/.aws
                  readOnly: true              
              env:
                - name: MYSQL_HOST
                  value: {{ .Values.mysql_host }}
                - name: MYSQL_USERNAME
                  value: {{ .Values.mysql_username }}
                - name: MYSQL_DATABASE
                  value: {{ .Values.mysql_database }}
                - name: STORAGE_ENDPOINT
                  value: {{ .Values.storage_endpoint }}
                - name: STORAGE_REGION
                  value: {{ .Values.storage_region }}
                - name: STORAGE_BUCKET
                  value: {{ .Values.storage_bucket }}                                                                                          
                - name: MYSQL_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: mysql
                      key: mysql-password
          volumes:
            - name: s3-bucket-secret
              secret:
                secretName: "cms-backend-s3-secret"
```                