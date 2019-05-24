//----------------------------------------------------------------------
// This template originally from:
// https://github.com/openshift/origin/blob/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
//----------------------------------------------------------------------
def TEMPLATEPATH = 'https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/hasura-tmpl.yaml'
def TEMPLATENAME = 'hasura'
def DB_TEMPL = 'postgresql-persistent'
def TARGET_NS = 'pipeline-app'
// def templateSelector = openshift.selector( "template", "postgresql-persistent")
    
// def templateExists = templateSelector.exists()



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
				sh'''oc project pipeline-app
				oc get all
				'''
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
                           // openshift.selector("all", [ deployment  : TEMPLATENAME ]).delete()
			//	openshift.selector("all", [ pvc  : "postgres-qas-pv-claim" ]).delete()
                            // delete any secrets with this template label
                            if (openshift.selector("configmap", "postgres-qascnf").exists()) {
		           	sh '''#!/bin/bash
				oc -n pipeline-app delete all  --selector=ENV=qas,app=hasura || echo "qas env was deleted already"
                               	
			       	'''
			       //openshift.selector("secrets", TEMPLATENAME).delete()
                            }
			    if (openshift.selector("secret", "db-hasura-prd").exists()) {
				    echo "prd db is configured not messing with it"
		           	sh '''#!/bin/bash
				oc -n pipeline-app delete all  --selector=ENV=qas,app=hasura || echo "qas env was deleted already"
                               	
			       	'''
			       //openshift.selector("secrets", TEMPLATENAME).delete()
                            }	
                            sh '''#!/bin/bash
			    echo "clear template"
			     oc -n pipeline-app delete template postgresql-persistent || echo "template was not there yet"
                            oc -n pipeline-app delete template hasura || echo "template was not there yet"
			    oc delete  all --selector=ENV=tst,app=hasura || echo "nothing deleted"
			    oc delete pvc  oc -n pipeline-app delete template || echo "nothing deleted"

			   # oc -n pipeline-app delete all --selector=ENV=qas,app=hasura || echo "qas env was deleted already"
                            oc -n pipeline-app delete pvc --selector=ENV=tst,app=hasura || echo "tst env was deleted already"

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
				
			
				template = openshift.create('https://raw.githubusercontent.com/viaacode/hasura-openshift-jenkins/master/postgresql-persistent.yaml').object()
			  			

				
                            // create a new application from the TEMPLATEPATH
                          // openshift.newApp(TEMPLATEPATH)
                           sh "oc -n pipeline-app apply -f hasura-tmpl.yaml"
			  // sh "oc apply -f postgresql-persistent.yaml"
			   sh '''#!/bin/bash
			   oc process -l app=hasura,ENV=prd  -p DATABASE_SERVICE_NAME=db-hasura-prd -p VOLUME_CAPACITY=254Mi  postgresql-persistent | oc apply -f - 
			   '''
                            sh '''#!/bin/bash
                                  oc project pipeline-app
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
                    
                        }
                    }
                } 
            } 
        } 


       stage('Install and configue') {
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
                script {
                    openshift.withCluster() {
                        openshift.withProject("pipeline-app") {
                             echo "Rolling outfrom template"
                             sh '''#/bin/bash
                             oc -n pipeline-app process --param ENV=qas hasura -l app=hasura,ENV=qas | oc apply -f -
                             echo Rolled out the QAS app
			     # oc -n pipeline-app process --param ENV=prd hasura -l app=hasura-qas,ENV=prd | oc apply -f -
                             echo Rolled out the PRD app
			     echo *** please edit the ENV of the hasura deployment to connect to the db ***
			    '''
				echo "setting DB generated stuff in env for hasura pod"
			    sh '''#!/bin/bash 
			    
			     DB_NAME=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_DB| head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_USER=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_USER | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			     DB_PASSWORD=`oc get configmap postgres-qascnf -o yaml | grep POSTGRES_PASSWORD | head -n 1 | cut -f 2 -d ':'| sed 's/ //g'`
			
			     oc set env deployment/hasura-qas HASURA_GRAPHQL_DATABASE_URL=postgres://$DB_USER:$DB_PASSWORD@postgres-qas.pipeline-app.svc:5432/hasura
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
