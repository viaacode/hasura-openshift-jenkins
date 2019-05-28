//----------------------------------------------------------------------
// This template originally from:
// https://github.com/openshift/origin/blob/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
//----------------------------------------------------------------------
def TEMPLATEPATH = 'https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/hasura-tmpl.yaml'
def TEMPLATENAME = 'hasura'
def DB_TEMPL = 'postgresql-persistent'
def TARGET_NS = 'tmp'
def templateSelector = openshift.selector( "template", "hasura-template")
    
def templateExists = templateSelector.exists()



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
                        openshift.withProject("tmp") {
                            echo "Using project: ${openshift.project()}"
                            echo "We need anyuid for postgrsql"
			     sh '''#!/bin/bash 
                               oc adm policy add-scc-to-user anyuid -n tmp  -z default"
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
                        openshift.withProject("tmp") {
                            if (openshift.selector("deploymentconfig", "db-avo2-events-qas").exists()) {
			       sh '''#!/bin/bash
				echo 'DB exists creating extention'
				PGPOD=$(oc get pods --selector=deploymentconfig=db-avo2-events-qas | grep "Running" | awk '{print $1}') 
				oc exec -ti $PGPOD -- bash -c "psql -c 'CREATE extension pgcrypto;' events dbmaster" || echo extention exists
				'''
                            } else {sh'''#!/bin/bash
                                      oc process -l=APP=hazura-qas -pMEMORY_LIMIT=128Mi -p DATABASE_SERVICE_NAME=db-avo2-events-qas -p ENV=qas -p POSTGRESQL_USER=dbmaster -p -p POSTGRESQL_DATABASE=events -p VOLUME_CAPACITY=666Mi -p POSTGRESQL_VERSION=9.6 -f postgresql-persistent.yaml | oc apply -f -
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
                        openshift.withProject("tmp") {
				
			 def template
			    if (!templateExists) {
				template = openshift.create('https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/hasura-tmpl.yaml').object()
			    } else {
				template = templateSelector.object()
			    }				

				
                            // create a new application from the TEMPLATEPATH
                          // openshift.newApp(TEMPLATEPATH)
                           sh "oc -n tmp apply -f hasura-tmpl.yaml"
			  // sh "oc apply -f postgresql-persistent.yaml"
			   sh '''#!/bin/bash
			   DB_NAME=$(oc get secrets db-avo2-events-qas -o yaml |grep database-name |head -n 1 | awk '{print $2}' | base64 --decode)
                           POSTGRESQL_USER=$(oc get secrets db-avo2-events-qas -o yaml |grep database-user |head -n 1 | awk '{print $2}' | base64 --decode)
                           POSTGRESQL_PASSWORD=$(oc get secrets db-avo2-events-qas -o yaml |grep database-password |head -n 1 | awk '{print $2}' | base64 --decode)
			   echo ${HASURA_GRAPHQL_DATABASE_URL}
			   oc process -l app=avo2-events,ENV=qas,HASURA_GRAPHQL_DATABASE_URL=postgres://${POSTGRESQL_USER}:${POSTGRESQL_PASSWORD}@db-avo2-events-qas:5432/${DB_NAME} -p MEMORY_LIMIT=128Mi  -f hasura-tmpl.yaml | oc apply -f - 
                           oc -n tmp get deploymentconfig  && echo SUCCESS
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
                        openshift.withProject("tmp") {
                             echo "No Test yet"
                    
                        }
                    }
                } 
            } 
        } 


       stage('Install and configue') {
            steps {

                script {
                    openshift.withCluster() {
                        openshift.withProject("tmp") {
                             echo "Rolling out  build from template"
                             sh '''#/bin/bash
                             oc -n tmp process hasura -l app=hasura,ENV=tst | oc apply -f -
                             echo Rolled out the Template tst'''

                        }
                    }
                } // script
                script {
                    openshift.withCluster() {
                        openshift.withProject("tmp") {
                             echo "Rolling outfrom template"
                             sh '''#/bin/bash
                             oc -n tmp process --param ENV=qas hasura -l app=hasura,ENV=qas | oc apply -f -
                             echo Rolled out the QAS app
			     # oc -n tmp process --param ENV=prd hasura -l app=hasura-qas,ENV=prd | oc apply -f -
                             echo Rolled out the PRD app
			     echo *** please edit the ENV of the hasura deployment to connect to the db ***
			    '''
				echo "setting DB generated stuff in env for hasura pod"
			    sh '''#!/bin/bash 
			    
			     DB_NAME=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_DB| head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_USER=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_USER | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_PASSWORD=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_PASSWORD | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			
			     oc set env deployment/hasura-qas HASURA_GRAPHQL_DATABASE_URL=postgres://$DB_USER:$DB_PASSWORD@postgres-qas.tmp.svc:5432/hasura
			     '''

                        }
                    }
                } // script
		    
            } // steps
        } // stage
    } // stages
} // pipeline
