node {
  def project = 'chris_ricci'
  def appName = 'simplewebapp'
  def feSvcName = "${appName}"
  def imageTag = "quay.io/${project}/${appName}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
  def namespace = 'production'
  checkout scm

  stage 'Build image'
  sh("docker build -t ${imageTag} .")

  //stage 'Run Go tests'
  //sh("docker run ${imageTag} go test")

  stage 'Push image to registry'
  sh("docker push ${imageTag}")

  stage "Deploy Application"
  switch (env.BRANCH_NAME) {
    // Roll out to canary environment
    case "canary":
        // Change deployed image in canary to the one we just built
	sh("sed -i.bak 's#quay.io/chris_ricci/simplewebapp:.*\$#${imageTag}#' ./k8s/canary/*.yaml")
        sh("kubectl --namespace=${namespace} apply -f k8s/services/")
        sh("kubectl --namespace=${namespace} apply -f k8s/canary/")
        sh("echo http://`kubectl --namespace=${namespace} get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${feSvcName}")
        break

    // Roll out to production
    case "master":
        // Change deployed image in canary to the one we just built
        sh("sed -i.bak 's#quay.io/chris_ricci/simplewebapp:.*\$#${imageTag}#' ./k8s/production/*.yaml")
        sh("kubectl --namespace=${namespace} apply -f k8s/services/")
        sh("kubectl --namespace=${namespace} apply -f k8s/production/")
        sh("echo http://`kubectl --namespace=#{namespace} get service/${feSvcName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${feSvcName}")
        break

    // Roll out a dev environment
    default:
        // Create namespace if it doesn't exist
        sh("kubectl get ns ${env.BRANCH_NAME} || kubectl create ns ${env.BRANCH_NAME}")
        // Don't use public load balancing for development branches
        sh("sed -i.bak 's#quay.io/chris_ricci/simplewebapp:.*\$#${imageTag}#' ./k8s/dev/*.yaml")
        sh("kubectl --namespace=${env.BRANCH_NAME} apply -f k8s/services/")
        sh("kubectl --namespace=${env.BRANCH_NAME} apply -f k8s/dev/")
        echo 'To access your environment run `kubectl proxy`'
        echo "Then access your service via http://localhost:8001/api/v1/proxy/namespaces/${env.BRANCH_NAME}/services/${feSvcName}:80/"
  }
}
