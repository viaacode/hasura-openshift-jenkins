//----------------------------------------------------------------------
// This template originally from:
// https://github.com/openshift/origin/blob/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
//----------------------------------------------------------------------
def TEMPLATEPATH = 'https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/hasura-tmpl.yaml'
def TEMPLATENAME = 'hasura'
def TARGET_NS = 'pipeline-app'
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
                        openshift.withProject("pipeline-app") {
                            echo "Using project: ${openshift.project()}"
                        }
                    }
                }
            }
        }
        stage('cleanup') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                            // delete everything with this template label
                            openshift.selector("all", [ deployment  : TEMPLATENAME ]).delete()
                            // delete any secrets with this template label
                            if (openshift.selector("secrets", TEMPLATENAME).exists()) {
                                openshift.selector("secrets", TEMPLATENAME).delete()
                            }
                            sh '''#!/bin/bash
                            oc -n pipeline-app delete template hasura || echo "template was not there yet"
		            oc delete all --selector=ENV=tst,app=hasura || echo "tst env was deleted already"
                            '''
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('create') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                            // create a new application from the TEMPLATEPATH
                           // openshift.newApp(TEMPLATEPATH)
                           sh "oc -n pipeline-app apply -f hasura-tmpl.yaml"
                           echo "processing WARNING need root container for build"
                            sh '''#!/bin/bash

                                  oc project pipeline-app
                                  echo ************ ${TEMPLATEPATH} **********
                                  oc -n pipeline-app delete all --selector=app=hasura-tst

                                  oc -n pipeline-app get templates && echo SUCCESS
                               '''
                        }
                    }
                } // script
            } // steps
        } // stage
        stage('build_config-qas_and_imagestreams') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                             echo "No builds needed"
                             sh '''#!/bin/bash
                             echo postgresql settings are auto generated for QAS, delete them for redeploy
			     oc delete -n pipeline-app configmap postgres-qascnf
			     echo deleting disk for qas 
			     PV-QAS=`oc get pv | grep postgres-qas-pv-claim | awk '{print $3}'`
			     oc delete pvc postgres-qas-pv-claim  || oc delete pv $PVC-QAS

                             '''
                        }
                    }
                } // script
            } // steps
        } // stage


               stage('Install') {
            steps {

                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                             echo "Rolling out  build from template"
                             sh '''#/bin/bash
                             oc -n pipeline-app process hasura -l app=hasura,ENV=tst | oc apply -f -
                             echo Rolled out the Template tst'''

                        }
                    }
                } // script
                input message: "Test app: hasura-qas. Approve?", id: "approval"
                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                             echo "Rolling outfrom template"
                             sh '''#/bin/bash
                             oc -n pipeline-app process --param ENV=qas hasura -l app=hasura,ENV=qas | oc apply -f -
                             echo Rolled out the QAS app
			      oc -n pipeline-app process --param ENV=prd hasura -l app=hasura,ENV=qas | oc apply -f -
                             echo Rolled out the PRD app
			     echo *** please edit the ENV of the hasura deployment to connect to the db ***
			    '''
				echo "setting DB generated stuff in env for hasura pod"
			    sh '''#!/bin/bash 
			    
			     DB_NAME=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_DB| head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_USER=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_USER | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_PASSWORD=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_PASSWORD | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			
			     oc set env deployment/hasura-qas HASURA_GRAPHQL_DATABASE_URL=postgres://$DB_USER:$DB_PASSWORD@postgres-qas:5432/sampledb
			     '''

                        }
                    }
                } // script
		 input message: "cleanup tst env? app: hasura-qas. Approve?", id: "approval"
                    script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                             echo "Deleting tst env"
                             sh '''#/bin/bash
                             oc delete  all --selector=ENV=tst,app=hasura
			     '''

                        }
                    }
                } // script		
		    
            } // steps
        } // stage
    } // stages
} // pipeline
