/* import shared library */
@Library('jenkins-shared-libs')_

def TEMPLATEPATH = 'https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/hasura-tmp-dc.yaml'
def TEMPLATENAME = 'hasura-template'
def DB_TEMPL = 'postgresql-persistent'
def TARGET_NS = 'shared-components'
def templateSelector = openshift.selector( "template", "hasura-template")




// NOTE, the "pipeline" directive/closure from the declarative pipeline syntax needs to include, or be nested outside,
// and "openshift" directive/closure from the OpenShift Client Plugin for Jenkins.  Otherwise, the declarative pipeline engine
// will not be fully engaged.
pipeline {
    agent {
      node {

        // spin up a pod to run this build on
        label 'master'
      }
    }
    options {
        // set a timeout of 20 minutes for this pipeline
        timeout(time: 20, unit: 'MINUTES')
    }
    stages {
        stage('preamble') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("shared-components") {
                            echo "Using project: ${openshift.project()}"
                            echo "We need anyuid for postgresql"
			                         sh '''#!/bin/bash
                               echo this is setup by the bash script
                               #oc adm policy add-scc-to-user anyuid -n shared-components  -z default
                            '''
                        }
                    }
                }
            }
        }
        stage('check DB') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("shared-components") {
                            if (openshift.selector("deploymentconfig", "db-avo2-events-qas").exists()) {
			       sh '''#!/bin/bash
          				echo 'DB exists creating extention'
          				PGPOD=`oc -n shared-components  get pods --selector=deploymentconfig=db-avo2-events-qas | grep "Running" | awk '{print $1}' `
                  echo "dbpod: $PGPOD"
          				oc -n shared-components exec -t $PGPOD -- bash -c "psql -c 'CREATE extension IF NOT EXISTS pgcrypto;' events " ;true
          				'''
                            } else {sh'''#!/bin/bash
                                      echo "deploying the database"
                                      oc -n shared-components process -l app=avo2-events -p MEMORY_LIMIT=128Mi -p DATABASE_SERVICE_NAME=db-avo2-events-qas -p ENV=qas -p POSTGRESQL_USER=dbmaster -p POSTGRESQL_DATABASE=events -p VOLUME_CAPACITY=666Mi -p POSTGRESQL_VERSION=9.6 -f postgresql-persistent.yaml | oc  apply -f -
                                      echo waiting roll out
                                      sleep 45

                                      PGPOD=`oc -n shared-components  get pods --selector=deploymentconfig=db-avo2-events-qas | grep "Running" | awk '{print $1}' `
                                      echo "dbpod: $PGPOD"
                              				oc -n shared-components exec -t $PGPOD -- bash -c "psql -c 'CREATE extension IF NOT EXISTS pgcrypto;' events " ;true
                                    '''
                              }
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('Install hasura') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("shared-components") {



                    			   sh "oc -n shared-components apply -f hasura-tmp-dc.yaml"
                    			   sh '''#!/bin/bash
                             oc project shared-components
                    			   DB_NAME=`oc -n shared-components get secrets db-avo2-events-qas -o yaml |grep database-name |head -n 1 | awk '{print $2}' | base64 --decode`
                             POSTGRESQL_USER=`oc -n shared-components get secrets db-avo2-events-qas -o yaml |grep database-user |head -n 1 | awk '{print $2}' | base64 --decode`
                             POSTGRESQL_PASSWORD=`oc -n shared-components get secrets db-avo2-events-qas -o yaml |grep database-password |head -n 1 | awk '{print $2}' | base64 --decode`
                    			   echo ${POSTGRESQL_USER}

                    			   oc -n shared-components process -l app=avo2-events,ENV=qas -p ENV=qas -p MEMORY_LIMIT=128Mi  -f hasura-tmp-dc.yaml | oc  apply -f -
                             oc -n shared-components get deploymentconfig  && echo SUCCESS
                             oc -n shared-components env dc/hasura-avo2-qas HASURA_GRAPHQL_DATABASE_URL=postgres://${POSTGRESQL_USER}:${POSTGRESQL_PASSWORD}@db-avo2-events-qas:5432/${DB_NAME}
                               '''
                                            }
                                        }
                } // script
            } // steps
        } // stage
        stage('test') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("shared-components") {
                             sh'''#!/bin/bash
                             echo "basic port test are in deployments "

                             '''

                        }
                    }
                }
            }
        }


    } // stages
    post {
        always {
            script {
               slackNotifier(currentBuild.currentResult)
            }
        }
    }


} // pipeline
