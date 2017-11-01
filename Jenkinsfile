#!groovy
  
def project = 'chris_ricci'
def appName = 'simplewebapp'
def ingName = 'simplewebapp' // Name of the production ingress rule
def stageIngName = 'simplewebapp-staging' // Name of the staging ingress rule
def namespace = 'blue-green'
def imageTag = "quay.io/${project}/${appName}:v${env.BUILD_NUMBER}"
def currentDeployment = ''
def firstDeploy = false

node {
  // Check if Blue or Green is currently live
  try {
    currentDeployment = sh(
      script: "kubectl get ing ${ingName} -n ${namespace} -o jsonpath='{.spec.rules[0].http.paths[0].backend.serviceName}'",
      returnStdout: true
    ).trim()
    echo "Current Deployment: ${currentDeployment}"
  } catch (err) {
    echo "No Previous Deployment"
    firstDeploy = true
  }

  checkout scm
  sh("printenv")
	
  stage 'Login to Quay.io'
  sh("docker login -u=\"${env.quay_username}\" -p=\"${env.quay_password}\" quay.io")
	
  stage 'Build image'
  sh("docker build -t ${imageTag} .")

  stage 'Push image to Quay.io registry'
  sh("docker push ${imageTag}")

  // If this is the first deployment
  if (firstDeploy) {
    stage 'First Deployment'
    // Update images in manifests with current build
    sh("sed -i.bak 's#quay.io/${project}/${appName}:.*\$#${imageTag}#' ./k8s/deployments/*.yaml")
    
    // Deploy resources to the cluster
    sh("kubectl --namespace=${namespace} apply -f k8s/ingress/")
    sh("kubectl --namespace=${namespace} apply -f k8s/services/")
    sh("kubectl --namespace=${namespace} label deployment ${appName}-blue --overwrite version=v${BUILD_NUMBER}")
    sh("kubectl --namespace=${namespace} label deployment ${appName}-green --overwrite version=v${BUILD_NUMBER}")
    currentBuild.result = 'SUCCESS'   
    return
  } else {
    // If current deployment is blue, then deploy to green
    if (currentDeployment == "${appName}-blue") {
      newColor = 'green'
    } else {
      newColor = 'blue'
    }
    stage 'Deploy to Staging'
    // Update deployment with latest image
    sh("kubectl --namespace=${namespace} set image deployment/${appName}-${newColor} simplewebapp=${imageTag}")
    
    // Update staging ingress rule
    sh("kubectl get ing ${stageIngName} --namespace=${namespace} -o yaml | sed 's/\\(serviceName: simplewebapp-\\).*\$/\\1${newColor}/' | kubectl replace -f -")

    // Apply version label to deployment, pods and ingress
    sh("kubectl --namespace=${namespace} label deployment ${appName}-${newColor} --overwrite version=v${BUILD_NUMBER}")
    sh("kubectl --namespace=${namespace} label pod  -l color=${newColor} --all --overwrite version=v${BUILD_NUMBER}")
    sh("kubectl --namespace=${namespace} label ing ${stageIngName} --overwrite version=v${BUILD_NUMBER}")
  }
  stage 'Verify Staging'
  def didTimeout = false
  def userInput = true
  try {
    timeout(time:1, unit:'DAYS') {
      userInput = input(id: 'promoteToProd', message: 'Approve rollout to Production?')
      echo "userInput: [${userInput}]" 
    }
  } catch(err) { // timeout reached or input false
    echo "Rollout Aborted"
    echo "userInput: [${userInput}]"
    currentBuild.result = 'FAILURE'
    error('Aborted')
  }

  if (!firstDeploy) {
    stage 'Rollout to Production' 
    // Update Ingress Rule to point to new color
    sh("kubectl get ing ${ingName} --namespace=${namespace} -o yaml | sed 's/\\(serviceName: simplewebapp-\\).*\$/\\1${newColor}/' | kubectl replace -f -")
    // Apply version label to deployment, pods and ingress
    sh("kubectl --namespace=${namespace} label deployment ${appName}-${newColor} --overwrite version=v${BUILD_NUMBER}")
    sh("kubectl --namespace=${namespace} label pod  -l color=${newColor} --all --overwrite version=v${BUILD_NUMBER}")
    sh("kubectl --namespace=${namespace} label ing ${ingName} --overwrite version=v${BUILD_NUMBER}")
    currentBuild.result = 'SUCCESS'
  }
}
