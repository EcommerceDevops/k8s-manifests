# k8s-manifests-

## Helm Chart Deployment Overview

Helm is a package manager for Kubernetes that simplifies deployment and lifecycle management of applications using reusable templates called **charts**. In this project, each microservice (e.g., `cloud-config`, `discovery`, `api-gateway`) is structured as a standalone Helm chart located under the `manifests/` directory. This modular setup promotes maintainability, version control, and consistency across environments. Key Helm commands include `helm install`, `helm upgrade`, `helm uninstall`, and `helm list`.

The provided deployment script automates the installation and upgrade of all defined Helm charts using `helm upgrade --install`. It dynamically resolves its directory to correctly locate the `manifests/` folder regardless of the working directory from which it's executed. To run the script:

```bash
./installCharts.sh
```

Use it whenever you want to deploy or update the full stack of microservices in a consistent and repeatable way.
    