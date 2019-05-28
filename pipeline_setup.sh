# Create pipeline demo projects in thie cluster
#oc new-project ci-cd
OC_PROJECT=shared-components
oc  project ${OC_PROJCT}
#new-project tmp --display-name="avo2 - Build"
#oc new-project pipeline-app-staging --display-name="Pipeline Example - Staging"
##oc adm policy add-scc-to-user privileged system:serviceaccount:pipeline-app:default --as system:admin --as-group system:admins -n pipeline-app

# Switch to the cicd and create the pipeline build from a template
oc project ci-cd 
oc apply -f ./pipeline-git.yaml # note: this will pull from github off the master branch

oc policy add-role-to-user edit system:serviceaccount:ci-cd:jenkins -n ${OC_PROJECT}
oc adm policy add-scc-to-user anyuid -n ${OC_PROJECT}  -z default
# Wait for Jenkins to start
oc project ci-cd
echo "Waiting for Jenkins pod to start.  You can safely exit this with Ctrl+C or just wait."
until
	oc get pods -l name=jenkins | grep -m 1 "Running"
do
	oc get pods -l name=jenkins
	sleep 2
done
echo "Yay, Jenkins is ready."
echo "But we need to do one more thing because of a current limitation."
echo "From the CI/CD project - open the Jenkins webconsole, Manage Jenkins->Configure System->OpenShift Jenkins Sync->Namespace and add 'pipeline-app pipeline-app-staging' to the list"
echo ""
oc project ${OC_PROJECT}
