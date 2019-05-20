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
		            oc delete all --selector=app=hasura-tst && sleep 5
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
                           sh "oc -n pipeline-app apply -f templ.yaml"
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
                             oc project pipeline-app

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
                             oc -n pipeline-app process hasura -l app=hasura-tst,ENV=tst | oc apply -f -
                             echo Rolled out the Template '''

                        }
                    }
                } // script
            //    input message: "Test deployment: es-qas. Approve?", id: "approval"

            } // steps
        } // stage
    } // stages
} // pipeline
