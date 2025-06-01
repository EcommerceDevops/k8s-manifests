# k8s-manifests-

## Helm Chart Deployment Overview

Helm is a package manager for Kubernetes that simplifies deployment and lifecycle management of applications using reusable templates called **charts**. In this project, each microservice (e.g., `cloud-config`, `discovery`, `api-gateway`) is structured as a standalone Helm chart located under the `manifests/` directory. This modular setup promotes maintainability, version control, and consistency across environments. Key Helm commands include `helm install`, `helm upgrade`, `helm uninstall`, and `helm list`.

---
# Helmfile

This project orchestrates the deployment of a microservices application on Kubernetes using Helmfile. It integrates the Linkerd service mesh (CRDs, control-plane, viz) and supporting services like Zipkin for distributed tracing. This document explains the deployment process, focusing on the `development` environment.

## Prerequisites

Ensure you have the following tools installed and configured:
* `kubectl`: Configured to access your target Kubernetes cluster.
* `helm`: Version 3 or higher.
* `helmfile`: Latest stable version recommended.

## Project Structure Overview

* **`helmfile.yaml`**: The core Helmfile manifest. It defines Helm repositories, environments, one-time preparation hooks, and all application/Linkerd releases with their configurations, dependencies, and lifecycle hooks.
* **`charts/`**: Contains local Helm charts for your application's microservices (e.g., `./charts/discovery`, `./charts/zipkin`).
* **`config/`**: Stores environment-specific configurations.
    * `config/development/values.yaml`: Global values for the `development` environment.
    * `config/development/secrets/`: Intended for secret files (e.g., `linkerd-secrets.yaml`).
    * `config/development/*-values.yaml`: Service-specific value overrides for the `development` environment.

## Understanding the Deployment Workflow with `helmfile apply`

The primary command for deploying or updating your services is `helmfile -e <environment> apply`. This command synchronizes the desired state defined in `helmfile.yaml` with your Kubernetes cluster.

Here's a breakdown of the execution flow:

1.  **Environment Selection & Value Loading**:
    * The `-e <environment>` flag (e.g., `-e development`) tells Helmfile which environment configuration to use.
    * Helmfile loads values from files specified in the `environments:` block (e.g., `config/development/values.yaml`). These are accessible via `{{ .Environment.Values.someKey }}`.
    * For each release, further `values:` files can be specified (e.g., `config/{{ .Environment.Name }}/zipkin-values.yaml`), where `{{ .Environment.Name }}` is dynamically replaced (e.g., "development").
    * `helmfile.yaml` itself uses Go templating for dynamic configurations like namespaces (e.g., `namespace: '{{ .Environment.Values.linkerd.namespace | default "linkerd" }}'`) and dependency definitions. *(Ensure correct quoting, e.g., `default "value"` or `default 'value'`, to avoid templating errors).*

2.  **Preparation Phase (`prepare` Hooks)**:
    * Commands defined in the top-level `prepare:` block of `helmfile.yaml` are executed **once** at the very beginning, before any releases are processed.
    * **In your setup**: The `"Annotate Default Namespace for Linkerd Injection"` hook runs here.
        ```yaml
        # Example from your helmfile.yaml
        hooks: # This should ideally be a 'prepare:' block for one-time execution
          - name: "Annotate Default Namespace for Linkerd Injection"
            events: ["prepare"] # Correctly uses 'prepare'
            command: "kubectl"
            args: ["annotate", "namespace", "default", "linkerd.io/inject=enabled", "--overwrite"]
        ```
    * **Purpose**: This ensures critical one-time setup tasks, like enabling Linkerd's automatic proxy injection for the `default` namespace, are completed before any application pods are scheduled.

3.  **Release Processing (Dependency Resolution and Execution)**:
    * Helmfile builds a Directed Acyclic Graph (DAG) based on the `needs:` directives within each release definition. Releases are processed in an order that respects these dependencies.
    * For each release in the determined order (e.g., `linkerd-crds` first, then `linkerd-control-plane`, etc.):
        * **`presync` Hooks**: Any hooks defined within the release with `events: ["presync"]` are executed. If multiple `presync` hooks exist for a release, their `order:` field (if specified) controls their sequence.
            * **Purpose**: These are vital for robust deployments. They run custom commands *before* Helm applies the chart. In your setup, these are primarily used with `kubectl wait` to ensure that dependencies (like CRDs being fully established, or a dependent service like Zipkin being fully up and running) are truly **ready**, not just that their Helm chart has been applied. This prevents cascading failures.
            * Examples:
                * `linkerd-control-plane` waits for CRDs.
                * `zipkin` waits for `linkerd-control-plane` pods (and has a strategic `sleep 10` for extra stabilization).
                * `discovery` waits for `zipkin` to be available.
                * `cloud-config` waits for `discovery`.
                * Your application microservices wait for `cloud-config`.
        * **Helm Action**: Helmfile typically runs `helm diff` to show potential changes, followed by `helm upgrade --install` to apply the chart for the release.
        * **`postsync` Hooks** (if defined): Run after a successful Helm action for the release. (Not extensively used in your current setup).

## Deploying the `development` Environment

This is the currently established environment.

1.  **Prerequisites**: Ensure `kubectl`, `helm`, and `helmfile` are installed and `kubectl` is configured for your target cluster.
2.  **Navigate**: Open your terminal in the root directory of this project (where `helmfile.yaml` is located).
3.  **Sync Helm Repositories** (Recommended first time or after adding new repos):
    This command downloads information about charts from the repositories defined in `helmfile.yaml`.
    ```bash
    helmfile repos
    ```
4.  **Review Pending Changes (Optional but Recommended)**:
    See what Helmfile would change in your cluster without actually applying anything.
    ```bash
    helmfile -e development diff
    ```
5.  **Apply the Deployment**:
    This is the main command to deploy or update all services and configurations for the `development` environment. It will trigger the full execution flow described above.
    ```bash
    helmfile -e development apply
    ```
    *Observe the output*: You'll see logs from the `prepare` hook, then each release being processed, including the `showlogs: true` output from your `presync` hooks (e.g., "Waiting for CRD...", "Zipkin service is ready.").

**Other Useful Commands for `development`:**

* **Deploy/Update a Specific Service (Targeted Apply)**:
    If you only want to apply changes to a single release (and its dependencies if they are not met):
    ```bash
    helmfile -e development -l name=discovery apply
    ```
* **Lint Configuration**:
    Check for syntax errors in `helmfile.yaml` and associated charts.
    ```bash
    helmfile -e development lint
    ```
* **Destroy Environment (Use with extreme caution!)**:
    This will delete all Helm releases managed by this Helmfile for the `development` environment.
    ```bash
    helmfile -e development destroy
    ```

## Deploying Other Environments (General Approach)

While only `development` is detailed, setting up new environments (e.g., `staging`, `production`) follows a similar pattern:

1.  **Create Configuration Directory**:
    Create a new directory under `config/`, for example, `config/staging/`.
2.  **Add Value Files**:
    * Create `config/staging/values.yaml` for global staging values.
    * Create service-specific value files like `config/staging/zipkin-values.yaml`, `config/staging/my-app-values.yaml`, etc., with configurations appropriate for staging.
3.  **Define in `helmfile.yaml`**:
    Add a new entry to the `environments:` block in `helmfile.yaml`:
    ```yaml
    environments:
      development:
        values:
          - "./config/development/values.yaml"
      staging: # New environment
        values:
          - "./config/staging/values.yaml"
          # Potentially other shared staging files
    ```
4.  **Deploy**:
    Use the `-e` flag to target the new environment:
    ```bash
    helmfile -e staging apply
    ```
    Helmfile will then use the values from `config/staging/` and the templated paths like `{{ .Environment.Name }}` will resolve to "staging".

This structure provides a robust and understandable way to manage complex deployments across different environments. The use of explicit `needs` and readiness-check `hooks` is key to the stability of the process.

---